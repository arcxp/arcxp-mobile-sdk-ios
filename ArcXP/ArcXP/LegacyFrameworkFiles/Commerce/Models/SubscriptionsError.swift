//
//  CommerceError.swift
//  Commerce
//
//  Created by Davis, Tyler on 6/1/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation

/// Error types that can be wrapped in `Failure`s and passed to the
/// functions'  `handleResult` blocks.
public enum SubscriptionsError: LocalizedError {

    /// The underlying reason the `.URLRequestError` occurred.
    public enum URLRequestErrorReason {
        /// For non-200 HTTP status codes.
        case httpError(_ statusCode: Int)
        /// For 400 HTTP status codes
        case badRequest(_ statusCode: Int, _ code: String, _ message: String)
        // For 401 HTTP status code
        case unauthorizedError(_ statusCode: Int, _ code: String, _ message: String)
        /// Thrown when the server doesn't return an error, but returns empty
        /// data.
        case noDataError
        /// For when the URL is broken or malformed
        case endpointMalformed
    }

    /// The underlying reason the `.userAccountErrorReason` occurred.
    public enum UserAccountErrorReason {
        case signInError(errorMessage: String)
        case unknownError
        case unexpectedResult
        case noAccessTokenDuringProfileUpdate
        case noAccessTokenAvailable
        case noUserProfileReturnedFromBackend
        case failedUserProfileUpdate(statusCode: Int)
        case failedToRedeemNonce(statusCode: Int)
        case failedToGenerateEmail(statusCode: Int)
        case currentUserNotAvailable
        case failedToParseAccessToken
        case noDataProvided(while: String)
        case failedThirdPartyAuthentication
        case failedToSendEmail
        case commerceBackendError(code: String, httpStatus: Int, message: String)
        case cancelledLogIn
        case socialLoginAlreadyExists
        case socialAccountAlreadyAdded
    }

    /// A Network Request failed with ``reason``
    case URLRequestError(reason: URLRequestErrorReason)

    /// A problem with the user account happened with ``reason``
    case userAccountError(reason: UserAccountErrorReason)

    /// Error message that's returned by calling ``.localizedDescription`` on the
    /// error.
    public var errorDescription: String? {
        switch self {
        case let .URLRequestError(reason):
            switch reason {
            case .httpError(let statusCode):
                return "HTTP error: status code \(statusCode)"
            case .badRequest(let statusCode, let code, let message):
                return "Bad HTTP request:\nStatus code \(statusCode)\nCode \(code)\n\(message)"
            case .unauthorizedError(let statusCode, let code, let message):
                return "Access denied:\nStatus code \(statusCode)\nCode \(code)\n\(message)"
            case .noDataError:
                return "The server did not send any data back"
            case .endpointMalformed:
                return "The endpoint was malformed and the URL could not be made."
            }
        case let .userAccountError(reason):
            switch reason {
            case .signInError(let errorMessage):
                return errorMessage

            case .unknownError:
                return "Sign in failed for an unexpected reason."

            case .unexpectedResult:
                return "Received an unexpected result from the Commerce backend."

            case .noAccessTokenDuringProfileUpdate:
                return "The user attempted to update their user profile, but their required access token was not available."

            case .noAccessTokenAvailable:
                return "Attempted to fetch the user's access token, but did not find one. This may be because the backend never delivered one."

            case .noUserProfileReturnedFromBackend:
                return "The user information returned by the backend did not contain a user profile."

            case .failedUserProfileUpdate(let statusCode):
                return "Failed to update user profile. URLResponse status code: \(statusCode)"

            case .failedToRedeemNonce(let statusCode):
                return "Failed to redeem nonce. URLResponse status code: \(statusCode)"

            case .failedToGenerateEmail(let statusCode):
                return "Failed to generate email. URLResponse status code: \(statusCode)"

            case .currentUserNotAvailable:
                return "A user must be signed in before this operation is available."

            case .failedToParseAccessToken:
                return "Failed to find expected access token in the provided data."

            case .noDataProvided(let action):
                return "No data was provided while: \(action)"

            case .failedThirdPartyAuthentication:
                return "Failed to authenticate third party authentication credentials."

            case .failedToSendEmail:
                return "Failed to send an email for the request"

            case .commerceBackendError(let code, let httpStatus, let message):
                return "There was an error from the Commerce backend. Error code: \(code), Error httpStatus: \(httpStatus), Error message: \(message)"

            case .cancelledLogIn:
                return "The user cancelled the log in process."

            case .socialLoginAlreadyExists:
                return "Attempted to add a social login, but social login already exists with another account."

            case .socialAccountAlreadyAdded:
                return "You've already added that social login to this account."
            }
        }
    }
}
