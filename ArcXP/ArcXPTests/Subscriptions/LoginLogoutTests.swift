//
//  LoginLogoutTests.swift
//  ExampleTests
//
//  Created by Cassandra Balbuena on 7/1/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class LoginLogoutTests: SubscriptionsMockNetworkTest {

    func testLoginEndpointComponents() {
        Subscriptions.mock.mockNetworkResponseEnabled = false
        let loginRequest = LoginRequest(userName: TestConstant.mockUsername, credentials: TestConstant.mockUserPassword)
        let loginEndpoint = IdentityEndpoint.login(request: loginRequest)

        XCTAssertTrue(loginEndpoint.url!.pathComponents.contains("login"))

        let loginEndpointBody = try? JSONSerialization.jsonObject(with: loginEndpoint.body!, options: .allowFragments) as? [String: Any]

        guard let identity = loginEndpointBody?["identity"] as? SignUpRequest.Identity else { return }
        XCTAssertTrue((identity as Any) is SignUpRequest.Identity)
        XCTAssertEqual(identity.userName, loginRequest.userName)
        XCTAssertEqual(identity.credentials, loginRequest.credentials)
    }

    func testLoginSuccess() {
        Subscriptions.mock.result = .success
        let apiExpectation = expectation(description: "Login was successful")
        let loginRequest = LoginRequest(userName: TestConstant.mockUsername, credentials: TestConstant.mockUserPassword)
        let loginEndpoint = IdentityEndpoint.login(request: loginRequest)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: loginEndpoint.url)

        Subscriptions.Identity.logIn(username: loginRequest.userName, password: loginRequest.credentials) { result in
            switch result {
            case .success:
                XCTAssertNotNil(Subscriptions.Identity.accessToken, "Failed to save access token")
                XCTAssertNotNil(Subscriptions.cachedUserProfile)
                XCTAssertEqual(Subscriptions.cachedUserProfile?.uuid, "uuid")
            case .failure(let error):
                XCTFail("Login failed due to the following reason : \(error)")
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }

    func testLoginFailure() {
        Subscriptions.mock.result = .failure
        let apiExpectation = expectation(description: "Login failed")
        let loginRequest = LoginRequest(userName: TestConstant.mockUsername, credentials: "INCORRECT")
        let endpoint = IdentityEndpoint.login(request: loginRequest)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 401, url: endpoint.url)

        var responseError: Error?

        Subscriptions.Identity.logIn(username: TestConstant.mockUsername, password: TestConstant.mockUserPassword) { (result) in
            if case let .failure(error) = result {
                responseError = error
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
        XCTAssertNotNil(responseError)
    }

    func testLogoutSuccess() {
        // mock the user as logged in
        Subscriptions.cachedUserProfile = UserProfile(userName: TestConstant.mockUsername,
                                                 password: TestConstant.mockUserPassword,
                                                 email: TestConstant.mockUserEmail,
                                                 firstName: TestConstant.mockUserFirstName,
                                                 lastName: TestConstant.mockUserLastName,
                                                 displayName: TestConstant.mockUserDisplayName)
        Subscriptions.Identity.accessToken = TestConstant.mockAccessToken
        
        Subscriptions.logOut()
        XCTAssertNil(Subscriptions.cachedUserProfile)
        XCTAssertNil(Subscriptions.Identity.accessToken)
        XCTAssertNil(Subscriptions.configOptions)
        XCTAssertEqual(0, Subscriptions.Identity.queuedUserProfileUpdates.count)
    }
}
