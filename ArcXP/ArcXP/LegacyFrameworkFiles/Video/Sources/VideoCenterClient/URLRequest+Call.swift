//  Copyright © 2019 The Washington Post Company. All rights reserved.

import Foundation

/// Error types that can be wrapped in `Failure`s and passed to the
/// functions' `handleResult` blocks.
enum URLRequestError: Error {

    /// For all non-200 HTTP status codes.
    case httpError(statusCode: Int)

    /// For URL paths that are invalid when resolved against the `baseURL`.
    case malformedEndpoint(urlString: String)

    /// Thrown when the server doesn't return an error, but returns empty
    /// data.
    case noDataError

    /// Thrown when no data was expected to be returned, but something was.
    case unexpectedlyNonEmptyDataError

}

extension URLRequest {

    // MARK: - Properties

    /// Get a `cURL` command string representation of the request.
    /// ~~Shamelessly stolen~~ Respectfully borrowed from
    /// https://gist.github.com/shaps80/ba6a1e2d477af0383e8f19b87f53661d
    var curlString: String {
        guard let url = url else { return "" }

        var baseCommand = "curl \"\(url.absoluteURL)\""

        if httpMethod == "HEAD" {
            baseCommand += " --head"
        }

        var command = [baseCommand]

        if let method = httpMethod, method != "GET" && method != "HEAD" {
            command.append("--request \(method)")
        }

        if let headers = allHTTPHeaderFields {
            for (key, value) in headers where key != "Cookie" {
                command.append("--header '\(key): \(value)'")
            }
        }

        if let data = httpBody, let body = String(data: data, encoding: .utf8) {
            command.append("--data '\(body)'")
        }

        return command.joined(separator: " \\\n\t")
    }

    // MARK: - Initialization

    /// Convenience initializer.
    ///
    /// - parameter endpoint: The `URL` being requested.
    /// - parameter httpMethod: One of `GET`, `POST`, `DELETE`, `HEADER`, etc.
    ///   The default is `GET`.
    /// - parameter body: The raw `Data` to be sent to the server. The specific
    ///   content depends on the URL endpoint being called. The default is
    ///   `nil`.
    /// - parameter headers: Any HTTP header values to be passed along. The
    ///   default is `nil`.
    init(endpoint: URL,
         httpMethod: String = "GET",
         body: Data? = nil,
         headers: [String: String?]? = nil) {
        self.init(url: endpoint)
        self.httpMethod = httpMethod
        self.httpBody = body

        headers?.forEach { (key, value) in
            setValue(value, forHTTPHeaderField: key)
        }
    }

    // MARK: - call()

    /// Execute a `URLRequest` and handle its response by decoding its JSON
    /// body and passing it to a completion block as a `Result`.
    ///
    /// For example, if a response is expected to contain a `Codable` `Foo`
    /// object as its body, call this like:
    ///
    /// ```
    /// URLRequest<Foo>(jsonDecoder: JSONDecoder()) { (result) in
    ///   switch result {
    ///     case .success(let foo):
    ///       // do something with the `foo` instance.
    ///     case .failure(let error):
    ///       print("There was an error: \(error.localizedDescription)")
    ///   }
    /// }
    /// ```
    ///
    /// - parameter jsonDecoder: The decoder used for decoding the response
    ///             body. By default, this is a plain `JSONDecoder`, but if you
    ///             need one that converts snake_case keys to CamelCase, for
    ///             example, you can pass one in explicitly.
    /// - parameter handleResult: The block to execute when the response is
    ///             received. It takes a `Result` object of type `T`. If an
    ///             error was received, then a failure `Result` is passed to it.
    ///             If valid data was received, it's parsed into an object of
    ///             type `T` and passed as a successful `Result`. If the HTTP
    ///             response was successful, but the response body is empty,
    ///             then a `URLRequestError.noDataError` `Result` is passed in.
    ///             (Use `callVoidable(jsonDecoder:handleResult)` for requests
    ///             that are *expected* to have empty response bodies.)
    func callAndExpectCodable<T: Decodable>(jsonDecoder: JSONDecoder = JSONDecoder(),
                                            handleResult: @escaping (Result <T, Error>) -> Void) {
        callAndExpectData { (result) in
            switch result {
            case .success(let data):
                guard let data = data else {
                    handleUnexpectedlyEmptyResult(handleResult: handleResult)

                    return
                }

                do {
                    let parsedObject: T = try T.decode(jsonData: data, decoder: jsonDecoder)
                    handleResult(Result.success(parsedObject))
                } catch {
                    let urlString = self.url?.absoluteString ?? "(unknown URL)"
                    ArcXPLogger.log(
                        """
\(urlString) succeeded, but the JSON data couldn't be parsed. Response: \n
\(String(decoding: data, as: UTF8.self))
""",
                        error: error)
                    handleResult(Result.failure(error))
                }
            case .failure(let error):
                handleResult(Result.failure(error))
            }
        }
    }

