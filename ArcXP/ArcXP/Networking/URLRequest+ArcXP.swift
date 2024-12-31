//
//  URLRequest+Content.swift
//  ArcXPContent
//
//  Created by Davis, Tyler on 1/18/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation

public extension URLRequest {
    static var session = URLSession.shared

    /// Initializes a URLRequest with an ContentEndpoint object.
    /// - Parameters:
    /// - endpoint: object with the url and other parameters needed to initialize a request.
    internal init?(endpoint: Endpoint) {
        guard let endpointURL = endpoint.url else {
            return nil
        }
        self.init(url: endpointURL)
        self.httpMethod = endpoint.method
        self.httpBody = endpoint.body

        endpoint.headers?.forEach { (key, value) in
            setValue(value, forHTTPHeaderField: key)
        }
    }

    /// A request for Data (JSON)
    /// - Parameters:
    /// - handleResult: A block that takes a `Result` object with the response, data in this instance
    ///   or an error.
    func callForData(handleResult: @escaping (Result <Data, Error>) -> Void) {
        URLRequest.session.dataTask(with: self) { data, response, error in
            deliverToMainThread {
                if let error = error {
                    if (error as NSError).code == -1009 {
                        let networkError = NetworkError.URLRequestError(reason: .networkUnavailable(cachedContent: nil))
                        handleResult(.failure(networkError))
                    } else {
                        handleResult(.failure(error))
                    }
                    return
                }

                guard let httpResponse = (response as? HTTPURLResponse) else {
                    handleResult(.failure(NetworkError.URLRequestError(reason: .endpointMalformed)))
                    return
                }

                let httpStatus = httpResponse.statusCode
                let errorReason: NetworkError.URLRequestErrorReason
                switch httpStatus {
                case 200:
                    if let data = data {
                        handleResult(.success(data))
                        return
                    } else {
                        errorReason = .noDataError
                    }
                case 400:
                    errorReason = .badRequest(httpStatus)
                case 401:
                    errorReason = .unauthorizedError(httpStatus)
                case 404:
                    errorReason = .dataNotFound(httpStatus)
                case 500...599:
                    errorReason = .serverError(httpStatus, cachedContent: nil)
                default:
                    errorReason = .httpError(httpStatus)
                }
                let error = NetworkError.URLRequestError(reason: errorReason)
                handleResult(.failure(error))
            }
        }.resume()
    }

    /// A request for a Codable Object
    /// This request will have to be written in such a way that the generics understand what object is being requested.
    /// - Parameters:
    /// - handleResult: A block that takes a `Result` object with the response, can be any codable object
    ///   or an error.
    func callForCodable<T: Codable>(handleResult: @escaping (Result <T, Error>) -> Void) {
        callForData { result in
            switch result {
            case .success(let data):
                do {
                    let jsonDecoder = JSONDecoder()
                    jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                    let parsedObject: T = try jsonDecoder.decode(T.self, from: data)
                    handleResult(.success(parsedObject))
                } catch {
                    handleResult(.failure(error))
                }
            case .failure(let error):
                handleResult(.failure(error))
            }
        }
    }
}
