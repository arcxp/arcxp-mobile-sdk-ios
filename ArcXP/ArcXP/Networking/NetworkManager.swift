//
//  NetworkManager.swift
//  Commerce
//
//  Created by Seitz, David on 6/30/20.
//  Copyright © 2020 The Washington Post Company. All rights reserved.
//

import Foundation

/// Manages network requests.
@available(iOS 14.0, *)
struct NetworkManager {
    static var session = URLSession.shared

    /// Makes a network request and returns the result as a `Codable` object through the completion handler.
    /// - Parameters:
    /// - endpoint: The endpoint to request data from.
    /// - completion: The completion handler to call.
    static func requestForCodable<T: Codable>(from endpoint: Endpoint, completion: @escaping (Result <T, Error>) -> Void) {
        requestForData(from: endpoint) { result in
            deliverToMainThread {
                switch result {
                case .success(let data):
                    do {
                        let parsedObject: T = try JSONDecoder().decode(T.self, from: data)
                        completion(.success(parsedObject))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    /// Makes a network request and returns the results data through the completion handler.
    /// - Parameters:
    ///  - endpoint: The endpoint to request data from.
    ///  - completion: The completion handler to call.
    static func requestForData(from endpoint: Endpoint,
                               completion: @escaping (Result <Data, Error>) -> Void) {
        guard let url = endpoint.url else {
            let error = SubscriptionsError.URLRequestError(reason: .endpointMalformed)
            completion(.failure(error))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.httpBody = endpoint.body
        request.addHeaders(endpoint.headers)

        session.dataTask(with: request) { data, response, error in
            deliverToMainThread {
                guard let data = data else {
                    completion(.failure(SubscriptionsError.URLRequestError(reason: .noDataError)))
                    return
                }
                if let error = error {
                    completion(.failure(error))
                }

                guard let httpResponse = (response as? HTTPURLResponse) else {
                    // Generally used for file:/// URLs, like mock JSON
                    // resource files.
                    completion(.success(data))
                    return
                }

                let httpStatus = httpResponse.statusCode
                do {
                    switch httpStatus {
                    case 200:
                        completion(.success(data))

                    case 400, 401:
                        let jsonDecoder: JSONDecoder = JSONDecoder()
                        let parsedObject = try jsonDecoder.decode(ErrorResponse.self, from: data)
                        let errorObject: SubscriptionsError
                        if httpStatus == 400 {
                            errorObject = SubscriptionsError.URLRequestError(reason: .badRequest(parsedObject.httpStatus,
                                                                                            parsedObject.code,
                                                                                            parsedObject.message))
                        } else {
                            errorObject = SubscriptionsError.URLRequestError(reason: .unauthorizedError(parsedObject.httpStatus,
                                                                                                   parsedObject.code,
                                                                                                   parsedObject.message))
                        }
                        completion(.failure(errorObject))
                    default:
                        let errorObject = SubscriptionsError.URLRequestError(reason: .httpError(httpStatus))
                        completion(.failure(errorObject))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
