//
//  BaseNetworkTest.swift
//  ExampleTests
//
//  Created by Mahesh Venkateswarlu on 6/30/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

/// Parent class for any tests that require mock network responses for the Subscriptions service.
class SubscriptionsMockNetworkTest: XCTestCase {

    // custom urlsession for mock network calls
    var mockURLSession: URLSession!

    override func setUp() {
        Subscriptions.mock.mockNetworkResponseEnabled = true
    }

    override func tearDown() {
        Subscriptions.mock.mockNetworkResponseEnabled = false
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Set url session for mock networking
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockURLSession = URLSession(configuration: configuration)
        NetworkManager.session = mockURLSession
        Subscriptions.mock.mockNetworkResponseEnabled = true
        let arcConfiguration = ArcXPSubscriptionsConfiguration(baseUrl: TestConstant.configurationBaseUrl,
                                                          organization: TestConstant.configurationOrganization,
                                                          site: TestConstant.configurationSite,
                                                          environment: TestConstant.configurationEnvironment)
        Subscriptions.setUp(configuration: arcConfiguration)
    }
    
    override func tearDownWithError() throws {
        Subscriptions.logOut()
        Subscriptions.mock.mockNetworkResponseEnabled = false
        try super.tearDownWithError()
    }
    
    func mockResponse(statusCode: Int, url: URL?) -> (URLRequest) -> (HTTPURLResponse, URL) {
        
        return { request in
            guard let url = url else {
                XCTFail("Couldn't load the url")
                fatalError()
            }
            let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            return (response, url)
        }
    }

    /// Prepare a test expectation, and set up the mock network response parameters.
    /// - parameter description: The expected outcome.
    /// - parameter result: The intended result for this mock network test.
    /// - parameter statusCode: The intended status code for this mock network test.
    /// - parameter url: The URL that these parameters will be used for.
    /// - returns: An `XCTestExpectation` to be fulfilled upon the completed test.
    func prepareSubscriptionsNetworkExpectatation(with description: String,
                                                  result: Subscriptions.Mock.Result,
                                                  statusCode: Int,
                                                  endpoint: Endpoint,
                                                  version: Subscriptions.Mock.WebAPIVersion = .v1) -> XCTestExpectation {
        Subscriptions.mock.result = result
        Subscriptions.mock.version = version
        MockURLProtocol.requestHandler = mockResponse(statusCode: statusCode, url: endpoint.url)
        return expectation(description: description)
    }
}
