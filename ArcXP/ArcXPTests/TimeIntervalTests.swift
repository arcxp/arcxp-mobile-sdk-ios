//
//  TimeIntervalTests.swift
//  ArcXPTests
//
//  Created by David Seitz on 12/6/23.
//  Copyright © 2023 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class TimeIntervalTests: XCTestCase {

    // Tests for minutes method
    func testMinutesWithDouble() {
        XCTAssertEqual(TimeInterval.minutes(5.0), 300.0, "5.0 minutes should equal 300 seconds")
    }

    func testMinutesWithInt() {
        XCTAssertEqual(TimeInterval.minutes(5), 300.0, "5 minutes should equal 300 seconds")
    }

    func testMinutesWithFloat() {
        XCTAssertEqual(TimeInterval.minutes(Float(5.0)), 300.0, "5.0 minutes should equal 300 seconds")
    }

    // Tests for hours method
    func testHoursWithDouble() {
        XCTAssertEqual(TimeInterval.hours(2.0), 7200.0, "2.0 hours should equal 7200 seconds")
    }

    func testHoursWithInt() {
        XCTAssertEqual(TimeInterval.hours(2), 7200.0, "2 hours should equal 7200 seconds")
    }

    func testHoursWithFloat() {
        XCTAssertEqual(TimeInterval.hours(Float(2.0)), 7200.0, "2.0 hours should equal 7200 seconds")
    }

    // Tests for days method
    func testDaysWithDouble() {
        XCTAssertEqual(TimeInterval.days(1.0), 86400.0, "1.0 day should equal 86400 seconds")
    }

    func testDaysWithInt() {
        XCTAssertEqual(TimeInterval.days(1), 86400.0, "1 day should equal 86400 seconds")
    }

    func testDaysWithFloat() {
        XCTAssertEqual(TimeInterval.days(Float(1.0)), 86400.0, "1.0 day should equal 86400 seconds")
    }

    // Tests for weeks method
    func testWeeksWithDouble() {
        XCTAssertEqual(TimeInterval.weeks(1.0), 604800.0, "1.0 week should equal 604800 seconds")
    }

    func testWeeksWithInt() {
        XCTAssertEqual(TimeInterval.weeks(1), 604800.0, "1 week should equal 604800 seconds")
    }

    func testWeeksWithFloat() {
        XCTAssertEqual(TimeInterval.weeks(Float(1.0)), 604800.0, "1.0 week should equal 604800 seconds")
    }
}
