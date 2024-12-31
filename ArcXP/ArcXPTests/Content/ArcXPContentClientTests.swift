//
//  ArcXPContentClientTests.swift
//  ArcXPContentTests
//
//  Created by Davis, Tyler on 1/24/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//
// swiftlint:disable force_cast
import XCTest
@testable import ArcXP

class ArcXPContentClientTests: BaseNetworkTests {

    let client = ArcXPContentManager.client
    
    func testSearchSuccess() throws {
        client.mock.mockType = .success
        let apiExpectation = expectation(description: "Search with mock")
        let searchEndpoint = FeedsEndpoint.search(["test"], fromIndex: 0, listSize: 2)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: searchEndpoint.url)

        client.search(by: ["test"], size: 2) { result in
            switch result {
            case .success(let stories):
                XCTAssertEqual(stories.count, 2)

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
    
    func testSearchAwaitSuccess() async {
        client.mock.mockType = .success
        let searchEndpoint = FeedsEndpoint.search(["test"], fromIndex: 0, listSize: 2)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: searchEndpoint.url)
        
        let stories = try? await client.search(by: ["test"], size: 2)
        XCTAssertEqual(stories?.count, 2)
    }
    
    func testSearchWithSpecialCharacterSuccess() throws {
        client.mock.mockType = .success
        let apiExpectation = expectation(description: "Search with mock")
        let searchEndpoint = FeedsEndpoint.search(["test"], fromIndex: 0, listSize: 2)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: searchEndpoint.url)

        client.search(by: ["@t#e$s%t^-"]) { result in
            switch result {
            case .success(let stories):
                XCTAssertEqual(stories.count, 2)

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

    func testSearchAwaitSuccess() throws {
        client.mock.mockType = .success
        let apiExpectation = expectation(description: "Search with mock")
        let searchEndpoint = FeedsEndpoint.search(["test"], fromIndex: 0, listSize: 2)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: searchEndpoint.url)

        Task.init {
            let searchResults = try? await client.search(by: ["test"], index: 0, size: 2)
            XCTAssertNotNil(searchResults)
            XCTAssertEqual(searchResults?.count, 2)
            apiExpectation.fulfill()
        }

        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }

    func testSearchVideoSuccess() throws {
        client.mock.mockType = .success
        let apiExpectation = expectation(description: "Search with mock")
        let searchEndpoint = FeedsEndpoint.searchVideo(["test"], fromIndex: 0, listSize: 2)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: searchEndpoint.url)

        client.searchVideos(by: ["test"], size: 2) { result in
            switch result {
            case .success(let stories):
                XCTAssertEqual(stories.count, 2)

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
    
    func testSearchFailure() throws {
        client.mock.mockType = .failure
        let expectation = expectation(description: "Failed to retrieve search content.")
        let searchEndpoint = FeedsEndpoint.search(["test"], fromIndex: 0, listSize: 2)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 400, url: searchEndpoint.url)

        client.search(by: ["test"]) { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error)
                XCTAssertNotNil(error as? NetworkError)
                let urlRequestError = error as! NetworkError
                switch urlRequestError {
                case .URLRequestError(reason: .badRequest(let statusCode)):
                    XCTAssertEqual(statusCode, 400)
                    XCTAssertEqual(urlRequestError.errorDescription, "Bad HTTP request:\n Status code = 400")
                default:
                    XCTFail("Should throw a fail response")
                }
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: expectationTimeOut)
    }

    func testSearchVideoFailure() throws {
        client.mock.mockType = .failure
        let expectation = expectation(description: "Failed to retrieve search content.")
        let searchEndpoint = FeedsEndpoint.searchVideo(["test"], fromIndex: 0, listSize: 2)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 400, url: searchEndpoint.url)

        client.searchVideos(by: ["test"]) { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error)
                XCTAssertNotNil(error as? NetworkError)
                let urlRequestError = error as! NetworkError
                switch urlRequestError {
                case .URLRequestError(reason: .badRequest(let statusCode)):
                    XCTAssertEqual(statusCode, 400)
                    XCTAssertEqual(urlRequestError.errorDescription, "Bad HTTP request:\n Status code = 400")
                default:
                    XCTFail("Should throw a fail response")
                }
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: expectationTimeOut)
    }
    
