//
//  ThirdPartyLoginUnitTests.swift
//  ExampleTests
//
//  Created by Cassandra Balbuena on 7/22/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class ThirdPartyLoginTests: SubscriptionsMockNetworkTest {

    let sut = Subscriptions.Identity.self
    let token = "token"

    func testThirdPartyLoginEndpoint() {
        Subscriptions.mock.mockNetworkResponseEnabled = false
        let thirdPartyLoginRequest = ThirdPartyLoginRequest(credentials: token, grantType: AuthService.facebook.rawValue)
        let thirdPartyEndpoint = IdentityEndpoint.thirdPartyLogin(request: thirdPartyLoginRequest)

        XCTAssertTrue(thirdPartyEndpoint.url!.pathComponents.contains("login"))

        let thirdPartyLoginEndpointBody = try? JSONSerialization.jsonObject(with: thirdPartyEndpoint.body!,
                                                                          options: .allowFragments) as? [String: String]

        XCTAssertEqual((thirdPartyLoginEndpointBody?["credentials"]), "token")
        XCTAssertEqual((thirdPartyLoginEndpointBody?["grantType"]), "facebook")
    }

    func testFacebookLoginSuccess() {
        Subscriptions.mock.result = .success
        let apiExpectation = expectation(description: "Facebook third party login successful")
        let thirdPartyLoginRequest = ThirdPartyLoginRequest(credentials: token, grantType: AuthService.facebook.rawValue)
        let thirdPartyEndpoint = IdentityEndpoint.thirdPartyLogin(request: thirdPartyLoginRequest)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: thirdPartyEndpoint.url)

        sut.logInWithFacebook(token: token) { result in
            switch result {
            case .success(let profile):
                XCTAssertNotNil(profile)
                XCTAssertNotNil(Subscriptions.cachedUserProfile)
                XCTAssertEqual(Subscriptions.cachedUserProfile?.uuid, "uuid")
            case .failure(let error):
                XCTFail("Third party login failed due to the following error: \(error)")
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }

    func testFacebookLoginFailure() {
        Subscriptions.mock.result = .failure
        let apiExpectation = expectation(description: "Third party login failed")
        let thirdPartyLoginRequest = ThirdPartyLoginRequest(credentials: token, grantType: AuthService.facebook.rawValue)
        let thirdPartyEndpoint = IdentityEndpoint.thirdPartyLogin(request: thirdPartyLoginRequest)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 401, url: thirdPartyEndpoint.url)

        var responseError: Error?

        sut.logInWithFacebook(token: token) { (result) in
            if case let .failure(error) = result {
                responseError = error
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
        XCTAssertNotNil(responseError)
    }

    func testGoogleLoginSuccess() {
        Subscriptions.mock.result = .success
        let apiExpectation = expectation(description: "Google third party login successful")
        let thirdPartyLoginRequest = ThirdPartyLoginRequest(credentials: token, grantType: AuthService.google.rawValue)
        let thirdPartyEndpoint = IdentityEndpoint.thirdPartyLogin(request: thirdPartyLoginRequest)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: thirdPartyEndpoint.url)

        sut.logInWithGoogle(token: token) { result in
            switch result {
            case .success(let profile):
                XCTAssertNotNil(profile)
                XCTAssertNotNil(Subscriptions.cachedUserProfile)
                XCTAssertEqual(Subscriptions.cachedUserProfile?.uuid, "uuid")
            case .failure(let error):
                XCTFail("Third party login failed due to the following error: \(error)")
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }

    func testGoogleLoginFailure() {
        Subscriptions.mock.result = .failure
        let apiExpectation = expectation(description: "Third party login failed")
        let thirdPartyLoginRequest = ThirdPartyLoginRequest(credentials: token, grantType: AuthService.google.rawValue)
        let thirdPartyEndpoint = IdentityEndpoint.thirdPartyLogin(request: thirdPartyLoginRequest)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 401, url: thirdPartyEndpoint.url)

        var responseError: Error?

        sut.logInWithGoogle(token: token) { (result) in
            if case let .failure(error) = result {
                responseError = error
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
        XCTAssertNotNil(responseError)
    }

    func testAppleLoginSuccess() {
        Subscriptions.mock.result = .success
        let apiExpectation = expectation(description: "Apple third party login successful")
        let thirdPartyLoginRequest = ThirdPartyLoginRequest(credentials: token, grantType: AuthService.apple.rawValue)
        let thirdPartyEndpoint = IdentityEndpoint.thirdPartyLogin(request: thirdPartyLoginRequest)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: thirdPartyEndpoint.url)

        sut.logInWithApple(token: token) { result in
            switch result {
            case .success(let profile):
                XCTAssertNotNil(profile)
                XCTAssertNotNil(Subscriptions.cachedUserProfile)
                XCTAssertEqual(Subscriptions.cachedUserProfile?.uuid, "uuid")
            case .failure(let error):
                XCTFail("Third party login failed due to the following error: \(error)")
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }

    func testAppleLoginFailure() {
        Subscriptions.mock.result = .failure
        let apiExpectation = expectation(description: "Third party login failed")
        let thirdPartyLoginRequest = ThirdPartyLoginRequest(credentials: token, grantType: AuthService.apple.rawValue)
        let thirdPartyEndpoint = IdentityEndpoint.thirdPartyLogin(request: thirdPartyLoginRequest)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 401, url: thirdPartyEndpoint.url)

        var responseError: Error?

        sut.logInWithApple(token: token) { (result) in
            if case let .failure(error) = result {
                responseError = error
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
        XCTAssertNotNil(responseError)
    }
}
