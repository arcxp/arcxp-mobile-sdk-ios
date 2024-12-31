//
//  EndpointTests.swift
//  ArcXPContentTests
//
//  Created by Davis, Tyler on 1/31/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//
// swiftlint:disable force_cast line_length
import XCTest
@testable import ArcXP

class EndpointTests: BaseNetworkTests {
    
    let client = ArcXPContentManager.client
    
    func testStoryContentEndPoints() {
        ArcXPContentManager.setUp(configuration: ArcXPContentConfig(organizationName: mockOrgName,
                                                           serverEnvironment: mockServerEnv,
                                                           site: mockSite,
                                                           hostDomain: mockDomain))
        client.mock.useMocks = false
        let expectedURL = URL(string: "https://arcsales-arcsales-sandbox.web.arc-cdn.net/arc/outboundfeeds/article/?_id=IENBVUAQDJBULNIBQBCKIPV2YQ")
        let endpoint = FeedsEndpoint.contentById("IENBVUAQDJBULNIBQBCKIPV2YQ")
        XCTAssertEqual(expectedURL?.absoluteString, endpoint.url?.absoluteString)
    }
    
    func testEndPointWithNoHttps() {
        ArcXPContentManager.setUp(configuration: ArcXPContentConfig(organizationName: mockOrgName,
                                                           serverEnvironment: mockServerEnv,
                                                           site: mockSite,
                                                           hostDomain: "arcsales-arcsales-sandbox.web.arc-cdn.net"))
        let expectedURL = URL(string: "https://arcsales-arcsales-sandbox.web.arc-cdn.net/arc/outboundfeeds/article/?_id=IENBVUAQDJBULNIBQBCKIPV2YQ")
        let endpoint = FeedsEndpoint.contentById("IENBVUAQDJBULNIBQBCKIPV2YQ")
        client.mock.useMocks = false
        XCTAssertEqual(expectedURL?.absoluteString, endpoint.url?.absoluteString)
    }
    
    func testSectionEndPointMalformed() {
        // This fails because the hostDomain & hierarchy has a space and a valid url can't be constructed
        ArcXPContentManager.setUp(configuration: ArcXPContentConfig(organizationName: mockOrgName,
                                                           serverEnvironment: mockServerEnv,
                                                           site: mockSite,
                                                           hostDomain: "arc sales-arcsales-sandbox.web.arc-cdn.net"))
        client.mock.useMocks = false
        let apiExpectation = expectation(description: "Endpoint malformed")
        client.getSectionList(siteHierarchy: "mobile nav",
                              shouldIgnoreCache: true) { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error as? NetworkError)
                let urlRequestError = error as! NetworkError
                XCTAssertEqual(urlRequestError.errorDescription, NetworkError.URLRequestError(reason: .endpointMalformed).errorDescription)
            }
            apiExpectation.fulfill()
            // Reset back to its defaults
            ArcXPContentManager.setUp(configuration: ArcXPContentConfig(organizationName: self.mockOrgName,
                                                               serverEnvironment: self.mockServerEnv,
                                                               site: self.mockSite,
                                                               hostDomain: "https://arcsales-arcsales-sandbox.web.arc-cdn.net"))
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
//    func testStoryContentEndPointMalformed() {
//        client.mock.mockType = .success
//        let apiExpectation = expectation(description: "URL failure")
//        // This fails because the identifier has a space and a valid url can't be constructed
//        client.getStoryContent(identifier: "Story Id", shouldIgnoreCache: true) { result in
//            if case let .failure(error) = result {
//                XCTAssertNotNil(error as? NetworkError)
//                let urlRequestError = error as! NetworkError
//                XCTAssertEqual(urlRequestError.errorDescription, NetworkError.URLRequestError(reason: .endpointMalformed).errorDescription)
//                apiExpectation.fulfill()
//            }
//        }
//        wait(for: [apiExpectation], timeout: expectationTimeOut)
//    }
    
    func testEndPointWithSlashSuffix() {
        ArcXPContentManager.setUp(configuration: ArcXPContentConfig(organizationName: mockOrgName,
                                                           serverEnvironment: mockServerEnv,
                                                           site: mockSite,
                                                           hostDomain: "arcsales-arcsales-sandbox.web.arc-cdn.net/"))
        let expectedURL = URL(string: "https://arcsales-arcsales-sandbox.web.arc-cdn.net/arc/outboundfeeds/article/?_id=IENBVUAQDJBULNIBQBCKIPV2YQ")
        let endpoint = FeedsEndpoint.contentById("IENBVUAQDJBULNIBQBCKIPV2YQ")
        client.mock.useMocks = false
        XCTAssertEqual(expectedURL?.absoluteString, endpoint.url?.absoluteString)
    }
    
    func testCollectionEndpointForSlashPrefixedAlias() {
        client.cacheConfiguration.shouldPreloadCache = false
        let endpoint = FeedsEndpoint.collection("/test", index: 0, size: 10)
        let urlPath = endpoint.path
        XCTAssertEqual(urlPath, "/collection/test")
        XCTAssertEqual(endpoint.urlParameters!["size"], "10")
        client.cacheConfiguration.shouldPreloadCache = true
    }