    /// Execute a `URLRequest` and handle its response. Use this for requests
    /// that are expected to return Data.
    ///
    /// For example, if a response is not expected to contain a `Codable`
    /// response body, call it like this:
    ///
    /// - parameter handleResult: The block to execute when the response is
    ///             received. It takes a `Result` object of type `T`. If an
    ///             error was received, then a failure `Result` is passed to it.
    ///             If valid data was received, it's passed as a successful `Result`. If the HTTP
    ///             response was successful, but the response body is empty,
    ///             then a `URLRequestError.noDataError` `Result` is passed in.
    ///             (Use `callVoidable(jsonDecoder:handleResult)` for requests
    ///             that are *expected* to have empty response bodies.)
    func callAndExpectData(handleResult: @escaping (Result <Data?, Error>) -> Void) {
        ArcXPLogger.logRequest(urlRequest: self)

        URLSession.shared.dataTask(with: self) { (data, urlResponse, error) in
            self.deliverToMainThread {
                if let error = error {
                    handleError(error, response: urlResponse, handleResult: handleResult)
                } else if let httpStatus = (urlResponse as? HTTPURLResponse)?.statusCode,
                          httpStatus < 200 || httpStatus >= 400 {
                    handleError(ArcMediaClientError.mediaNotFound(url),
                                response: urlResponse,
                                handleResult: handleResult)
                } else if let data = data {
                    handleResult(Result.success((data)))
                } else {
                    handleUnexpectedlyEmptyResult(urlResponse: urlResponse,
                                                  handleResult: handleResult)
                }
            }
        }.resume()
    }

    /// Execute a `URLRequest` and handle its response. Use this for requests
    /// that aren't expected to return anything in the response body. Note that
    /// unlike `call(jsonDecoder:handleResult)`, this function is not generic,
    /// because there's no body data to be parsed.
    ///
    /// For example, if a response is not expected to contain a `Codable`
    /// response body, call it like this:
    ///
    /// ```
    /// URLRequest { (result) in
    ///   switch result {
    ///     case .success:
    ///       print("It worked. The body is empty, which is as it should be.")
    ///     case .failure(let error):
    ///       print("There was an error: \(error.localizedDescription)")
    ///   }
    /// }
    /// ```
    ///
    /// - parameter jsonDecoder: The decoder used for decoding the response
    ///             body. By default, this is a plain `JSONDecoder`, but if you
    ///             need one that converts snake_case keys to CamelCase, for
    ///             example, you can pass one in explicitly.
    /// - parameter handleResult: The block to execute when the response is
    ///             received. It takes a `Result` object of type `T`. If an
    ///             error was received, then a failure `Result` is passed to it.
    ///             If valid data was received, it's parsed into an object of
    ///             type `T` and passed as a successful `Result`. If the HTTP
    ///             response was successful, but the response body is empty,
    ///             then a `URLRequestError.noDataError` `Result` is passed in.
    ///             (Use `callVoidable(jsonDecoder:handleResult)` for requests
    ///             that are *expected* to have empty response bodies.)
    func callAndExpectVoid(handleResult: @escaping (Result <Void, Error>) -> Void) {
        ArcXPLogger.logRequest(urlRequest: self)

        URLSession.shared.dataTask(with: self) { (data, urlResponse, error) in
            self.deliverToMainThread {
                if let error = error {
                    handleError(error, response: urlResponse, handleResult: handleResult)
                } else if let response = urlResponse as? HTTPURLResponse,
                          200 <= response.statusCode && response.statusCode <= 204 {
                    // Technically, calls that don't return any data should
                    // return a 204 instead of a 200, but in reality, few
                    // servers honor this.
                    handleResult(Result.success(()))
                } else if data == nil || data!.isEmpty {
                    handleResult(Result.success(()))
                } else {
                    handleResult(Result.failure(URLRequestError.unexpectedlyNonEmptyDataError))
                }
            }
        }.resume()
    }

