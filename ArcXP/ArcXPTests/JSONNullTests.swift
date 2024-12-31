//
//  JSONNullTests.swift
//  ArcXPTests
//
//  Created by David Seitz on 12/6/23.
//  Copyright © 2023 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class JSONNullTests: XCTestCase {

    func testEquality() {
        let jsonNull1 = JSONNull()
        let jsonNull2 = JSONNull()
        XCTAssertEqual(jsonNull1, jsonNull2, "JSONNull instances should always be equal")
    }

    func testDefaultInitializer() {
        XCTAssertNotNil(JSONNull(), "Default initializer should create a non-nil instance")
    }

    func testDecodableWithNullValue() {
        let json = "null"
        let decoder = JSONDecoder()
        do {
            let decoded = try decoder.decode(JSONNull.self, from: Data(json.utf8))
            XCTAssertNotNil(decoded, "Should successfully decode JSON null value")
        } catch {
            XCTFail("Decoding should not fail for valid JSON null value")
        }
    }

    func testDecodableWithInvalidType() {
        let json = "\"string\""
        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(JSONNull.self, from: Data(json.utf8)), "Decoding should fail for non-null values") { error in
            XCTAssertTrue(error is DecodingError, "Thrown error should be of type DecodingError")
        }
    }

    func testEncodable() {
        let jsonNull = JSONNull()
        let encoder = JSONEncoder()
        do {
            let encodedData = try encoder.encode(jsonNull)
            let encodedString = String(data: encodedData, encoding: .utf8)
            XCTAssertEqual(encodedString, "null", "Encoded result should be a JSON null")
        } catch {
            XCTFail("Encoding should not fail")
        }
    }

    func testHashability() {
        let jsonNull = JSONNull()
        var hashSet = Set<JSONNull>()
        hashSet.insert(jsonNull)
        XCTAssertEqual(hashSet.count, 1, "JSONNull should be able to be inserted into a hash set")
    }
}
