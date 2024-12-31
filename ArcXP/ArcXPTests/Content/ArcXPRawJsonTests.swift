//
//  ArcXPRawJsonTests.swift
//  ArcXP
//
//  Created by Mahesh Venkateswarlu on 2/28/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import Foundation

import XCTest
@testable import ArcXP

class ArcXPRawJsonTests: BaseNetworkTests {
    
    let client = ArcXPContentManager.client
    var cacheManager = ContentCacheManager<ContentListResponse>()
    let cacheKey = ContentListResponse.cacheKey + ".test"
    
    override func tearDown() {
        cacheManager = ContentCacheManager<ContentListResponse>()
        cacheManager.clearAllCache()
        super.tearDown()
    }

    func testAwaitRawJsonSectionListIgnoreCache() async throws {
        // Mocking the cache and the response
        client.mock.mockType = .success
        let navigationEndpoint = FeedsEndpoint.sectionList("mobile-nav")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: navigationEndpoint.url)

        // Asserting the calls
        let rawResponse = try await client.getRawJsonContent(requestType: .sectionList, aliasId: "mobile-nav", shouldIgnoreCache: true)
        let sectionListString = try XCTUnwrap(rawResponse)

        let data = sectionListString.data(using: .utf8)
        let sectionListData = try XCTUnwrap(data)

        let parsedContent = try JSONSerialization.jsonObject(with: sectionListData, options: .allowFragments) as? [Any]
        let sectionListElements = try XCTUnwrap(parsedContent)

