//
//  PasswordResetTests.swift
//  ExampleTests
//
//  Created by Mahesh Venkateswarlu on 6/30/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class PasswordResetTests: SubscriptionsMockNetworkTest {

    let sut = Subscriptions.Identity.self
    
    func testResetPasswordEndPointPathComponents() {
        Subscriptions.mock.mockNetworkResponseEnabled = false
        let mockUserName = "mocktestuser"
        let resetPasswordRequest = ResetPasswordEmailRequest(userName: mockUserName)
        let endpoint = IdentityEndpoint.requestResetPassword(request: resetPasswordRequest)
        XCTAssertTrue(endpoint.url!.pathComponents.contains("reset"))
        let body = try? JSONSerialization.jsonObject(with: endpoint.body!, options: .allowFragments) as? [String: String]
        XCTAssertEqual((body!["userName"]), mockUserName)
    }
    
    func testRequestResetPasswordAPISuccess() {
        Subscriptions.mock.result = .success
        let mockUserName = "mocktestuser"
        
        // mock response
        let endpoint = IdentityEndpoint.requestResetPassword(request: ResetPasswordEmailRequest(userName: mockUserName))
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: endpoint.url)   //reset.json
        
        let apiExpectation = expectation(description: "Reset password Link sent")
        sut.requestResetPassword(username: mockUserName) { (result) in
            apiExpectation.fulfill()
            if case let .failure(error) = result {
                XCTFail("Failed to generate password reset email = \(error)")
            }
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }
    
    func testRequestResetPasswordAPIFailure() {
        Subscriptions.mock.result = .failure
        let mockUserName = "$%"
        
        // mock response
        let endpoint = IdentityEndpoint.requestResetPassword(request: ResetPasswordEmailRequest(userName: mockUserName))
        MockURLProtocol.requestHandler = mockResponse(statusCode: 400, url: endpoint.url)
        
        let apiExpectation = expectation(description: "Reset password Link failure")
        sut.requestResetPassword(username: mockUserName) { (result) in
            apiExpectation.fulfill()
            if case let .failure(error) = result {
                XCTAssertNotNil(error)
                XCTAssertNotNil(error as? SubscriptionsError)
                let urlRequestError = error as! SubscriptionsError
                switch urlRequestError {
                case .URLRequestError(reason: .badRequest(let statusCode,
                                                                 let code,
                                                                 let message)):
                    XCTAssertEqual(statusCode, 400)
                    XCTAssertEqual(code, "300301")
                    XCTAssertEqual(message, "userName must be between 5 and 100 characters long")
                default:
                    XCTFail("Should throw a fail response")
                }
            }
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }
    
    func testResetPasswordAPISuccess() {
        Subscriptions.mock.result = .success
        let nonceValue = "nonce"
        
        // mock response
        let endpoint = IdentityEndpoint.resetPassword(nonceString: nonceValue, request: ResetPasswordRequest(newPassword: "NEW_PASSWORD"))
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: endpoint.url)   //reset.json
        
        let apiExpectation = expectation(description: "Redemption success")
        sut.resetPassword(nonce: nonceValue, newPassword: "Test123$") { (result) in
            apiExpectation.fulfill()
            if case let .failure(error) = result {
                XCTFail("Failed to reset password = \(error)")
            }
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }
    
    func testResetPasswordAPIFailure() {
        Subscriptions.mock.result = .failure
        let nonceValue = "nonce"
        
        // mock response
        let endpoint = IdentityEndpoint.resetPassword(nonceString: nonceValue, request: ResetPasswordRequest(newPassword: "NEW_PASSWORD"))
        MockURLProtocol.requestHandler = mockResponse(statusCode: 400, url: endpoint.url)   //reset.json
        
        let apiExpectation = expectation(description: "Redemption success")
        sut.resetPassword(nonce: nonceValue, newPassword: "NEW_PASSWORD") { (result) in
            apiExpectation.fulfill()
            if case let .failure(error) = result {
               XCTAssertNotNil(error as? SubscriptionsError)
            }
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }
    
    func testUpdatePasswordAPISuccess() {
        Subscriptions.mock.result = .success
        let oldPassword = "OLD_PASSWORD"
        let newPassword = "NEW_PASSWORD"
        
        // mock response
        Subscriptions.Identity.accessToken = TestConstant.mockAccessToken
        let endpoint = IdentityEndpoint.updateLoginPassword(request: UpdatePasswordRequest(oldPassword: oldPassword, newPassword: newPassword))
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: endpoint.url)   //reset.json
        
        let apiExpectation = expectation(description: "Redemption success")
        sut.updatePassword(oldPassword: oldPassword, newPassword: newPassword, completion: { (result) in
            apiExpectation.fulfill()
            if case let .failure(error) = result {
                XCTFail("Failed to reset password = \(error)")
            }
        })
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }
    
    func testUpdatePasswordAPIFailure() {
        Subscriptions.mock.result = .failure
        let oldPassword = "OLD_PASSWORD"
        let newPassword = "FAIL"
        
        // mock response
        Subscriptions.Identity.accessToken = TestConstant.mockAccessToken
        let endpoint = IdentityEndpoint.updateLoginPassword(request: UpdatePasswordRequest(oldPassword: oldPassword, newPassword: newPassword))
        MockURLProtocol.requestHandler = mockResponse(statusCode: 400, url: endpoint.url)   //reset.json
        
        let apiExpectation = expectation(description: "Update fail")
        sut.updatePassword(oldPassword: oldPassword, newPassword: newPassword, completion: { (result) in
            apiExpectation.fulfill()
            if case let .failure(error) = result {
               XCTAssertNotNil(error as? SubscriptionsError)
            }
        })
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }
    
    func testUpdatePasswordAPIFailureWithNoAccessToken() {
        let oldPassword = "OLD_PASSWORD"
        let newPassword = "FAIL"
        
        // mock response
        let apiExpectation = expectation(description: "Update fail")
        sut.updatePassword(oldPassword: oldPassword, newPassword: newPassword, completion: { (result) in
            apiExpectation.fulfill()
            if case let .failure(error) = result {
               XCTAssertNotNil(error as? SubscriptionsError)
                let urlRequestError = error as! SubscriptionsError
                switch urlRequestError {
                case .userAccountError(reason:let reason):
                   print(reason)
                default:
                    XCTFail("Should throw a fail response")
                }
            }
        })
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }
    
}