    func testCollectionAliasEndpointPreloadingFalse() {
        client.cacheConfiguration.shouldPreloadCache = false
        let endpoint = FeedsEndpoint.collection("test", index: 0, size: 10)
        let urlPath = endpoint.path
        XCTAssertEqual(urlPath, "/collection/test")
        XCTAssertEqual(endpoint.urlParameters!["size"], "10")
        client.cacheConfiguration.shouldPreloadCache = true
    }
    
    func testCollectionAliasEndpointPreloadingTrue() {
        let endpoint = FeedsEndpoint.collection("test", index: 0, size: 10)
        let urlPath = endpoint.path
        XCTAssertEqual(urlPath, "/collection-full/test")
        XCTAssertEqual(endpoint.urlParameters!["size"], "10")
    }
    
//    func testCollectionEndPointMalformed() {
//        client.mock.useMocks = false
//        let apiExpectation = expectation(description: "URL failure")
//        // This fails because the identifier has a space and a valid url can't be constructed
//        client.getCollection(alias: "Alias ID", shouldIgnoreCache: true) { result in
//             if case let .failure(error) = result {
//                XCTAssertNotNil(error as? NetworkError)
//                let urlRequestError = error as! NetworkError
//                XCTAssertEqual(urlRequestError.errorDescription, NetworkError.URLRequestError(reason: .endpointMalformed).errorDescription)
//                apiExpectation.fulfill()
//            }
//        }
//        wait(for: [apiExpectation], timeout: expectationTimeOut)
//    }

    func testSearchEndpoint() {
        let endpoint = FeedsEndpoint.search(["first", "second", "third", "fourth"], fromIndex: 0, listSize: 10)
        let urlPath = endpoint.path
        XCTAssertEqual(urlPath, "/search/first,%20second,%20third,%20fourth")
        XCTAssertEqual(endpoint.urlParameters!["size"], "10")
    }
    
    func testSearchEndpointWithSpace() {
        let endpoint = FeedsEndpoint.search(["first", "second withSpace", "third", "fourth"], fromIndex: 0, listSize: 10)
        let urlPath = endpoint.path
        XCTAssertEqual(urlPath, "/search/first,%20second%20withSpace,%20third,%20fourth")
        XCTAssertEqual(endpoint.urlParameters!["size"], "10")
    }
    
    func testSearchMaxSizeEndpoint() {
        let endpoint = FeedsEndpoint.search(["first", "second", "third", "fourth"], fromIndex: 0, listSize: 40)
        let urlPath = endpoint.path
        XCTAssertEqual(urlPath, "/search/first,%20second,%20third,%20fourth")
        XCTAssertEqual(endpoint.urlParameters!["size"], "20")
    }

    func testSectionListEndpoint() {
        let endpoint = FeedsEndpoint.sectionList("mobile-nav")
        let urlPath = endpoint.path
        XCTAssertEqual(urlPath, "/navigation/mobile-nav")
    }
    
    func testSearchVideoEndpoint() {
        let endpoint = FeedsEndpoint.searchVideo(["first", "second", "third", "fourth"], fromIndex: 0, listSize: 10)
        let urlPath = endpoint.path
        XCTAssertEqual(urlPath, "/searchVideo/first,%20second,%20third,%20fourth")
        XCTAssertEqual(endpoint.urlParameters!["size"], "10")
    }
    
    func testSearchVideoEndpointWithSpace() {
        let endpoint = FeedsEndpoint.searchVideo(["first", "second withSpace", "third", "fourth"], fromIndex: 0, listSize: 10)
        let urlPath = endpoint.path
        XCTAssertEqual(urlPath, "/searchVideo/first,%20second%20withSpace,%20third,%20fourth")
        XCTAssertEqual(endpoint.urlParameters!["size"], "10")
    }
    
    func testSearchVideoMaxSizeEndpoint() {
        let endpoint = FeedsEndpoint.searchVideo(["first", "second", "third", "fourth"], fromIndex: 0, listSize: 40)
        let urlPath = endpoint.path
        XCTAssertEqual(urlPath, "/searchVideo/first,%20second,%20third,%20fourth")
        XCTAssertEqual(endpoint.urlParameters!["size"], "20")
    }
    
    func testSearchVideoEndPointMalformed() {
        // This fails because the hostDomain & hierarchy has a space and a valid url can't be constructed
        ArcXPContentManager.setUp(configuration: ArcXPContentConfig(organizationName: mockOrgName,
                                                           serverEnvironment: mockServerEnv,
                                                           site: mockSite,
                                                           hostDomain: "arc sales-arcsales-sandbox.web.arc-cdn.net"))
        client.mock.useMocks = false
        let apiExpectation = expectation(description: "Endpoint malformed")
        client.searchVideos(by: ["test"]) { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error as? NetworkError)
                let urlRequestError = error as! NetworkError
                XCTAssertEqual(urlRequestError.errorDescription, NetworkError.URLRequestError(reason: .endpointMalformed).errorDescription)
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    override func tearDown() {
        // Reset back to its defaults
        ArcXPContentManager.setUp(configuration: ArcXPContentConfig(organizationName: mockOrgName,
                                                           serverEnvironment: mockServerEnv,
                                                           site: mockSite,
                                                           hostDomain: "https://arcsales-arcsales-sandbox.web.arc-cdn.net"))
    }
}
