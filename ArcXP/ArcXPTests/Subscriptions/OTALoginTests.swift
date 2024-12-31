//
//  OTALoginTests.swift
//  ExampleTests
//
//  Created by Mahesh Venkateswarlu on 6/27/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class OTALoginTests: SubscriptionsMockNetworkTest {
    
    let sut = Subscriptions.Identity.self

    func testOneTimeLoginEndPointPathComponents() {
        Subscriptions.mock.mockNetworkResponseEnabled = false
        let mockEmail = TestConstant.mockUserEmail
        let otaLinkRequest = OTALinkRequest(email: mockEmail)
        let endpoint = IdentityEndpoint.requestOTALink(request: otaLinkRequest)
        XCTAssertTrue(endpoint.url!.pathComponents.contains("magiclink"))
        let body = try? JSONSerialization.jsonObject(with: endpoint.body!, options: .allowFragments) as? [String: String]
        XCTAssertEqual((body!["email"]), mockEmail)
    }
    
    
    func testOneTimeLoginAPISuccess() {
        Subscriptions.mock.result = .success
        let mockEmail = TestConstant.mockUserEmail
        
        // mock response
        let endpoint = IdentityEndpoint.requestOTALink(request: OTALinkRequest(email: mockEmail))
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: endpoint.url)   //magicklink.json
        
        let apiExpectation = expectation(description: "OTA Link sent")
        sut.requestOneTimeAccessLink(email: mockEmail) { (result) in
            apiExpectation.fulfill()
            if case let .failure(error) = result {
                XCTFail("Failed One time access email generation = \(error)")
            }
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }
    
    func testOneTimeLoginAPIFailure() {
        Subscriptions.mock.result = .failure
        let mockEmail = TestConstant.mockUserEmail
        
        // mock response
        let endpoint = IdentityEndpoint.requestOTALink(request: OTALinkRequest(email: mockEmail))
        MockURLProtocol.requestHandler = mockResponse(statusCode: 401, url: endpoint.url)
        
        let apiExpectation = expectation(description: "OTA Link sent failure")
        sut.requestOneTimeAccessLink(email: mockEmail) { (result) in
            apiExpectation.fulfill()
            if case let .failure(error) = result {
                XCTAssertNotNil(error)
                XCTAssertNotNil(error as? SubscriptionsError)
                let urlRequestError = error as! SubscriptionsError
                switch urlRequestError {
                case .URLRequestError(reason: .unauthorizedError(let statusCode,
                                                                 let code,
                                                                 let message)):
                    XCTAssertEqual(statusCode, 401)
                    XCTAssertEqual(code, "300040")
                    XCTAssertEqual(message, "Authentication failed")
                default:
                    XCTFail("Should throw a fail response")
                }
            }
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }
    
    func testRedeemOTALoginAPISuccess() {
        Subscriptions.mock.result = .success
        let nonceValue = TestConstant.mockNonce
        
        // mock response
        let endpoint = IdentityEndpoint.redeemOTALink(nonceString: nonceValue)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: endpoint.url) //nonce.json
        
        let apiExpectation = expectation(description: "Nonce redeemed")
        sut.redeemOneTimeAccessLink(nonce: nonceValue) { (result) in
            apiExpectation.fulfill()
            if case let .failure(error) = result {
                XCTFail("Failed One time access email generation = \(error)")
            }
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }
    
    func testRedeemOTALoginAPIFailure() {
        Subscriptions.mock.result = .failure
        let nonceValue = TestConstant.mockNonce
        
        // mock response
        let endpoint = IdentityEndpoint.redeemOTALink(nonceString: nonceValue)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 401, url: endpoint.url)
        
        let apiExpectation = expectation(description: "Redemption failure")
        sut.redeemOneTimeAccessLink(nonce: nonceValue) { (result) in
            apiExpectation.fulfill()
            if case let .failure(error) = result {
                XCTAssertNotNil(error as? SubscriptionsError)
            }
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }
}
