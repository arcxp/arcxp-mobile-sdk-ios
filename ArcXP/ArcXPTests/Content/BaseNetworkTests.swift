//
//  BaseNetworkTests.swift
//  ArcXPContentTests
//
//  Created by Davis, Tyler on 1/24/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class BaseNetworkTests: XCTestCase {

    // custom urlsession for mock network calls
    var mockURLSession: URLSession!
    
    let expectationTimeOut = 10.0
    
    let mockOrgName = "ArcXP"
    let mockServerEnv = ServerEnvironment.sandbox
    let mockSite = "Site"
    let mockDomain = "arcsales-arcsales-sandbox.web.arc-cdn.net"
    
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Set url session for mock networking
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockURLSession = URLSession(configuration: configuration)
        URLRequest.session = mockURLSession
        ArcXPContentManager.client.mock.useMocks = true
        ArcXPContentManager.setUp(configuration: ArcXPContentConfig(organizationName: mockOrgName,
                                                           serverEnvironment: mockServerEnv,
                                                           site: mockSite,
                                                           hostDomain: mockDomain))
    }
    
    override func tearDownWithError() throws {
        ArcXPContentManager.client.mock.useMocks = false
        try super.tearDownWithError()
    }
    
    func mockResponse(statusCode: Int, url: URL?) -> (URLRequest) -> (HTTPURLResponse, URL) {
        return { _ in
            guard let url = url else {
                XCTFail("Couldn't load the url")
                fatalError()
            }
            let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            return (response, url)
        }
    }
}
