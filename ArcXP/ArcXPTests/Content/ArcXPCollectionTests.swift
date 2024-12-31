//
//  ArcXPCollectionTests.swift
//  ArcXPTests
//
//  Created by Mahesh Venkateswarlu on 3/21/22.
//  Copyright © 2022 Arc XP. All rights reserved.
//
// swiftlint:disable force_cast type_body_length
import XCTest
@testable import ArcXP

class ArcXPCollectionTests: BaseNetworkTests {

    let client = ArcXPContentManager.client
    var cacheManager = ContentCacheManager<ContentListResponse>()
    let cacheKey = ContentListResponse.cacheKey + ".test"
    

    func testCollectionShouldIgnoreCacheTrue() throws {
        client.mock.mockType = .success
        let apiExpectation = expectation(description: "Get collection")
        let collectionEndpoint = FeedsEndpoint.collection("test", index: 0, size: 2)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: collectionEndpoint.url)

        client.getCollection(alias: "test", shouldIgnoreCache: true) { result in
            switch result {
            case .success(let stories):
                // Ensure ANSModels have expected parameters
                XCTAssertNotNil(stories.first?.taxonomy)
                XCTAssertNotNil(stories.first?.identifier)
                XCTAssertNotNil(stories.first?.canonicalUrl)

                XCTAssertNotNil(stories.last?.promoItems)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testVideoCollectionShouldIgnoreCacheTrue() throws {
        client.mock.mockType = .success
        let apiExpectation = expectation(description: "Get collection")
        let collectionEndpoint = FeedsEndpoint.collection("video", index: 0, size: 2)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: collectionEndpoint.url)

        client.getCollection(alias: "video", shouldIgnoreCache: true) { result in
            switch result {
            case .success(let stories):
                XCTAssertEqual(stories.count, 2)
                do {
                    let videoStory = try XCTUnwrap(stories.first)
                    XCTAssertEqual(videoStory.type, ArcXPContentType.video)
                    // Ensure ANSModels have expected parameters
                    XCTAssertNotNil(videoStory.taxonomy)
                    XCTAssertNotNil(videoStory.identifier)
                    XCTAssertNotNil(videoStory.canonicalUrl)
                    XCTAssertNotNil(videoStory.promoItems)
                    XCTAssertNotNil(videoStory.thumbnailImageUrl)
                }
                catch {
                    XCTFail(error.localizedDescription)
                }
                
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testCollectionWithNoCacheLoaded() throws {
        client.mock.mockType = .success
        let apiExpectation = expectation(description: "Get collection")
        let collectionEndpoint = FeedsEndpoint.collection("test", index: 0, size: 2)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: collectionEndpoint.url)

        cacheManager = ContentCacheManager<ContentListResponse>()
        cacheManager.removeFromCache(cacheKey: cacheKey)
        
        client.getCollection(alias: "test") { result in
            switch result {
            case .success(let stories):
                XCTAssertFalse(stories.isEmpty)
                XCTAssertNotNil(stories.first?.taxonomy)
                XCTAssertNotNil(stories.first?.identifier)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            apiExpectation.fulfill()
            
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testCollectionPaginatedIndex0Size2() throws {

        client.mock.mockType = .success
        let collectionEndpoint = FeedsEndpoint.collection("test", index: 0, size: 2)
        
        let collectionData = try? Data(contentsOf: collectionEndpoint.url!, options: Data.ReadingOptions.uncached)
        let collectionResults = try? JSONDecoder().decode(ContentListResponse.self, from: collectionData!)
        cacheManager = ContentCacheManager<ContentListResponse>()
        cacheManager.saveContentToCache(collectionResults!.contentList, key: cacheKey)
        sleep(1)    // sleep for a moment to save cache
        let apiExpectation = expectation(description: "Get collection")
        client.getCollection(alias: "test", index: 0, size: 2) { result in
            switch result {
            case .success(let stories):
                XCTAssertEqual(stories.count, 2)
                XCTAssertNotNil(stories.first?.taxonomy)
                XCTAssertNotNil(stories.first?.identifier)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            self.cacheManager.removeFromCache(cacheKey: self.cacheKey)
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testCollectionPaginatedIndex2Size2() throws {
        // Existing cache for Page 1 - 2 elements
        // Cache after pagination request for page 2 - 4 elements
        client.mock.mockType = .success
        let collectionEndpointPage1 = FeedsEndpoint.collection("test", index: 0, size: 2)
        
        let collectionData = try? Data(contentsOf: collectionEndpointPage1.url!, options: Data.ReadingOptions.uncached)
        let collectionResults = try? JSONDecoder().decode(ContentListResponse.self, from: collectionData!)
        cacheManager = ContentCacheManager<ContentListResponse>()
        cacheManager.saveContentToCache(collectionResults!.contentList, key: cacheKey)
        sleep(1)    // sleep for a moment to save cache
        
        let collectionEndpointPage2 = FeedsEndpoint.collection("test", index: 2, size: 2)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: collectionEndpointPage2.url)
        
        let apiExpectation = expectation(description: "Get collection")
        client.getCollection(alias: "test", index: 2, size: 2) { result in
            switch result {
            case .success(let stories):
                XCTAssertEqual(stories.count, 2)
                XCTAssertNotNil(stories.first?.taxonomy)
                XCTAssertNotNil(stories.first?.identifier)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            self.cacheManager.removeFromCache(cacheKey: self.cacheKey)
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testCollectionPaginatedAppendToExistingCache() throws {
        client.mock.mockType = .success
        let collectionEndpointPage1 = FeedsEndpoint.collection("test", index: 0, size: 2)

        // Load collection into cache for index 0 - 2
        let collectionData1 = try? Data(contentsOf: collectionEndpointPage1.url!, options: Data.ReadingOptions.uncached)
        let collectionResults1 = try? JSONDecoder().decode(ContentListResponse.self, from: collectionData1!)
        cacheManager = ContentCacheManager<ContentListResponse>()
        cacheManager.saveContentToCache(collectionResults1!.contentList, key: cacheKey)
        sleep(1)    // sleep for a moment to save cache
        
        // Load collection into cache for index 2 - 2
        let collectionEndpointPage2 = FeedsEndpoint.collection("test", index: 2, size: 2)
        let collectionData2 = try? Data(contentsOf: collectionEndpointPage2.url!, options: Data.ReadingOptions.uncached)
        let collectionResults2 = try? JSONDecoder().decode(ContentListResponse.self, from: collectionData2!)
        
        // save collections into cache
        client.saveCollectionsToCache(alias: "test", collectionsList: collectionResults2!.contentList, index: 2, size: 2)
        sleep(1)    // sleep for a moment to save cache
        
        // validate the total collections saved into cache
        cacheManager.fetchContentFromCache(key: self.cacheKey) { cacheResult in
            let value = cacheResult.value?.value
            XCTAssertNotNil(value)
            let cachedContent = value?.contentList
            XCTAssertEqual(cachedContent!.count, 4)
        }
    }
    
    
    func testCollectionPaginatedIndex1Size4() throws {
        // Results are fetched from cache while the index is in range.
        client.mock.mockType = .success
        let collectionEndpointPage1 = FeedsEndpoint.collection("test", index: 0, size: 2)
        let collectionEndpointPage2 = FeedsEndpoint.collection("test", index: 2, size: 2)
        
        let collectionData1 = try? Data(contentsOf: collectionEndpointPage1.url!, options: Data.ReadingOptions.uncached)
        var collectionResults1 = try? JSONDecoder().decode(ContentListResponse.self, from: collectionData1!)
        
        let collectionData2 = try? Data(contentsOf: collectionEndpointPage2.url!, options: Data.ReadingOptions.uncached)
        let collectionResults2 = try? JSONDecoder().decode(ContentListResponse.self, from: collectionData2!)
        collectionResults1?.contentList.append(contentsOf: collectionResults2!.contentList)
        
        cacheManager = ContentCacheManager<ContentListResponse>()
        cacheManager.saveContentToCache(collectionResults1!.contentList, key: cacheKey)
        sleep(1)    // sleep for a moment to save cache
        let apiExpectation = expectation(description: "Get collection")
        client.getCollection(alias: "test", index: 1, size: 5) { result in
            switch result {
            case .success(let stories):
                XCTAssertEqual(stories.count, 3)
                XCTAssertNotNil(stories.first?.taxonomy)
                XCTAssertNotNil(stories.first?.identifier)
                
                // Validate with the cache
                self.cacheManager.fetchContentFromCache(key: self.cacheKey) { cacheResult in
                    let value = cacheResult.value?.value
                    XCTAssertNotNil(value)
                    let cachedContent = value?.contentList
                    XCTAssertEqual(cachedContent!.count, 4)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            self.cacheManager.removeFromCache(cacheKey: self.cacheKey)
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testCollectionContentInErrorResponseWhileBadGateway() {
        client.mock.mockType = .success
        let collectionEndpoint = FeedsEndpoint.collection("test", index: 0, size: 2)
        let collectionData = try? Data(contentsOf: collectionEndpoint.url!, options: Data.ReadingOptions.uncached)
        let collectionResults = try? JSONDecoder().decode(ContentListResponse.self, from: collectionData!)
        cacheManager = ContentCacheManager<ContentListResponse>()
        cacheManager.saveContentToCache(collectionResults!.contentList, key: cacheKey)
        sleep(1)    // sleep for a moment to save cache
        let apiExpectation = expectation(description: "Bad Gateway")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 500, url: collectionEndpoint.url)
        // By setting TTC to 0.0, Cache will be skipped and will attempt to make a network call
        client.cacheConfiguration.cacheTimeUntilUpdate = 0.0
        client.getCollection(alias: "test") { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error as? NetworkError)
                let urlRequestError = error as! NetworkError
                switch urlRequestError {
                case .URLRequestError(reason: .serverError(let statusCode, cachedContent: let cachedContent)):
                    XCTAssertEqual(statusCode, 500)
                    XCTAssertNotNil(cachedContent as? ArcXPContentList)
                    XCTAssertEqual(urlRequestError.errorDescription, "Server has encountered an error: \n Status code = 500 ")
                default:
                    XCTFail("Should throw a fail response")
                }
                // Reset back defaults
                self.client.cacheConfiguration.cacheTimeUntilUpdate = 1.0
                self.cacheManager.removeFromCache(cacheKey: self.cacheKey)
                apiExpectation.fulfill()
            }
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testCollectionFailure() {
        client.mock.mockType = .failure
        // mock response
        let apiExpectation = expectation(description: "Collection errors out")
        let collectionEndpoint = FeedsEndpoint.collection("test", index: 0, size: 2)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 404, url: collectionEndpoint.url)

        client.getCollection(alias: "test") { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error)
                XCTAssertNotNil(error as? NetworkError)
                let urlRequestError = error as! NetworkError
                switch urlRequestError {
                case .URLRequestError(reason: .dataNotFound(let statusCode)):
                    XCTAssertEqual(statusCode, 404)
                    XCTAssertEqual(urlRequestError.errorDescription, "Can not find the requested resource: \n Status code = 404")
                default:
                    XCTFail("Should throw a fail response")
                }
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testCollectionDataNotFound() {
        client.mock.mockType = .success
        let apiExpectation = expectation(description: "Collection_Data_Not_found")
        let collectionEndpoint = FeedsEndpoint.collection("test", index: 0, size: 2)
        let collectionData = try? Data(contentsOf: collectionEndpoint.url!, options: Data.ReadingOptions.uncached)
        let collectionResults = try? JSONDecoder().decode(ContentListResponse.self, from: collectionData!)
        cacheManager = ContentCacheManager<ContentListResponse>()
        cacheManager.saveContentToCache(collectionResults!.contentList, key: cacheKey)
        cacheManager.removeFromCache(cacheKey: cacheKey)
        cacheManager.saveContentToCache(collectionResults, key: cacheKey)
        sleep(1)
        
        self.client.cacheConfiguration.cacheTimeUntilUpdate = 0.0
        MockURLProtocol.requestHandler = mockResponse(statusCode: 404, url: collectionEndpoint.url)
        client.getCollection(alias: "test") { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error as? NetworkError)
                let urlRequestError = error as! NetworkError
                switch urlRequestError {
                case .URLRequestError(reason: .dataNotFound(let statusCode)):
                    XCTAssertEqual(statusCode, 404)
                default:
                    XCTFail("Should throw a fail response")
                }
                self.client.cacheConfiguration.cacheTimeUntilUpdate = 1.0
                self.cacheManager.removeFromCache(cacheKey: self.cacheKey)
                apiExpectation.fulfill()
            }
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }

}