        XCTAssertEqual(sectionListElements.count, 5)
    }
    
    func testAwaitRawJsonCollectionWithCache() async throws {
        // Mocking the cache and the response
        client.mock.mockType = .success
        let collectionEndpoint = FeedsEndpoint.collection("test", index: 0, size: 2)
        let cachedData = try? Data(contentsOf: collectionEndpoint.url!, options: Data.ReadingOptions.uncached)
        let collectionResults = try? JSONDecoder().decode(ContentListResponse.self, from: cachedData!)
        cacheManager = ContentCacheManager<ContentListResponse>()
        cacheManager.saveContentToCache(collectionResults!.contentList, key: cacheKey)
        sleep(1)    // sleep for a moment to save cache

        // Asserting the calls
        let rawResponse = try await client.getRawJsonContent(requestType: .collection, aliasId: "test")
        let collectionString = try XCTUnwrap(rawResponse)

        let data = collectionString.data(using: .utf8)
        let collectionData = try XCTUnwrap(data)

        let parsedContent = try JSONSerialization.jsonObject(with: collectionData, options: .allowFragments) as? [Any]
        let collectionList = try XCTUnwrap(parsedContent)

        XCTAssertEqual(collectionList.count, 2)
    }
    
    func testAwaitRawJsonSectionListWithCache() async throws {
        // Mocking the cache and the response
        client.mock.mockType = .success
        let navigationEndpoint = FeedsEndpoint.sectionList("mobile-nav")
        let cacheManager = ContentCacheManager<SectionListResponse>()
        let cachedData = try? Data(contentsOf: navigationEndpoint.url!, options: Data.ReadingOptions.uncached)
        let sectionListResults = try? JSONDecoder().decode(SectionListResponse.self, from: cachedData!)
        cacheManager.saveContentToCache(sectionListResults?.sectionList, key: SectionListResponse.cacheKey)
        sleep(1)

        // Asserting the calls
        let rawResponse = try await client.getRawJsonContent(requestType: .sectionList, aliasId: "mobile-nav")
        let sectionListString = try XCTUnwrap(rawResponse)

        let data = sectionListString.data(using: .utf8)
        let sectionListData = try XCTUnwrap(data)

        let parsedContent = try JSONSerialization.jsonObject(with: sectionListData, options: .allowFragments) as? [Any]
        let sectionListElements = try XCTUnwrap(parsedContent)

        XCTAssertEqual(sectionListElements.count, 5)
    }
    
    func testAwaitRawJsonStoryWithCache() async throws {
        // Mocking the cache and the response
        client.mock.mockType = .success
        let cacheKey = ArcXPContent.cacheKey + ".ID"
        let storyEndpoint = FeedsEndpoint.contentById("Story")
        let cachedData = try? Data(contentsOf: storyEndpoint.url!, options: Data.ReadingOptions.uncached)
        let storyContent = try? JSONDecoder().decode(ArcXPContent.self, from: cachedData!)
        cacheManager.saveContentToCache(storyContent, key: cacheKey)
        sleep(1)

        // Asserting the calls
        let rawResponse = try await client.getRawJsonContent(requestType: .content, aliasId: "ID")
        let storyRawString = try XCTUnwrap(rawResponse)

        let data = storyRawString.data(using: .utf8)
        let storyRawData = try XCTUnwrap(data)

        let parsedContent = try JSONSerialization.jsonObject(with: storyRawData, options: .allowFragments) as? [String: Any]
        let story = try XCTUnwrap(parsedContent)

        XCTAssertEqual(story["type"] as! String, "story")
        XCTAssertEqual(story["_id"] as! String, "TLZJTWT7JBCXXIVQ25OUBSJOJM")
    }
    
    func testAwaitRawJsonStoryWithEncodingException() async throws {
        // Mocking the cache and the response
        client.mock.mockType = .success
        let storyEndpoint = FeedsEndpoint.contentById("Exception")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: storyEndpoint.url)

        // Asserting the calls
        let rawResponse = try await client.getRawJsonContent(requestType: .content, aliasId: "Exception")
        let storyRawString = try XCTUnwrap(rawResponse)

        let data = storyRawString.data(using: .utf8)
        let storyRawData = try XCTUnwrap(data)

        let parsedContent = try JSONSerialization.jsonObject(with: storyRawData, options: .allowFragments) as? [String: Any]
        let story = try XCTUnwrap(parsedContent)

        XCTAssertEqual(story["type"] as! String, "story")
        XCTAssertEqual(story["_id"] as! Int, 123)
    }
    
    func testAwaitRawJsonSectionListWithEncodingException() async throws {
        // Mocking the cache and the response
        client.mock.mockType = .success
        let navigationEndpoint = FeedsEndpoint.sectionList("Exception")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: navigationEndpoint.url)

        // Asserting the calls
        let rawResponse = try await client.getRawJsonContent(requestType: .sectionList, aliasId: "Exception")
        let sectionListString = try XCTUnwrap(rawResponse)

        let data = sectionListString.data(using: .utf8)
        let sectionListData = try XCTUnwrap(data)

        let parsedContent = try JSONSerialization.jsonObject(with: sectionListData, options: .allowFragments) as? [Any]
        let sectionListElements = try XCTUnwrap(parsedContent)

        XCTAssertEqual(sectionListElements.count, 1)
    }
    
    func testAwaitRawJsonCollectionWithEncodingException() async throws {
        // Mocking the cache and the response
        client.mock.mockType = .success
        let collectionEndpoint = FeedsEndpoint.collection("exception", index: 0, size: 2)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: collectionEndpoint.url)

        // Asserting the calls
        let rawResponse = try await client.getRawJsonContent(requestType: .collection, aliasId: "exception")
        let collectionListString = try XCTUnwrap(rawResponse)

        let data = collectionListString.data(using: .utf8)
        let collectionListData = try XCTUnwrap(data)

        let parsedContent = try JSONSerialization.jsonObject(with: collectionListData, options: .allowFragments) as? [Any]
        let collectionElements = try XCTUnwrap(parsedContent)

        XCTAssertEqual(collectionElements.count, 1)
    }
    
    func testAwaitRawJsonStoryWithDataNotFound() async throws {
        client.mock.mockType = .failure

        let storyEndpoint = FeedsEndpoint.contentById("Story")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 404, url: storyEndpoint.url)
        do {
            _ = try await client.getRawJsonContent(requestType: .content, aliasId: "Story")
        } catch {
            let networkError = error as? NetworkError
            let urlRequestError = try XCTUnwrap(networkError)
            switch urlRequestError {
            case .URLRequestError(reason: .dataNotFound(let statusCode)):
                XCTAssertEqual(statusCode, 404)
            default:
                XCTFail("Should throw a fail response")
            }
        }
    }
    
}
