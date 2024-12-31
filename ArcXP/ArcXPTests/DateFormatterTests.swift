//
//  DateFormatterTests.swift
//  ArcXPTests
//
//  Created by David Seitz on 12/6/23.
//  Copyright © 2023 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class DateFormatterTests: XCTestCase {

    func testJSONFormatterHasCorrectProperties() {
        let jsonFormatter = DateFormatter.jsonFormatter
        XCTAssertEqual(jsonFormatter.dateFormat, "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ")
        XCTAssertEqual(jsonFormatter.calendar, Calendar(identifier: .iso8601))
        XCTAssertEqual(jsonFormatter.timeZone, TimeZone(secondsFromGMT: 0))
        XCTAssertEqual(jsonFormatter.locale, Locale(identifier: "en_US_POSIX"))
    }
    
    func testJSONFormatterProducesCorrectDate() {
        let dateString = "2023-12-06T10:30:45.123+0000"
        let expectedDate = DateFormatter.jsonFormatter.date(from: dateString)
        XCTAssertEqual(expectedDate, expectedDate)
    }
}
