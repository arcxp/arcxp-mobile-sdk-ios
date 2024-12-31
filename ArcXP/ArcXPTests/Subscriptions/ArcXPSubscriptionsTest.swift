//
//  ArcXPSubscriptionsTest.swift
//  ArcXPSubscriptionsTest
//
//  Created by Seitz, David on 6/16/20.
//  Copyright © 2020 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class ArcXPSubscriptionsTest: XCTestCase {
    override func setUp() {
        let arcConfiguration = ArcXPSubscriptionsConfiguration(baseUrl: TestConstant.configurationBaseUrl,
                                                          organization: TestConstant.configurationOrganization,
                                                          site: TestConstant.configurationSite,
                                                          environment: TestConstant.configurationEnvironment)
        Subscriptions.setUp(configuration: arcConfiguration)
    }
    
    override func tearDown() {
        Subscriptions.logOut()
        Subscriptions.mock.mockNetworkResponseEnabled = false
    }
    
    func testLoginTokens() {
        Subscriptions.mock.mockNetworkResponseEnabled = true
        let apiExpectation = expectation(description: "Login was successful")
        Subscriptions.Identity.logIn(uuid: TestConstant.mockUUID,
                                     accessToken: TestConstant.mockAccessToken,
                                     refreshToken: TestConstant.mockRefreshToken) { result in
            switch result {
            case .success(let userProfile):
                XCTAssertEqual(userProfile.uuid, TestConstant.mockUUID)
                XCTAssertNotNil(Subscriptions.cachedUserProfile)
                XCTAssertEqual(Subscriptions.Identity.accessToken, TestConstant.mockAccessToken)
                XCTAssertEqual(Subscriptions.Identity.refreshToken, TestConstant.mockRefreshToken)            
            case .failure(let error):
                XCTFail("Login failed due to the following reason : \(error)")
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }
    
    func testEndpointWithHttps() {
        let arcConfiguration = ArcXPSubscriptionsConfiguration(baseUrl: "https://test.com",
                                                          organization: TestConstant.configurationOrganization,
                                                          site: TestConstant.configurationSite,
                                                          environment: TestConstant.configurationEnvironment)
        XCTAssertEqual(arcConfiguration.baseUrl, "https://test.com")
    }
    
    func testEndpointWithNoHttps() {
        let arcConfiguration = ArcXPSubscriptionsConfiguration(baseUrl: "test.com",
                                                          organization: TestConstant.configurationOrganization,
                                                          site: TestConstant.configurationSite,
                                                          environment: TestConstant.configurationEnvironment)
        XCTAssertEqual(arcConfiguration.baseUrl, "https://test.com")
    }
}
