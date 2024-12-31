//
//  TenantConfigTests.swift
//  ExampleTests
//
//  Created by Mahesh Venkateswarlu on 7/13/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class TenantConfigTests: SubscriptionsMockNetworkTest {

    let sut = Subscriptions.Identity.self
    
    func testTenantConfigPathComponents() {
        Subscriptions.mock.mockNetworkResponseEnabled = false
        let profileEndpoint = IdentityEndpoint.config
        XCTAssertTrue(profileEndpoint.url!.pathComponents.contains("config"))
        XCTAssertEqual(profileEndpoint.method, "GET")
    }

    // TODO: AM-4867 - Fix broken unit tests
//    func testTenantApiConfigSuccess() throws {
//        let apiExpectation = expectation(description: "Tenant api fulfilled")
//        // mock response
//        let endpoint = IdentityEndpoint.config
//        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: endpoint.url)
//
//        Commerce.Identity.getConfig { result in
//            switch result {
//            case .success(let configOptions):
//                // Based on current org settings
//                XCTAssertFalse(configOptions.signinRecaptcha)
//                XCTAssertFalse(configOptions.signupRecaptcha)
//            case .failure(let error):
//                XCTFail("Failed to get the configuration, error = \(error)")
//            }
//
//            apiExpectation.fulfill()
//        }
//        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
//    }
}
