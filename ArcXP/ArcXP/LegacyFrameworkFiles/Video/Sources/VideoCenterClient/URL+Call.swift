//  Copyright © 2019 The Washington Post Company. All rights reserved.

import Foundation

public extension URL {

    // MARK: - Shortcuts for making URL requests

    /// Construct a `URLRequest` from the URL and execute it.
    ///
    /// - parameter body: The request body, if any. The default is `nil`.
    /// - parameter httpMethod: One of `GET`, `PUT`, `POST`, `DELETE`, or
    ///             `HEAD`, although values are not checked or validated. The
    ///             default is `GET`.
    /// - parameter headers: HTTP request headers to send, such as cookies or
    ///             authorization tokens. The default is an empty dictionary.
    /// - parameter handleResult: The block to execute when the response is
    ///             received. See
    ///             `URLRequest.call(endpoint:httpMethod:body:headers)` for
    ///             details.
    ///
    /// - returns:  A `URLRequest` that has already had its `resume()` function
    ///             called.
    @discardableResult
    func callAndExpectCodable<T: Codable>(body: Data? = nil,
                                          httpMethod: String = "GET",
                                          headers: [String: String] = [:],
                                          jsonDecoder: JSONDecoder = JSONDecoder(),
                                          handleResult: @escaping (Result <T, Error>) -> Void) -> URLRequest {

        let request = URLRequest(endpoint: self,
                                 httpMethod: httpMethod,
                                 body: body,
                                 headers: headers)
        request.callAndExpectCodable(jsonDecoder: jsonDecoder, handleResult: handleResult)

        return request
    }

    /// Construct a `URLRequest` from the URL and execute it. Call this
    /// version if nothing is expected in the response body for a successful
    /// call.
    ///
    /// - parameter body: The request body, if any. The default is `nil`.
    /// - parameter httpMethod: One of `GET`, `PUT`, `POST`, `DELETE`, or
    ///             `HEAD`, although values are not checked or validated. The
    ///             default is `GET`.
    /// - parameter headers: HTTP request headers to send, such as cookies or
    ///             authorization tokens. The default is an empty dictionary.
    /// - parameter handleResult: The block to execute when the response is
    ///             received. See
    ///             `URLRequest.call(endpoint:httpMethod:body:headers)` for
    ///             details.
    ///
    /// - returns:  A `URLRequest` that has already had its `resume()` function
    ///             called.
    @discardableResult
    func callAndExpectVoid(body: Data? = nil,
                           httpMethod: String = "GET",
                           headers: [String: String] = [:],
                           handleResult: @escaping (Result <Void, Error>) -> Void) -> URLRequest {
        let request = URLRequest(endpoint: self,
                                 httpMethod: httpMethod,
                                 body: body,
                                 headers: headers)
        request.callAndExpectVoid(handleResult: handleResult)

        return request
    }

    /// Construct a `URLRequest` from the URL and execute it. Call this
    /// version if String response is expected
    ///
    /// - parameter body: The request body, if any. The default is `nil`.
    /// - parameter httpMethod: One of `GET`, `PUT`, `POST`, `DELETE`, or
    ///             `HEAD`, although values are not checked or validated. The
    ///             default is `GET`.
    /// - parameter headers: HTTP request headers to send, such as cookies or
    ///             authorization tokens. The default is an empty dictionary.
    /// - parameter handleResult: The block to execute when the response is
    ///             received. See
    ///             `URLRequest.call(endpoint:httpMethod:body:headers)` for
    ///             details.
    ///
    /// - returns:  A `URLRequest` that has already had its `resume()` function
    ///             called.
    @discardableResult
    func callAndExpectString(body: Data? = nil,
                             httpMethod: String = "GET",
                             headers: [String: String] = [:],
                             handleResult: @escaping (Result <String?, Error>) -> Void) -> URLRequest {
        let request = URLRequest(endpoint: self,
                                 httpMethod: httpMethod,
                                 body: body,
                                 headers: headers)
        request.callAndExpectString(handleResult: handleResult)

        return request
    }

}
