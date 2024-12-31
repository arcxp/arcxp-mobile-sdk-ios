//
//  AnalyticsNetworkTest.swift
//  ArcXPTests
//
//  Created by Cassandra Balbuena on 3/13/23.
//  Copyright © 2023 Arc XP. All rights reserved.

import XCTest
@testable import ArcXP

final class AnalyticsNetworkTest: XCTestCase {
    // custom urlsession for mock network calls
    private var provider: SplunkProvider!
    private let expectationTimeOut = 10.0

    private let mockOrgName = "ArcXP"
    private let mockServerEnv = "sandbox"
    private let mockSite = "Site"
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        provider = SplunkProvider(org: mockOrgName,
                                  site: mockSite,
                                  environment: mockServerEnv)
    }

    override func tearDown() {
        provider = nil
    }
    
    func testSendSuccess() {
        let mockURLSession = URLSession(mockResponder: MockSplunkURLResponder.self)
        URLRequest.session = mockURLSession
        let apiExpectation = expectation(description: "Successful mock analytics reporting.")
        
        provider.reportEvent(event: .install) { result in
            switch result {
            case .success(let data):
                XCTAssertNotNil(data)
                XCTAssertNotNil(result.value)
                guard let responseString = String(data: result.value!, encoding: .utf8) else {
                    XCTFail()
                    return
                }
                XCTAssert(responseString.contains("Success"))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testSendEventFailureError() throws {
        let mockURLSession = URLSession(mockResponder: MockSplunkErrorURLResponder.self)
        URLRequest.session = mockURLSession
        let apiExpectation = expectation(description: "Failed mock analytics reporting with error.")
        
        provider.reportEvent(event: .install) { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error)
            } else {
                XCTFail("Operation was successful instead of failing, as expected.")
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testSendEventFailureResponse() throws {
        let mockURLSession = URLSession(mockResponder: MockSplunkFailureURLResponder.self)
        URLRequest.session = mockURLSession
        let apiExpectation = expectation(description: "Failed mock analytics reporting with response.")
        
        provider.reportEvent(event: .install) { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error)
            } else {
                XCTFail("Operation was successful instead of failing, as expected.")
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
}
