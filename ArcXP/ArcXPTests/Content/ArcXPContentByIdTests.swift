//
//  ArcXPStoryContentTests.swift
//  ArcXPContentTests
//
//  Created by Mahesh Venkateswarlu on 1/25/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//
// swiftlint:disable force_cast
import XCTest
@testable import ArcXP

class ArcXPContentByIdTests: BaseNetworkTests {
    
    let client = ArcXPContentManager.client

    var cacheManager = ContentCacheManager<ArcXPContent>()
    
    func testStoryContentSuccessPathsIgnoreCacheTrue() {
        client.mock.mockType = .success
        let apiExpectation = expectation(description: "Get story")
        let storyEndpoint = FeedsEndpoint.contentById("Story")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: storyEndpoint.url)

        client.getStoryContent(identifier: "ID",
                               shouldIgnoreCache: true) { result in
            if case let .success(storyContent) = result {
                XCTAssertNotNil(storyContent)
                XCTAssertNotNil(storyContent.contentElements)
                XCTAssertEqual(storyContent.type, .story)
                let timeZone = TimeZone.current.abbreviation()
                XCTAssertEqual(storyContent.formattedPublishedDate, "March 30, 2022 at 7:24 PM \(timeZone!)")
                XCTAssertEqual(storyContent.authorNames, ["Test user1", "Test User2"])
                XCTAssertNotNil(storyContent.thumbnailImageUrl)
                XCTAssertNotNil(storyContent.imageUrl)
                XCTAssertNotNil(storyContent.contentElements![3] as! VideoContentElement)
                let videoElement = storyContent.contentElements![3] as! VideoContentElement
                XCTAssertNotNil(videoElement.promoImage?.resizedImageUrl)
                apiExpectation.fulfill()
            }
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testStoryWithGalleryContentIgnoreCache() {
        client.mock.mockType = .success
        let apiExpectation = expectation(description: "Get story")
        let storyEndpoint = FeedsEndpoint.contentById("StoryWithGallery")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: storyEndpoint.url)

        client.getStoryContent(identifier: "ID",
                               shouldIgnoreCache: true) { result in
            if case let .success(storyContent) = result {
                XCTAssertNotNil(storyContent)
                XCTAssertNotNil(storyContent.contentElements)
                XCTAssertEqual(storyContent.contentElements![0].type, "gallery")
                XCTAssertEqual(storyContent.type, .story)
                let galleryContentElement = storyContent.contentElements?.first! as! GalleryContentElement
                XCTAssertNotNil(galleryContentElement.resizedThumbnailImageUrl)
                XCTAssertNotNil(galleryContentElement.resizedImageUrl)
                XCTAssertNotNil((galleryContentElement.promoItems?.content as? ImageContentElement)?.resizedThumbnailImageUrl)
                apiExpectation.fulfill()
            }
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testStorySuccessNoCacheLoaded() {
        client.mock.mockType = .success
        let storyEndpoint = FeedsEndpoint.contentById("Story")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: storyEndpoint.url)
        
        let cacheKey = ArcXPContent.cacheKey + ".ID"
        cacheManager.removeFromCache(cacheKey: cacheKey)
        sleep(2)
        
        let apiExpectation = expectation(description: "Get story")
        client.getStoryContent(identifier: "ID",
                               shouldIgnoreCache: false) { result in
            if case let .success(storyContent) = result {
                XCTAssertNotNil(storyContent)
                XCTAssertEqual(storyContent.type, .story)
                
                // Sleep for a moment to let the caching operations completed
                // Assert for cache items
                sleep(2)
                self.cacheManager = ContentCacheManager<ArcXPContent>()
                self.cacheManager.fetchContentFromCache(key: cacheKey) { cacheResult in
                    let value = cacheResult.value?.value
                    XCTAssertNotNil(value)
                    let cachedContent = value
                    XCTAssertEqual(cachedContent?.type, .story)
                    apiExpectation.fulfill()
                }
            }
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testStorySuccessShouldIgnoreCacheFalseWithCacheLoaded() {
        client.mock.mockType = .success
        let cacheKey = ArcXPContent.cacheKey + ".ID"
        let storyEndpoint = FeedsEndpoint.contentById("Story")
        let storyData = try? Data(contentsOf: storyEndpoint.url!, options: Data.ReadingOptions.uncached)
        let storyContent = try? JSONDecoder().decode(ArcXPContent.self, from: storyData!)
        cacheManager.saveContentToCache(storyContent, key: cacheKey)
        sleep(1)
        
        let apiExpectation = expectation(description: "Get story")
        client.getStoryContent(identifier: "ID",
                               shouldIgnoreCache: false) { result in
            if case let .success(storyContent) = result {
                XCTAssertNotNil(storyContent)
                XCTAssertEqual(storyContent.type, .story)
                apiExpectation.fulfill()
            }
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testStoryWithCacheExpired() {
        client.mock.mockType = .success
        let cacheKey = ArcXPContent.cacheKey + ".ID"
        let storyEndpoint = FeedsEndpoint.contentById("Story")
        let storyData = try? Data(contentsOf: storyEndpoint.url!, options: Data.ReadingOptions.uncached)
        let storyContent = try? JSONDecoder().decode(ArcXPContent.self, from: storyData!)
        cacheManager.saveContentToCache(storyContent, key: cacheKey)
        sleep(1)
        
        let apiExpectation = expectation(description: "Get story")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: storyEndpoint.url)
        client.cacheConfiguration.cacheTimeUntilUpdate = 0.0
        client.getStoryContent(identifier: "ID",
                               shouldIgnoreCache: false) { result in
            if case let .success(storyContent) = result {
                XCTAssertNotNil(storyContent)
                XCTAssertEqual(storyContent.type, .story)
                apiExpectation.fulfill()
            }
            self.client.cacheConfiguration.cacheTimeUntilUpdate = 1.0
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testStoryContentInErrorResponseWhileBadGateway() {
        client.mock.mockType = .success
        let cacheKey = ArcXPContent.cacheKey + ".ID"
        cacheManager.removeFromCache(cacheKey: cacheKey)
        let storyEndpoint = FeedsEndpoint.contentById("Story")
        let storyData = try? Data(contentsOf: storyEndpoint.url!, options: Data.ReadingOptions.uncached)
        let storyContent = try? JSONDecoder().decode(ArcXPContent.self, from: storyData!)
        cacheManager.saveContentToCache(storyContent, key: cacheKey)
        sleep(2)
        
        let apiExpectation = expectation(description: "Bad Gateway")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 500, url: storyEndpoint.url)
        // By setting TTC to 0.0, Cache will be skipped and will attempt to make a network call
        client.cacheConfiguration.cacheTimeUntilUpdate = 0.0
        client.getStoryContent(identifier: "ID") { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error as? NetworkError)
                let urlRequestError = error as! NetworkError
                switch urlRequestError {
                case .URLRequestError(reason: .serverError(let statusCode, cachedContent: let cachedContent)):
                    XCTAssertEqual(statusCode, 500)
                    XCTAssertNotNil(cachedContent)
                    XCTAssertEqual(urlRequestError.errorDescription, "Server has encountered an error: \n Status code = 500 ")
                default:
                    XCTFail("Should throw a fail response")
                }
                // Reset back to whatever it was
                self.client.cacheConfiguration.cacheTimeUntilUpdate = 1.0
                apiExpectation.fulfill()
            }
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testStoryContentEndPointDataNotFound() {
        client.mock.mockType = .success
        let apiExpectation = expectation(description: "Get story")
        let storyEndpoint = FeedsEndpoint.contentById("Story")
        let storyData = try? Data(contentsOf: storyEndpoint.url!, options: Data.ReadingOptions.uncached)
        let storyContent = try? JSONDecoder().decode(ArcXPContent.self, from: storyData!)
        let cacheKey = ArcXPContent.cacheKey + ".ID"
        cacheManager.removeFromCache(cacheKey: cacheKey)
        cacheManager.saveContentToCache(storyContent, key: cacheKey)
        sleep(1)
        
        client.mock.mockType = .failure
        self.client.cacheConfiguration.cacheTimeUntilUpdate = 0.0
        MockURLProtocol.requestHandler = mockResponse(statusCode: 404, url: storyEndpoint.url)
        client.getStoryContent(identifier: "Story") { result in
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
    
    func testStoryContentFailureUnauthorized() {
        client.mock.mockType = .failure
        let apiExpectation = expectation(description: "Unauthorized")
        let storyEndpoint = FeedsEndpoint.contentById("Story")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 401, url: storyEndpoint.url)
        client.getStoryContent(identifier: "ID", shouldIgnoreCache: true) { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error as? NetworkError)
                let urlRequestError = error as! NetworkError
                switch urlRequestError {
                case .URLRequestError(reason: .unauthorizedError(let statusCode)):
                    XCTAssertEqual(statusCode, 401)
                    XCTAssertEqual(urlRequestError.errorDescription, "Access denied:\n Status code = 401")
                default:
                    XCTFail("Should throw a fail response")
                }
                apiExpectation.fulfill()
            }
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testGalleryContentSuccessPaths() {
        client.mock.mockType = .success
        let apiExpectation = expectation(description: "Get gallery content")
        let galleryEndpoint = FeedsEndpoint.contentById("Gallery")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: galleryEndpoint.url)
        
        client.getGalleryContent(identifier: "ID", shouldIgnoreCache: true) { result in
            if case let .success(galleryContent) = result {
                XCTAssertNotNil(galleryContent)
                XCTAssertNotNil(galleryContent.contentElements)
                XCTAssertEqual(galleryContent.type, .gallery)
                XCTAssertNotNil(galleryContent.imageUrl)
                XCTAssertNotNil(galleryContent.contentElements?.first as? ImageContentElement)
                let galleryContentElement = galleryContent.contentElements?.first! as! ImageContentElement
                XCTAssertNotNil(galleryContentElement.resizedThumbnailImageUrl)
                apiExpectation.fulfill()
            } 
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    func testGalleryContentFailureBadGateway() {
        client.mock.mockType = .failure
        let apiExpectation = expectation(description: "Bad Gateway")
        let storyEndpoint = FeedsEndpoint.contentById("Gallery")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 500, url: storyEndpoint.url)
        client.getGalleryContent(identifier: "ID", shouldIgnoreCache: true) { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error as? NetworkError)
                let urlRequestError = error as! NetworkError
                switch urlRequestError {
                case .URLRequestError(reason: .serverError(let statusCode, cachedContent: _)):
                    XCTAssertEqual(statusCode, 500)
                    XCTAssertEqual(urlRequestError.errorDescription, "Server has encountered an error: \n Status code = 500 ")
                default:
                    XCTFail("Should throw a fail response")
                }
                apiExpectation.fulfill()
            }
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
    
    // This is just a test case to increase the coverage and we aren't expecting any authentication
    // May be something comes in future that worries about authorization.
    func testGalleryContentFailureUnauthorized() {
        client.mock.mockType = .failure
        let apiExpectation = expectation(description: "Unauthorized")
        let storyEndpoint = FeedsEndpoint.contentById("Gallery")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 401, url: storyEndpoint.url)
        client.getGalleryContent(identifier: "ID", shouldIgnoreCache: true) { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error as? NetworkError)
                let urlRequestError = error as! NetworkError
                switch urlRequestError {
                case .URLRequestError(reason: .unauthorizedError(let statusCode)):
                    XCTAssertEqual(statusCode, 401)
                    XCTAssertEqual(urlRequestError.errorDescription, "Access denied:\n Status code = 401")
                default:
                    XCTFail("Should throw a fail response")
                }
                apiExpectation.fulfill()
            }
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }
}
