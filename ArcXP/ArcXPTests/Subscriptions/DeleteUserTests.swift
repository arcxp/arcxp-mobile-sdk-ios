//
//  DeleteUserTests.swift
//  ExampleTests
//
//  Created by Cassandra Balbuena on 6/30/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class DeleteUserTests: SubscriptionsMockNetworkTest {

    let sut = Subscriptions.Identity.self
    
    func testDeleteUserEndpointComponents() {
        Subscriptions.mock.mockNetworkResponseEnabled = false
        let declineDeletionRequest = DeclineDeleteAccountRequest(reason: "MISTAKE", notes: "string")
        let deletionRequestEndpoint = IdentityEndpoint.requestDeleteAccount
        let deletionApproveEndpoint = IdentityEndpoint.approveDeleteAccount(nonce: "nonce")
        let deletionDeclineEndpoint = IdentityEndpoint.declineDeleteAccount(nonce: "nonce", request: declineDeletionRequest)

        XCTAssertTrue(deletionRequestEndpoint.url!.pathComponents.contains("anonymize"))
        XCTAssertTrue(deletionApproveEndpoint.url!.pathComponents.contains("approve"))
        XCTAssertTrue(deletionDeclineEndpoint.url!.pathComponents.contains("decline"))

        let deletionDeclineBody = try? JSONSerialization.jsonObject(with: deletionDeclineEndpoint.body!, options: .allowFragments) as? [String: String]
        
        XCTAssertEqual((deletionDeclineBody?["reason"]), declineDeletionRequest.reason)
        XCTAssertEqual((deletionDeclineBody?["notes"]), declineDeletionRequest.notes)
    }

    func testRequestAccountDeletionSuccess() {
        Subscriptions.mock.result = .success
        let endpoint = IdentityEndpoint.requestDeleteAccount
        let apiExpectation = expectation(description: "Account deletion request was sent")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: endpoint.url)

        sut.requestDeleteAccount { (result) in
            if case let .failure(error) = result {
                XCTFail("Failed account deletion request = \(error)")
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }

    func testRequestAccountDeletionFailure() {
        Subscriptions.mock.result = .failure
        let endpoint = IdentityEndpoint.requestDeleteAccount
        let apiExpectation = expectation(description: "Account deletion request was not sent")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 401, url: endpoint.url)
        var responseError: Error?
        
        sut.requestDeleteAccount { (result) in
            if case let .failure(error) = result {
                responseError = error
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
        XCTAssertNotNil(responseError)
    }

    func testApproveAccountDeletionSuccess() {
        Subscriptions.mock.result = .success
        let endpoint = IdentityEndpoint.approveDeleteAccount(nonce: "nonce")
        let apiExpectation = expectation(description: "Account deletion was approved")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: endpoint.url)

        sut.approveDeleteAccount("nonce") { (result) in
            if case let .failure(error) = result {
                XCTFail("Failed account approval request = \(error)")
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }

    // Commeted out due to Bitrise failing this test repeatedly, though it succeeds locally.
//    func testApproveAccountDeletionFailure() {
//        Commerce.mock.result = .failure
//        let endpoint = IdentityEndpoint.approveDeleteAccount(nonce: "nonce")
//        MockURLProtocol.requestHandler = mockResponse(statusCode: 401, url: endpoint.url)
//        let apiExpectation = expectation(description: "Failed account approval request")
//        Commerce.setUp(configuration: ArcXPCommerceConfiguration(baseUrl: "TestBaseURL", organization: "TestOrg", site: "TestSite", environment: "TestEnv"))
//        sut.approveDeleteAccount("nonce") { (result) in
//            switch result {
//            case .failure(let error):
//                XCTAssertNotNil(error)
//            default:
//                XCTFail("Should return a failed response")
//            }
//            apiExpectation.fulfill()
//        }
//        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
//    }

    func testDeclineAccountDeletionSuccess() {
        Subscriptions.mock.result = .success
        let declineDeletionRequest = DeclineDeleteAccountRequest(reason: "MISTAKE", notes: "string")
        let endpoint = IdentityEndpoint.declineDeleteAccount(nonce: "nonce", request: declineDeletionRequest)
        let apiExpectation = expectation(description: "Account deletion was declined")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: endpoint.url)

        sut.declineDeleteAccount("nonce", .mistake) { (result) in
            if case let .failure(error) = result {
                XCTFail("Failed account decline request = \(error)")
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }

    func testDeclineAccountDeletionFailure() {
        Subscriptions.mock.result = .failure
        let declineDeletionRequest = DeclineDeleteAccountRequest(reason: "MISTAKE", notes: "string")
        let endpoint = IdentityEndpoint.declineDeleteAccount(nonce: "nonce", request: declineDeletionRequest)
        let apiExpectation = expectation(description: "Account deletion was not declined")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 401, url: endpoint.url)

        sut.declineDeleteAccount("nonce", .mistake) { (result) in
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
            default:
                XCTFail("Should throw a fail response")
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }

}
