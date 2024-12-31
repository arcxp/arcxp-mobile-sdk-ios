//
//  RememberMeExtendUserSessionTests.swift
//  ExampleTests
//
//  Created by Cassandra Balbuena on 7/16/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class RememberMeExtendUserSessionTests: SubscriptionsMockNetworkTest {

    var signUpData = UserProfile(userName: TestConstant.mockUsername,
                                 password: TestConstant.mockUserPassword,
                                 email: TestConstant.mockUserEmail)

    func testExtendUserSessionEndpoint() {
        Subscriptions.mock.mockNetworkResponseEnabled = false
        Subscriptions.Identity.refreshToken = "refresh_token"
        guard let refreshToken = Subscriptions.Identity.refreshToken else { return }
        let extendSessionRequest = ExtendSessionRequest(token: refreshToken)
        let extendSessionEndpoint = IdentityEndpoint.extendUserSession(request: extendSessionRequest)

        XCTAssertTrue(extendSessionEndpoint.url!.pathComponents.contains("token"))

        let extendSessionEndpointBody = try? JSONSerialization.jsonObject(with: extendSessionEndpoint.body!,
                                                                          options: .allowFragments) as? [String: String]

        XCTAssertEqual((extendSessionEndpointBody?["token"]), "refresh_token")
        XCTAssertEqual((extendSessionEndpointBody?["grantType"]), "refresh-token")
    }

    func testExtendUserSessionSuccess() {
        Subscriptions.mock.result = .success
        Subscriptions.Identity.refreshToken = "refresh-token"
        let apiExpectation = expectation(description: "Extended user session successfully")
        guard let refreshToken = Subscriptions.Identity.refreshToken else { return }
        let extendSessionRequest = ExtendSessionRequest(token: refreshToken)
        let extendSessionEndpoint = IdentityEndpoint.extendUserSession(request: extendSessionRequest)

        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: extendSessionEndpoint.url)

        Subscriptions.Identity.extendUserSession {
            switch $0 {
            case .success(let response):
                XCTAssertNotNil(response)
                XCTAssertEqual(Subscriptions.Identity.accessToken, TestConstant.mockAccessToken)
                XCTAssertEqual(Subscriptions.Identity.refreshToken, TestConstant.mockRefreshToken)
            case .failure(let error):
                XCTFail("Failed to extend user session due to the following error: \(error)")
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }

    func testExtendUserSessionFailure() {
        Subscriptions.mock.result = .failure
        guard let refreshToken = Subscriptions.Identity.refreshToken else { return }
        let apiExpectation = expectation(description: "Failed to extend user session as expected")
        let extendSessionRequest = ExtendSessionRequest(token: refreshToken)
        let extendSessionEndpoint = IdentityEndpoint.extendUserSession(request: extendSessionRequest)

        MockURLProtocol.requestHandler = mockResponse(statusCode: 400, url: extendSessionEndpoint.url)

        Subscriptions.Identity.extendUserSession { result in
            apiExpectation.fulfill()
            if case let .failure(error) = result {
                XCTAssertNotNil(error as? SubscriptionsError)
            }
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }

    // TODO: AM-4867 - Fix broken unit tests
//    func testRememberMeSignUpSuccess() {
//        Commerce.mock.result = .success
//        var apiExpectation: XCTestExpectation? = expectation(description: "Sign up with remember me was a success")
//        guard let signUpRequest = SignUpRequest(from: signUpData) else {
//            XCTFail("Sign Up Request was nil")
//            return
//        }
//
//        let endpoint = IdentityEndpoint.signUp(signUpRequest, nil)
//        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: endpoint.url)
//
//        sut.signUp(user: signUpData, rememberMe: true) { result in
//            switch result {
//            case .success(_):
//                XCTAssertNotNil(self.sut.accessToken)
//                XCTAssertNotNil(self.sut.refreshToken)
//                XCTAssertTrue(Commerce.rememberMe)
//            case .failure(let error):
//                XCTFail("Sign Up failed due to the following error: \(error)")
//            }
//            apiExpectation?.fulfill()
//            apiExpectation = nil
//        }
//        if let expectation = apiExpectation {
//            wait(for: [expectation], timeout: TestConstant.expectationTimeout)
//        }
//    }

    func testRememberMeSignUpFailure() {
        Subscriptions.mock.result = .failure
        let apiExpectation = expectation(description: "Sign up with remember me failed")
        guard let signUpRequest = SignUpRequest(from: signUpData) else {
            XCTFail("Sign Up Request was nil")
            return
        }

        let endpoint = IdentityEndpoint.signUp(signUpRequest, nil)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 401, url: endpoint.url)

        var responseError: Error?

        Subscriptions.Identity.signUp(user: signUpData, rememberMe: true) { (result) in
            if case let .failure(error) = result {
                responseError = error
                XCTAssertFalse(Subscriptions.rememberMe)
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
        XCTAssertNotNil(responseError)
    }

    func testRememberMeLoginSuccess() {
        Subscriptions.mock.result = .success
        let apiExpectation = expectation(description: "Login with remember me was a success")
        let loginRequest = LoginRequest(userName: "mocktestuser", credentials: "Test123$!")
        let loginEndpoint = IdentityEndpoint.login(request: loginRequest)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: loginEndpoint.url)

        Subscriptions.Identity.logIn(username: loginRequest.userName,
                  password: loginRequest.credentials,
                  rememberMe: true) { (result) in
            switch result {
            case .success:
                XCTAssertNotNil(Subscriptions.Identity.accessToken, "Failed to save access token")
                XCTAssertNotNil(Subscriptions.cachedUserProfile)
                XCTAssertEqual(Subscriptions.cachedUserProfile?.uuid, "uuid")
                XCTAssertTrue(Subscriptions.rememberMe)
            case .failure(let error):
                XCTFail("Login failed due to the following reason : \(error)")
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }

    func testRememberMeLoginFailure() {
        Subscriptions.mock.result = .failure
        let apiExpectation = expectation(description: "Login with remember me failed")
        let loginRequest = LoginRequest(userName: "mocktestuser", credentials: "INCORRECT")
        let endpoint = IdentityEndpoint.login(request: loginRequest)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 401, url: endpoint.url)

        var responseError: Error?

        Subscriptions.Identity.logIn(username: "mocktestuser",
                  password: "Test123$",
                  rememberMe: true) { (result) in
            if case let .failure(error) = result {
                responseError = error
                XCTAssertFalse(Subscriptions.rememberMe)
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
        XCTAssertNotNil(responseError)
    }
}
