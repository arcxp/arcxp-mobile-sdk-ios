//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import XCTest

class ArcXPLoggerTests: XCTestCase {

    // MARK: - log(message:)

    func testLogMessageWithVariousLoggingLevels() {
        let message = "some message"

        for level in ArcXPLogger.Level.allCases {
            ArcXPLogger.level = level
            let loggedString = ArcXPLogger.log(message)

            if level != .all {
                XCTAssertNil(loggedString)
            } else {
                XCTAssertNotNil(loggedString)
                XCTAssertTrue(loggedString!.contains(message))
                XCTAssertTrue(loggedString!.contains(#function))
            }
        }
    }

    // MARK: - logError()

    func testLogErrorWithVariousLoggingLevels() {
        let message = "some message"
        let error = NSError(domain: "some domain", code: 1564, userInfo: nil)

        for level in ArcXPLogger.Level.allCases {
            ArcXPLogger.level = level
            let loggedString = ArcXPLogger.log(message, error: error)

            if level == .off {
                XCTAssertNil(loggedString)
            } else {
                XCTAssertNotNil(loggedString)
                XCTAssertTrue(loggedString!.contains(message))
                XCTAssertTrue(loggedString!.contains("some domain"))
                XCTAssertTrue(loggedString!.contains("1564"))
                XCTAssertTrue(loggedString!.contains(#function))
            }
        }
    }

    // MARK: - logIfNil()

    func testLogIfNilWithVariousLoggingLevels() {
        let thing: String? = nil

        for logLevel in ArcXPLogger.Level.allCases {
            ArcXPLogger.level = logLevel

            if logLevel == .all {
                let loggedString = ArcXPLogger.logIfNil(thing)
                XCTAssertNotNil(loggedString)
                XCTAssertTrue(loggedString!.contains(#function))
            } else {
                XCTAssertNil(ArcXPLogger.logIfNil(thing))
            }
        }
    }

    // MARK: - logHTTPError()

    func testLogHTTPErrorWithVariousLoggingLevels() {
        let message = "some message"
        let description = "some description"
        let statusCode = 404

        for level in ArcXPLogger.Level.allCases {
            ArcXPLogger.level = level
            let loggedString = ArcXPLogger.logHTTPError(message, description: description, statusCode: statusCode)

            if level == .off {
                XCTAssertNil(loggedString)
            } else {
                XCTAssertNotNil(loggedString)
                XCTAssertTrue(loggedString!.contains(message))
                XCTAssertTrue(loggedString!.contains(description))
                XCTAssertTrue(loggedString!.contains("\(statusCode)"))
                XCTAssertTrue(loggedString!.contains(#function))
            }
        }
    }
    // MARK: - logRequest()

    func testLogUrlRequestWithVariousLoggingLevels() {
        let url = URL(string: "https://washingtonpost.com")!
        var request = URLRequest(url: url)
        request.setValue("one", forHTTPHeaderField: "header1")
        request.setValue("two", forHTTPHeaderField: "header2")
        let bodyString = "request_body"
        request.httpBody = bodyString.data(using: .utf8)

        for level in ArcXPLogger.Level.allCases {
            ArcXPLogger.level = level
            let loggedString = ArcXPLogger.logRequest(urlRequest: request)

            if level == .off || level == .error {
                XCTAssertNil(loggedString)
            } else {
                XCTAssertNotNil(loggedString)
                XCTAssertTrue(loggedString!.contains(url.absoluteString))
                XCTAssertTrue(loggedString!.contains("header1"))
                XCTAssertTrue(loggedString!.contains("header2"))
                XCTAssertTrue(loggedString!.contains(bodyString))
                XCTAssertTrue(loggedString!.contains(#function))
            }
        }
    }

}
