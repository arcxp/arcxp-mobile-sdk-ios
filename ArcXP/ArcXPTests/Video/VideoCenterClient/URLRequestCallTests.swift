//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import XCTest

class URLRequestCallTests: ArcMediaTestBase {

    class DummyCodable: Codable {

    }

    // MARK: - Initialization

    func testInitializerWithDefaultArguments() throws {
        let url = URL(string: "https://www.washingtonpost.com")!
        let request = URLRequest(endpoint: url)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertNil(request.httpBody)
        XCTAssertEqual(request.allHTTPHeaderFields, [:])
    }

    func testInitializerWithSpecificArguments() {
        let url = URL(string: "https://www.washingtonpost.com")!
        let data = "Some data string".data(using: .utf8)
        let request = URLRequest(endpoint: url,
                                 httpMethod: "POST",
                                 body: data,
                                 headers: ["one": "two"])
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(String(data: request.httpBody!, encoding: .utf8), "Some data string")
        XCTAssertEqual(request.allHTTPHeaderFields!.count, 1)
        XCTAssertEqual(request.allHTTPHeaderFields!["one"], "two")
    }

    // MARK: - curlString

    func testCurlString() {
        let url = URL(string: "https://www.washingtonpost.com")!
        let data = "Some data string".data(using: .utf8)!
        let request = URLRequest(endpoint: url,
                                 httpMethod: "POST",
                                 body: data,
                                 headers: ["one": "two"])
        XCTAssertEqual(request.curlString,
                       "curl \"\(url)\" \\\n\t--request POST \\\n\t--header 'one: two' \\\n\t--data 'Some data string'")
    }

    func testCurlStringWithHeadMethod() {
        let url = URL(string: "https://www.washingtonpost.com")!
        let request = URLRequest(endpoint: url,
                                 httpMethod: "HEAD",
                                 headers: ["one": "two"])
        XCTAssertEqual(request.curlString,
                       "curl \"\(url)\" --head \\\n\t--header 'one: two'")
    }

    // MARK: - callAndExpectVoid()

    func testCallAndExpectVoidFromValidUrlOk() {
        let url = testBundle.url(forResource: "empty", withExtension: "json")!
        let exp = expectation(description: "empty JSON")

        url.callAndExpectVoid { (result) in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTFail("The tracker should have succeeded, and returned nothing")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)
    }

    func testCallAndExpectVoidFromValidUrlFailsIfDataIsReturned() {
        let url = testBundle.url(forResource: "avails", withExtension: "json")!
        let exp = expectation(description: "sample avails file")

        url.callAndExpectVoid { (result) in
            switch result {
            case .success:
                XCTFail("No data should have been returned.")
            case .failure:
                XCTAssertTrue(true)
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)
    }

    func testCallAndExpectVoidFromInvalidUrlFails() {
        let url = URL(string: "https://www.they-try-to-make-me-go-to-rehab.com")!
        let exp = expectation(description: "non-existent web site")

        url.callAndExpectVoid { (result) in
            switch result {
            case .success:
                XCTFail("This shouldn't have succeeded.")
            case .failure:
                XCTAssertTrue(true)
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)
    }

    // MARK: - callAndExpectString()

    func testCallAndExpectStringFromInvalidUrlFails() {
        let url = URL(string: "https://www.they-try-to-make-me-go-to-rehab.com")!
        let exp = expectation(description: "non-existent web site")

        url.callAndExpectString { (result) in
            switch result {
            case .success(let string):
                XCTFail("The empty file shouldn't contain anything, but it has \"\(string ?? "nothing")\".")
            case .failure:
                XCTAssertTrue(true)
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)
    }

    // MARK: - callAndExpectCodable()

    func testCallAndExpectCodableFromInvalidUrlFails() {
        let url = URL(string: "https://www.they-try-to-make-me-go-to-rehab.com")!
        let exp = expectation(description: "non-existent web site")

        url.callAndExpectCodable { (result: Result<DummyCodable, Error>) in
            switch result {
            case .success:
                XCTFail("This shouldn't have succeeded.")
            case .failure:
                XCTAssertTrue(true)
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)
    }

    func testCallAndExpectCodableOfWrongTypeFails() {
        let url = URL(string: "https://www.thankyouforhearingme.com")!
        let exp = expectation(description: "Thank You for Hearing Me")

        url.callAndExpectCodable { (result: Result<DummyCodable, Error>) in
            switch result {
            case .success:
                XCTFail("The return type should not have been a DummyCodable")
            case .failure:
                XCTAssertTrue(true)
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 15.0)
    }

    // MARK: - callAndExpectData()

}
