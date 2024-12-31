//
//  CommerceErrorTests.swift
//  ArcXPTests
//
//  Created by David Seitz on 12/1/23.
//  Copyright © 2023 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class CommerceErrorTests: XCTestCase {
    
    // MARK: URLRequestError Tests
    
    func testHttpError() {
        let error = SubscriptionsError.URLRequestError(reason: .httpError(404))
        XCTAssertEqual(error.localizedDescription, "HTTP error: status code 404")
    }
    
    func testBadRequest() {
        let error = SubscriptionsError.URLRequestError(reason: .badRequest(400, "400", "Invalid request"))
        XCTAssertEqual(error.localizedDescription, "Bad HTTP request:\nStatus code 400\nCode 400\nInvalid request")
    }
    
    func testUnauthorizedError() {
        let error = SubscriptionsError.URLRequestError(reason: .unauthorizedError(401, "401", "Unauthorized"))
        XCTAssertEqual(error.localizedDescription, "Access denied:\nStatus code 401\nCode 401\nUnauthorized")
    }
    
    func testNoDataError() {
        let error = SubscriptionsError.URLRequestError(reason: .noDataError)
        XCTAssertEqual(error.localizedDescription, "The server did not send any data back")
    }
    
    func testEndpointMalformed() {
        let error = SubscriptionsError.URLRequestError(reason: .endpointMalformed)
        XCTAssertEqual(error.localizedDescription, "The endpoint was malformed and the URL could not be made.")
    }
    
    // MARK: UserAccountError Tests
    
    func testSignInError() {
        let error = SubscriptionsError.userAccountError(reason: .signInError(errorMessage: "Invalid credentials"))
        XCTAssertEqual(error.localizedDescription, "Invalid credentials")
    }
    
    func testUnknownError() {
        let error = SubscriptionsError.userAccountError(reason: .unknownError)
        XCTAssertEqual(error.localizedDescription, "Sign in failed for an unexpected reason.")
    }
    
    func testUnexpectedResult() {
        let error = SubscriptionsError.userAccountError(reason: .unexpectedResult)
        XCTAssertEqual(error.localizedDescription, "Received an unexpected result from the Commerce backend.")
    }
    
    func testNoAccessTokenDuringProfileUpdate() {
        let error = SubscriptionsError.userAccountError(reason: .noAccessTokenDuringProfileUpdate)
        XCTAssertEqual(error.localizedDescription, "The user attempted to update their user profile, but their required access token was not available.")
    }
    
    func testNoAccessTokenAvailable() {
        let error = SubscriptionsError.userAccountError(reason: .noAccessTokenAvailable)
        XCTAssertEqual(error.localizedDescription, "Attempted to fetch the user's access token, but did not find one. This may be because the backend never delivered one.")
    }
    
    func testNoUserProfileReturnedFromBackend() {
        let error = SubscriptionsError.userAccountError(reason: .noUserProfileReturnedFromBackend)
        XCTAssertEqual(error.localizedDescription, "The user information returned by the backend did not contain a user profile.")
    }
    
    func testFailedUserProfileUpdate() {
        let error = SubscriptionsError.userAccountError(reason: .failedUserProfileUpdate(statusCode: 500))
        XCTAssertEqual(error.localizedDescription, "Failed to update user profile. URLResponse status code: 500")
    }
    
    func testFailedToRedeemNonce() {
        let error = SubscriptionsError.userAccountError(reason: .failedToRedeemNonce(statusCode: 400))
        XCTAssertEqual(error.localizedDescription, "Failed to redeem nonce. URLResponse status code: 400")
    }
    
    func testFailedToGenerateEmail() {
        let error = SubscriptionsError.userAccountError(reason: .failedToGenerateEmail(statusCode: 403))
        XCTAssertEqual(error.localizedDescription, "Failed to generate email. URLResponse status code: 403")
    }
    
    func testCurrentUserNotAvailable() {
        let error = SubscriptionsError.userAccountError(reason: .currentUserNotAvailable)
        XCTAssertEqual(error.localizedDescription, "A user must be signed in before this operation is available.")
    }
    
    func testFailedToParseAccessToken() {
        let error = SubscriptionsError.userAccountError(reason: .failedToParseAccessToken)
        XCTAssertEqual(error.localizedDescription, "Failed to find expected access token in the provided data.")
    }
    
    func testNoDataProvided() {
        let error = SubscriptionsError.userAccountError(reason: .noDataProvided(while: "updating profile"))
        XCTAssertEqual(error.localizedDescription, "No data was provided while: updating profile")
    }
    
    func testFailedThirdPartyAuthentication() {
        let error = SubscriptionsError.userAccountError(reason: .failedThirdPartyAuthentication)
        XCTAssertEqual(error.localizedDescription, "Failed to authenticate third party authentication credentials.")
    }
    
    func testFailedToSendEmail() {
        let error = SubscriptionsError.userAccountError(reason: .failedToSendEmail)
        XCTAssertEqual(error.localizedDescription, "Failed to send an email for the request")
    }
    
    func testCommerceBackendError() {
        let error = SubscriptionsError.userAccountError(reason: .commerceBackendError(code: "BE001", httpStatus: 500, message: "Server error"))
        XCTAssertEqual(error.localizedDescription, "There was an error from the Commerce backend. Error code: BE001, Error httpStatus: 500, Error message: Server error")
    }
    
    func testCancelledLogIn() {
        let error = SubscriptionsError.userAccountError(reason: .cancelledLogIn)
        XCTAssertEqual(error.localizedDescription, "The user cancelled the log in process.")
    }
    
    func testSocialLoginAlreadyExists() {
        let error = SubscriptionsError.userAccountError(reason: .socialLoginAlreadyExists)
        XCTAssertEqual(error.localizedDescription, "Attempted to add a social login, but social login already exists with another account.")
    }
    
    func testSocialAccountAlreadyAdded() {
        let error = SubscriptionsError.userAccountError(reason: .socialAccountAlreadyAdded)
        XCTAssertEqual(error.localizedDescription, "You've already added that social login to this account.")
    }
}
