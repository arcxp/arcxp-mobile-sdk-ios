//
//  IdentityTests.swift
//  ArcXPTests
//
//  Created by David Seitz on 2/1/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class IdentityTests: SubscriptionsMockNetworkTest {

    override func setUp() {
        super.setUp()
        Subscriptions.Identity.TestConstant.useTestValue = true
    }

    override func tearDown() {
        Subscriptions.Identity.TestConstant.useTestValue = false
        super.tearDown()
    }

    // MARK: - Sign Up

    func testSignUpSuccess() {

        // Create the sign up endpoint
        guard let signUpEndpoint = signUpEndpoint() else {
            XCTFail("Failed to create sign up endpoint.")
            return
        }

        // Prepare the expectation and set the mock network parameters
        var apiExpectation: XCTestExpectation? = prepareSubscriptionsNetworkExpectatation(with: "Sign up succeeded.",
                                                                                          result: .success,
                                                                                          statusCode: 200,
                                                                                          endpoint: signUpEndpoint)
        // Perform the sign up network request.
        Subscriptions.Identity.signUp(user: mockNewUserProfile) { result in

            switch result {
            case .success(let userProfile):
                XCTAssertNotNil(userProfile)
                guard let accessToken = Subscriptions.Identity.accessToken,
                      let refreshToken = Subscriptions.Identity.refreshToken else {
                    XCTFail("Failed sign up due to missing tokens.")
                    return
                }
                XCTAssertNotNil(accessToken)
                XCTAssertNotNil(refreshToken)
            case .failure(let error):
                XCTFail("Sign Up failed due to the following error: \(error)")
            }
            apiExpectation?.fulfill()
            apiExpectation = nil
        }

        // Create a timeout for the expectation.
        if let expectation = apiExpectation {
            wait(for: [expectation], timeout: TestConstant.expectationTimeout)
        }
    }

    func testSignUpFailure() {

        // Create the sign up endpoint
        guard let signUpEndpoint = signUpEndpoint() else {
            XCTFail("Failed to create sign up endpoint.")
            return
        }

        var apiExpectation: XCTestExpectation? = prepareSubscriptionsNetworkExpectatation(with: "Sign up request failed.",
                                                                                          result: .failure,
                                                                                          statusCode: 401,
                                                                                          endpoint: signUpEndpoint)
        var expectedError: Error?
        Subscriptions.Identity.signUp(user: mockNewUserProfile) { result in
            if case let .failure(error) = result {
                expectedError = error
            }
            apiExpectation?.fulfill()
            apiExpectation = nil
        }
        if let expectation = apiExpectation {
            wait(for: [expectation], timeout: TestConstant.expectationTimeout)
        }
        XCTAssertEqual(expectedError?.localizedDescription, "Access denied:\nStatus code 400\nCode 300009,300081\ninput validation error")
    }

    /// Test failure when config options exist, but no ReCaptcha is provided.
    func testSignUpRecaptchaFail() {
        // Set up mock config options
        let mockConfigOptions = ConfigOptions(signupRecaptcha: true,
                                              signinRecaptcha: false,
                                              magicLinkRecaptcha: false,
                                              recaptchaSiteKey: "TestRecaptchaSiteKey")
        let originalConfigOptions = Subscriptions.configOptions
        Subscriptions.configOptions = mockConfigOptions

        // Create the sign up endpoint
        guard let signUpEndpoint = signUpEndpoint() else {
            XCTFail("Failed to create sign up endpoint.")
            return
        }
        var expectedError: Error?
        // Perform the sign up network request.
        Subscriptions.Identity.signUp(user: mockNewUserProfile) { result in
            switch result {
            case .success:
                XCTFail("Expected failure due to missing signup recaptcha.")
                return
            case .failure(let error):
                XCTAssertEqual(error.localizedDescription, "No data was provided while: attempting to sign up for new Commerce account with recaptcha.")
                expectedError = error
            }
            Subscriptions.configOptions = originalConfigOptions
        }
        XCTAssertNotNil(expectedError)
    }

    func testRequiredSignUpDataFail() {
        let mockErrorUserProfile = mockNewUserProfile
        mockErrorUserProfile.userName = nil
        var expectedError: Error?
        Subscriptions.Identity.signUp(user: mockErrorUserProfile) { result in
            switch result {
            case .success:
                XCTFail("Expected failure due to missing signup recaptcha.")
                return
            case .failure(let error):
                XCTAssertEqual(error.localizedDescription, "No data was provided while: attempting to sign up without required fields")
                expectedError = error
            }
        }
        XCTAssertNotNil(expectedError)
    }

    func testSignUpEndpointComponents() {
        // Turn off mock network responses to test sign up request object.
        Subscriptions.mock.mockNetworkResponseEnabled = false
        guard let signUpRequest = SignUpRequest(from: mockNewUserProfile) else {
            XCTFail("Sign Up Request was nil")
            return
        }
        let endpoint = IdentityEndpoint.signUp(signUpRequest, nil)
        XCTAssertTrue(endpoint.url!.pathComponents.contains("signup"))
        let body = try? JSONSerialization.jsonObject(with: endpoint.body!, options: .allowFragments) as? [String: Any]
        guard let userProfile = body?["profile"] as? UserProfile else { return }
        XCTAssertEqual(userProfile.email, mockNewUserProfile.email)
        Subscriptions.mock.mockNetworkResponseEnabled = true
    }

    // MARK: - Convenience Methods

    /// Creates the standard sign up endpoint used in multiple test methods.
    private func signUpEndpoint() -> IdentityEndpoint? {
        guard let signUpRequest = SignUpRequest(from: mockNewUserProfile) else {
            return nil
        }
        return IdentityEndpoint.signUp(signUpRequest, nil)
    }

    func testGetValidAccessToken() {
        Subscriptions.Identity.TestConstant.useTestValue = true
        Subscriptions.Identity.TestConstant.testAccessToken = TestConstant.mockValidAccessToken

        Subscriptions.Identity.getAccessToken { result in
            switch result {
            case .success(let jwt):
                XCTAssertNotNil(jwt)
                guard let name = jwt.body["name"] as? String else {
                    XCTFail("Expected JWT value is not available.")
                    return
                }
                XCTAssertEqual(name, "John Doe")
            case .failure(let error):
                XCTFail("An error occurred while testing for a valid JWT access token. Error: \(error.localizedDescription)")
            }
        }
    }

    func testGetInvalidAccessToken() {
        Subscriptions.Identity.TestConstant.useTestValue = true
        Subscriptions.Identity.TestConstant.testAccessToken = TestConstant.mockAccessToken

        Subscriptions.Identity.getAccessToken { result in
            switch result {
            case .success:
                XCTFail("Expected an error to be returned for an invalid JWT access token.")
            case .failure(let error):
                XCTAssertNotNil(error)
            }
        }
    }

    func testGetAccessTokenNil() {
        Subscriptions.Identity.TestConstant.useTestValue = true
        Subscriptions.Identity.TestConstant.testAccessToken = nil

        Subscriptions.Identity.getAccessToken { result in
            switch result {
            case .success:
                XCTFail("Expected an error to be returned for a nil access token.")
            case .failure(let error):
                XCTAssertNotNil(error)
                XCTAssertEqual(error.localizedDescription, "Attempted to fetch the user's access token, but did not find one. This may be because the backend never delivered one.")
            }
        }
    }

    func testGetConfigSuccess() {
        let expectation = prepareSubscriptionsNetworkExpectatation(with: "Config returned successfully.",
                                                                   result: .success,
                                                                   statusCode: 200,
                                                                   endpoint: IdentityEndpoint.config)
        Subscriptions.Identity.getConfig { result in
            switch result {
            case .success(let configOptions):
                XCTAssertFalse(configOptions.signupRecaptcha)
                XCTAssertFalse(configOptions.signinRecaptcha)
                XCTAssertFalse(configOptions.magicLinkRecaptcha)
                XCTAssertEqual(configOptions.recaptchaSiteKey, "some-api-site-key")
            case .failure:
                XCTFail("Expected to receive a success result with config options.")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TestConstant.expectationTimeout)
    }

    func testGetConfigFailure() {
        let expectation = prepareSubscriptionsNetworkExpectatation(with: "Network request returns unexpected internal server error.",
                                                                   result: .failure,
                                                                   statusCode: 500,
                                                                   endpoint: IdentityEndpoint.config)
        Subscriptions.Identity.getConfig { result in
            switch result {
            case .success:
                XCTFail("Expected a failure response.")
            case .failure(let error):
                XCTAssertNotNil(error)
                if case SubscriptionsError.URLRequestError(reason: .httpError(500)) = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Unexpected error.")
                }
            }
        }
        wait(for: [expectation], timeout: TestConstant.expectationTimeout)
    }

    // MARK: - Commerce.swift Tests

    func testIsLoggedInTrue() {
        // Setting access token manually due to cache value not returning in test environment.
        Subscriptions.Identity.TestConstant.useTestValue = true
        Subscriptions.Identity.TestConstant.testAccessToken = "mockAccessToken"
        Subscriptions.isLoggedIn { result in
            XCTAssertTrue(result)
        }
    }

    func testIsLoggedInFalse() {
        Subscriptions.Identity.TestConstant.useTestValue = true
        Subscriptions.Identity.TestConstant.testAccessToken = nil
        Subscriptions.isLoggedIn { result in
            XCTAssertFalse(result)
        }
    }

    // MARK: - Test Values

    /// Mock user profile data for new sign up requets.
    private var mockNewUserProfile = UserProfile(userName: TestConstant.mockUsername,
                                                 password: TestConstant.mockUserPassword,
                                                 email: TestConstant.mockUserEmail)
}