    /// Handle an HTTP error by logging it and passing it to `Result.failure()`
    private func handleError<T>(_ error: Error,
                                response: URLResponse?,
                                handleResult: @escaping (Result <T, Error>) -> Void) {
        let responseStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        ArcXPLogger.logHTTPError(url?.absoluteString ?? "(nil URL)",
                            description: error.localizedDescription,
                            statusCode: responseStatusCode)
        handleResult(Result.failure(error))
    }

    /// Execute a `URLRequest` and handle its response. Use this for requests
    /// that are expected to return String form of the response body.
    ///
    /// For example, if a response is not expected to contain a `Codable`
    /// response body, call it like this:
    ///
    /// ```
    /// URLRequest { (result) in
    ///   switch result {
    ///     case .success(let foo):
    ///     // do something with the `foo` instance.
    ///     case .failure(let error):
    ///       print("There was an error: \(error.localizedDescription)")
    ///   }
    /// }
    /// ```
    ///
    /// - parameter jsonDecoder: The decoder used for decoding the response
    ///             body. By default, this is a plain `JSONDecoder`, but if you
    ///             need one that converts snake_case keys to CamelCase, for
    ///             example, you can pass one in explicitly.
    /// - parameter handleResult: The block to execute when the response is
    ///             received. It takes a `Result` object of type `T`. If an
    ///             error was received, then a failure `Result` is passed to it.
    ///             If valid data was received, it's parsed into an object of
    ///             type `T` and passed as a successful `Result`. If the HTTP
    ///             response was successful, but the response body is empty,
    ///             then a `URLRequestError.noDataError` `Result` is passed in.
    ///             (Use `callVoidable(jsonDecoder:handleResult)` for requests
    ///             that are *expected* to have empty response bodies.)
    func callAndExpectString(handleResult: @escaping (Result <String?, Error>) -> Void) {
        let endpoint = url?.absoluteString ?? "(nil URL)"
        ArcXPLogger.logRequest(urlRequest: self)

        URLSession.shared.dataTask(with: self) { (data, urlResponse, error) in
            self.deliverToMainThread {
                if let error = error {
                    let responseStatusCode = (urlResponse as? HTTPURLResponse)?.statusCode ?? 0
                    ArcXPLogger.logHTTPError(endpoint,
                                        description: error.localizedDescription,
                                        statusCode: responseStatusCode)
                    handleResult(Result.failure(error))
                } else if let data = data {
                    let responseObject = String(data: data, encoding: String.Encoding.utf8)
                    handleResult(Result.success((responseObject)))
                } else {
                    handleUnexpectedlyEmptyResult(urlResponse: urlResponse,
                                                  handleResult: handleResult)
                }
            }
        }.resume()
    }

    // MARK: - Everything Else

    /// Dispatches the given block on the main thread context, switching only if nessessary.
    ///
    /// Shamelessly copied from UtilityBelt's `Dispatch`.
    ///
    /// - parameter block: The closure to be executed.
    private func deliverToMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }

    /// Called when a request succeeded, but didn't contain any `Data` in the
    /// response. This calls the result handler with a
    /// `URLRequestError.noDataError` and logs it.
    ///
    /// - parameter urlResponse: The response. If it's an `HTTPURLResponse`,
    ///   the response code will be logged.
    /// - parameter handleResult: The result block to invoke with an error.
    ///   Note that the result that's passed to it isn't even examined, since
    ///   we assume that the caller checked the result before calling this
    ///   function.
    private func handleUnexpectedlyEmptyResult<T>(urlResponse: URLResponse? = nil,
                                                  handleResult: @escaping (Result <T, Error>) -> Void) {
        let error = URLRequestError.noDataError

        if let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode {
            ArcXPLogger.logHTTPError("No data was returned",
                                description: "\(url?.absoluteString ?? "(no url)") should have returned data.",
                                statusCode: statusCode)
        } else {
            ArcXPLogger.log(error: error)
        }

        handleResult(Result.failure(URLRequestError.noDataError))
    }

}
