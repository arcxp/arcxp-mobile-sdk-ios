//
//  UtilTests.swift
//  ArcXPTests
//
//  Created by Mahesh Venkateswarlu on 7/15/22.
//  Copyright © 2022 Arc XP. All rights reserved.
//

import XCTest
@testable import ArcXP

class UtilTests: XCTestCase {

    func testConvertedDateFormat() {
        let formattedDate = ArcXPContentUtils.formattedDate(dateString: "2022-04-07T08:00:00.000Z")
        let timeZone = TimeZone.current.abbreviation()
        XCTAssertEqual(formattedDate, "April 7, 2022 at 8:00 AM \(timeZone!)")
    }

    func testInvalidDateFormat() {
        let formattedDate = ArcXPContentUtils.formattedDate(dateString: "202204070800000")
        XCTAssertNil(formattedDate)
    }
    
    func testNilDateConversion() {
        let dateString: String? = nil
        let formattedDate = ArcXPContentUtils.formattedDate(dateString: dateString)
        XCTAssertNil(formattedDate)
    }
}
