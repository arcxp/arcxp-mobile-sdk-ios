//
//  NetworkError.swift
//  ArcXP
//
//  Created by David Seitz Jr on 3/15/23.
//  Copyright © 2023 The Washington Post Company. All rights reserved.
//

import Foundation

/// Represents possible errors that the Content service can produce.
public enum NetworkError: LocalizedError {

    /// The underlying reason the `.URLRequestError` occurred.
    public enum URLRequestErrorReason {

        /// For non-200 HTTP status codes.
        case httpError(_ statusCode: Int)

        /// For 400 HTTP status codes
        case badRequest(_ statusCode: Int)

        // For 401 HTTP status code
        case unauthorizedError(_ statusCode: Int)

        // For 404 HTTP status code
        case dataNotFound(_ statusCode: Int)

        /// Thrown when the server doesn't return an error, but returns empty data.
        case noDataError

        /// For when the URL is broken or malformed
        case endpointMalformed

        /// For 500-599 HTTP status codes.
        case serverError(_ statusCode: Int, cachedContent: Any?)
        
        /// For when the network is unavailable.
        case networkUnavailable(cachedContent: Any?)
    }

    /// Represents the reasons for a `CacheError`.
    public enum CacheErrorReason {
        case cacheMiss
    }

    /// A network request failed with a``URLRequestErrorReason``.
    case URLRequestError(reason: URLRequestErrorReason)

    /// A network request failed with a ``CacheErrorReason``.
    case cacheError(reason: CacheErrorReason)

    /// Error message that's returned by calling ``.localizedDescription`` on the error.
    public var errorDescription: String? {
        switch self {
        case let .URLRequestError(reason):
            switch reason {
            case .httpError(let statusCode):
                return "HTTP error: status code = \(statusCode)"
            case .badRequest(let statusCode):
                return "Bad HTTP request:\n Status code = \(statusCode)"
            case .unauthorizedError(let statusCode):
                return "Access denied:\n Status code = \(statusCode)"
            case .dataNotFound(let statusCode):
                return "Can not find the requested resource: \n Status code = \(statusCode)"
            case .noDataError:
                return "The server did not send any data back"
            case .endpointMalformed:
                return "The endpoint was malformed and the URL could not be made."
            case .serverError(let statusCode, _):
                return "Server has encountered an error: \n Status code = \(statusCode) "
            case .networkUnavailable:
                return "The Internet connection appears to be offline."
            }
        case .cacheError(reason: let reason):
            switch reason {
            case .cacheMiss:
                return "Couldn't find the requested resource"
            }
        }
    }

    /// A utility function to feed cached content into an error object.
    /// - Parameter cachedContent: The cached content to add to the error object.
    /// - Returns: An error object with the cached content added.
    func feedCacheContentIntoErrorObject(cachedContent: Any?) -> Error {
        switch self {
        case let .URLRequestError(reason):
            switch reason {
            case .serverError(let statusCode, _):
                return NetworkError.URLRequestError(reason: .serverError(statusCode, cachedContent: cachedContent))
            case .networkUnavailable:
                return NetworkError.URLRequestError(reason: .networkUnavailable(cachedContent: cachedContent))
            default:
                break
            }
        default:
            break
        }
        return self
    }
}

/// Represents an error response for the `URLRequest`.
struct ContentErrorResponse: Codable {
    /// The HTTP status code of the response.
    let httpStatus: Int
    
    /// The error code returned by the server.
    let code: String
    
    /// The error message returned by the server.
    let message: String
}
