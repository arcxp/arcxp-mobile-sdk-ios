//
//  ArcXPJsonFetchingTest.swift
//  ArcXPContentTests
//
//  Created by Soldier Williams on 2/2/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//
// swiftlint:disable force_cast
import XCTest
@testable import ArcXP

class ArcXPJsonFetchingTest: BaseNetworkTests {

    let client = ArcXPContentManager.client

    func testCollection() throws {
        client.mock.mockType = .success
        let apiExpectation = expectation(description: "Get collection")
        let collectionEndpoint = FeedsEndpoint.collection("test", index: 0, size: 2)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: collectionEndpoint.url)
        client.getRawJsonContent(requestType: .collection, identifierOrAlias: "test") { result in
            switch result {
            case .success(let stories):
                guard let data = stories.data(using: .utf8) else {
                    XCTFail("Response is invalid")
                    return
                }
                do {
                    if let stories = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [Any] {
                        XCTAssertEqual(stories.count, 2)
                        if let firstStory = stories.first as? [String: Any] {
                            XCTAssertNotNil(firstStory["taxonomy"])
                            XCTAssertNotNil(firstStory["_id"])
                            XCTAssertNotNil(firstStory["canonical_url"])
                        } else {
                            XCTFail("firstStory does not exist")
                        }
                    } else {
                        XCTFail("Response is invalid")
                    }
                } catch let error as NSError {
                    XCTFail(error.localizedDescription)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
    }

    func testCollectionFailure() {
        client.mock.mockType = .failure
        // mock response
        let apiExpectation = expectation(description: "Collection errors out")
        let collectionEndpoint = FeedsEndpoint.collection("test", index: 0, size: 2)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 404, url: collectionEndpoint.url)

        client.getRawJsonContent(requestType: .collection, identifierOrAlias: "test") { result in
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
    
//    func testCollectionEndPointMalformed() {
//            client.mock.useMocks = false
//            let apiExpectation = expectation(description: "URL failure")
//            // This fails because the identifier has a space and a valid url can't be constructed
//            client.getRawJsonContent(requestType: .collectionType, identifierOrAlias: "Alias ID") { result in
//                if case let .failure(error) = result {
//                    XCTAssertNotNil(error as? NetworkError)
//                    let urlRequestError = error as! NetworkError
//                    XCTAssertEqual(urlRequestError.errorDescription,
//                                   NetworkError.URLRequestError(reason: .endpointMalformed).errorDescription)
//                    apiExpectation.fulfill()
//                }
//            }
//            wait(for: [apiExpectation], timeout: expectationTimeOut)
//        }
    
    func testEmptyResult() throws {
        client.mock.mockType = .success
        let apiExpectation = expectation(description: "Get collection")
        let collectionEndpoint = FeedsEndpoint.collection("test", index: 0, size: 2)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: collectionEndpoint.url)
        client.getRawJsonContent(requestType: .collection, identifierOrAlias: "test") { result in
            switch result {
            case .success(let stories):
                guard !stories.isEmpty else {
                    XCTFail("Response is invalid")
                    return
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
        // The content type recorded is taken in the failure case
    }
    
    func testContentType() {
        client.mock.mockType = .failure
        client.mock.useMocks = true
        let apiExpectation = expectation(description: "Get Content By Id")
        let collectionEndpoint = FeedsEndpoint.contentById("invalidCollectionTest")
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: collectionEndpoint.url)
        client.getRawJsonContent(requestType: .collection, identifierOrAlias: "invalidCollectionTest") { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error)
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: expectationTimeOut)
        // The content type recorded is taken in the failure case
    }
}