    func testSectionListSuccessShouldIgnoreCacheTrue() throws {
        client.mock.mockType = .success
        let expectation = expectation(description: "Successfully retrieved the section list.")
        let navigationEndpoint = FeedsEndpoint.sectionList("mobile-nav")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: navigationEndpoint.url)
        
        client.getSectionList(siteHierarchy: "mobile-nav", shouldIgnoreCache: true) { result in
            switch result {
            case .success(let sectionListElements):
                XCTAssertNotNil(sectionListElements)
                XCTAssertEqual(sectionListElements.count, 5)
                XCTAssertEqual(sectionListElements.first?.name, "Mobile - Top Stories")
                XCTAssertEqual(sectionListElements.first?.navigation?.title, "Top Stories")
                XCTAssertEqual(sectionListElements.first?.title, "Top Stories")
                XCTAssertEqual(sectionListElements[1].title, "Mobile - Politics")
                XCTAssertEqual(sectionListElements.first?.website, "arcsales")
            case .failure(let error):
                XCTFail("Failed with the following error: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: expectationTimeOut)
    }
    
    func testSectionListWithNoCacheLoaded() throws {
        client.mock.mockType = .success
        let cacheManager = ContentCacheManager<SectionListResponse>()
        cacheManager.removeFromCache(cacheKey: SectionListResponse.cacheKey)
        sleep(2)
        let expectation = expectation(description: "Successfully retrieved the section list.")
        let navigationEndpoint = FeedsEndpoint.sectionList("mobile-nav")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: navigationEndpoint.url)
        
        client.getSectionList(siteHierarchy: "mobile-nav") { result in
            switch result {
            case .success(let sectionListElements):
                XCTAssertNotNil(sectionListElements)
                XCTAssertEqual(sectionListElements.count, 5)
                XCTAssertEqual(sectionListElements.first?.name, "Mobile - Top Stories")
                XCTAssertEqual(sectionListElements.first?.navigation?.title, "Top Stories")
                XCTAssertEqual(sectionListElements.first?.website, "arcsales")
            case .failure(let error):
                XCTFail("Failed with the following error: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: expectationTimeOut)
    }
    
    func testSectionListWithCacheLoaded() throws {
        client.mock.mockType = .success
        let expectation = expectation(description: "Successfully retrieved the section list.")
        let navigationEndpoint = FeedsEndpoint.sectionList("mobile-nav")
        let cacheManager = ContentCacheManager<SectionListResponse>()
        let sectionListData = try? Data(contentsOf: navigationEndpoint.url!, options: Data.ReadingOptions.uncached)
        let sectionListResults = try? JSONDecoder().decode(SectionListResponse.self, from: sectionListData!)
        cacheManager.saveContentToCache(sectionListResults?.sectionList, key: SectionListResponse.cacheKey)
        sleep(2)    // sleep for a moment to save cache
        
        client.getSectionList(siteHierarchy: "mobile-nav") { result in
            switch result {
            case .success(let sectionListElements):
                XCTAssertNotNil(sectionListElements)
                XCTAssertEqual(sectionListElements.count, 5)
                XCTAssertEqual(sectionListElements.first?.name, "Mobile - Top Stories")
                XCTAssertEqual(sectionListElements.first?.website, "arcsales")
            case .failure(let error):
                XCTFail("Failed with the following error: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: expectationTimeOut)
    }
    
    func testSectionListCacheInErrorResponseWhileBadGateway() throws {
        client.mock.mockType = .success
        let navigationEndpoint = FeedsEndpoint.sectionList("mobile-nav")
        let cacheManager = ContentCacheManager<SectionListResponse>()
        let sectionListData = try? Data(contentsOf: navigationEndpoint.url!, options: Data.ReadingOptions.uncached)
        let sectionListResults = try? JSONDecoder().decode(SectionListResponse.self, from: sectionListData!)
        cacheManager.saveContentToCache(sectionListResults?.sectionList, key: SectionListResponse.cacheKey)
        sleep(2)    // sleep for a moment to save cache
        
        let apiExpectation = expectation(description: "Bad Gateway")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 500, url: navigationEndpoint.url)
        // By setting TTC to 0.0, Cache will be skipped and will attempt to make a network call
        client.cacheConfiguration.cacheTimeUntilUpdate = 0.0
        client.getSectionList(siteHierarchy: "mobile-nav") { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error as? NetworkError)
                let urlRequestError = error as! NetworkError
                switch urlRequestError {
                case .URLRequestError(reason: .serverError(let statusCode, cachedContent: let cachedContent)):
                    XCTAssertEqual(statusCode, 500)
                    XCTAssertNotNil(cachedContent as? SectionListResponse)
                    XCTAssertEqual(urlRequestError.errorDescription, "Server has encountered an error: \n Status code = 500 ")
                default:
                    XCTFail("Should throw a fail response")
                }
                // Reset back defaults
                self.client.cacheConfiguration.cacheTimeUntilUpdate = 1.0
                apiExpectation.fulfill()
            }
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testSectionListFailure() throws {
        client.mock.mockType = .failure
        let expectation = expectation(description: "Failed to retrieve the section list.")
        let navigationEndpoint = FeedsEndpoint.sectionList("mobile-nav")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 400, url: navigationEndpoint.url)

        client.getSectionList(siteHierarchy: "mobile-nav", shouldIgnoreCache: true) { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error)
                XCTAssertNotNil(error as? NetworkError)
                let urlRequestError = error as! NetworkError
                switch urlRequestError {
                case .URLRequestError(reason: .badRequest(let statusCode)):
                    XCTAssertEqual(statusCode, 400)
                    XCTAssertEqual(urlRequestError.errorDescription, "Bad HTTP request:\n Status code = 400")
                default:
                    XCTFail("Should throw a fail response")
                }
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: expectationTimeOut)
    }
    
    func testSectionDataNotFound() {
        client.mock.mockType = .success
        let navigationEndpoint = FeedsEndpoint.sectionList("mobile-nav")
        let cacheManager = ContentCacheManager<SectionListResponse>()
        let sectionListData = try? Data(contentsOf: navigationEndpoint.url!, options: Data.ReadingOptions.uncached)
        let sectionListResults = try? JSONDecoder().decode(SectionListResponse.self, from: sectionListData!)
        cacheManager.saveContentToCache(sectionListResults?.sectionList, key: SectionListResponse.cacheKey)
        sleep(2)    // sleep for a moment to save cache
        
        self.client.cacheConfiguration.cacheTimeUntilUpdate = 0.0
        MockURLProtocol.requestHandler = mockResponse(statusCode: 404, url: navigationEndpoint.url)
        let apiExpectation = expectation(description: "Failed to retrieve the section list.")
        client.getSectionList(siteHierarchy: "mobile-nav", shouldIgnoreCache: true) { result in
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
                apiExpectation.fulfill()
            }
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testClearAllCache() {
        client.mock.mockType = .success
        let sectionListExpectation = expectation(description: "Clear sectionList cache")
        let collectionListExpectation = expectation(description: "Clear collection list cache")

        // Save SectionList into cache
        let navigationEndpoint = FeedsEndpoint.sectionList("mobile-nav")
        let sectionListData = try? Data(contentsOf: navigationEndpoint.url!, options: Data.ReadingOptions.uncached)
        let sectionListResults = try? JSONDecoder().decode(SectionListResponse.self, from: sectionListData!)
        let sectionListCacheManager = ContentCacheManager<SectionListResponse>()
        sectionListCacheManager.saveContentToCache(sectionListResults?.sectionList, key: SectionListResponse.cacheKey)
        sleep(1)    // sleep for a moment to save cache

        // Save collections into cache
        let collectionCacheKey = ContentListResponse.cacheKey + ".test"
        let collectionEndpoint = FeedsEndpoint.collection("test", index: 0, size: 2)
        let collectionData = try? Data(contentsOf: collectionEndpoint.url!, options: Data.ReadingOptions.uncached)
        let collectionResults = try? JSONDecoder().decode(ContentListResponse.self, from: collectionData!)
        let collectionCacheManager = ContentCacheManager<ContentListResponse>()
        collectionCacheManager.saveContentToCache(collectionResults!.contentList, key: collectionCacheKey)
        sleep(1)    // sleep for a moment to save cache

        client.clearAllCache { result in
            switch result {
            case .success:

                sectionListCacheManager.fetchContentFromCache(key: SectionListResponse.cacheKey) { result in
                    switch result {
                    case .failure(_):
                        XCTAssertTrue(true)
                    case .success(_):
                        XCTFail("Expected to remove the section list cache by key")
                    }
                    sectionListExpectation.fulfill()
                }
                
                collectionCacheManager.fetchContentFromCache(key: collectionCacheKey) { result in
                    switch result {
                    case .failure(_):
                        XCTAssertTrue(true)
                    case .success(_):
                        XCTFail("Expected to remove the collection cache by key")
                    }
                    collectionListExpectation.fulfill()
                }

            case .failure(let error):
                XCTAssertFalse(false, "Error while clearing cache: \(error)")
            }
        }

        wait(for: [sectionListExpectation, collectionListExpectation], timeout: expectationTimeOut)
    }
    
    func testClearCacheByKey() {
        client.mock.mockType = .success
        client.clearAllCache()

        let sectionListExpectation = expectation(description: "Clear sectionList cache")
        let collectionListExpectation = expectation(description: "Clear collection list cache")

        // Save SectionList into cache
        let navigationEndpoint = FeedsEndpoint.sectionList("mobile-nav")
        let sectionListData = try? Data(contentsOf: navigationEndpoint.url!, options: Data.ReadingOptions.uncached)
        let sectionListResults = try? JSONDecoder().decode(SectionListResponse.self, from: sectionListData!)
        let sectionListCacheManager = ContentCacheManager<SectionListResponse>()
        sectionListCacheManager.saveContentToCache(sectionListResults?.sectionList, key: SectionListResponse.cacheKey)
        sleep(1)    // sleep for a moment to save cache

        // Save collections into cache
        let collectionCacheKey = ContentListResponse.cacheKey + ".test"
        let collectionEndpoint = FeedsEndpoint.collection("test", index: 0, size: 2)
        let collectionData = try? Data(contentsOf: collectionEndpoint.url!, options: Data.ReadingOptions.uncached)
        let collectionResults = try? JSONDecoder().decode(ContentListResponse.self, from: collectionData!)
        let collectionCacheManager = ContentCacheManager<ContentListResponse>()
        collectionCacheManager.saveContentToCache(collectionResults!.contentList, key: collectionCacheKey)
        sleep(1)    // sleep for a moment to save cache

        client.clearCacheForKey(requestType: ArcXPContentClient.RequestType.sectionList)
        sleep(1)

        client.clearCacheForKey(requestType: ArcXPContentClient.RequestType.collection, alias: "test")
        sleep(1)

        sectionListCacheManager.fetchContentFromCache(key: SectionListResponse.cacheKey) { result in
            switch result {
            case .failure(_):
                XCTAssertTrue(true)
            case .success(_):
                XCTFail("Expected to remove the sectionList cache by key")
            }
            sectionListExpectation.fulfill()
        }

        collectionCacheManager.fetchContentFromCache(key: collectionCacheKey) { result in
            switch result {
            case .failure(_):
                XCTAssertTrue(true)
            case .success(_):
                XCTFail("Expected to remove the collection cache by key")
            }
            collectionListExpectation.fulfill()
        }

        wait(for: [sectionListExpectation, collectionListExpectation], timeout: expectationTimeOut)
    }
}
