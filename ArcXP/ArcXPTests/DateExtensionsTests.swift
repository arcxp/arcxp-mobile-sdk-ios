//
//  DateExtensionsTests.swift
//  ArcXPTests
//
//  Created by David Seitz on 12/15/23.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class DateExtensionsTests: XCTestCase {

    // Test for isNewDay
    func testIsNewDay() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        XCTAssertTrue(Date.isNewDay(firstDate: today, secondDate: tomorrow))
        XCTAssertFalse(Date.isNewDay(firstDate: today, secondDate: today))
    }

    // Test for isNewWeek
    func testIsNewWeek() {
        let thisWeek = Date()
        let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: thisWeek)!

        XCTAssertTrue(Date.isNewWeek(firstDate: thisWeek, secondDate: nextWeek))
        XCTAssertFalse(Date.isNewWeek(firstDate: thisWeek, secondDate: thisWeek))
    }

    // Test for isNewMonth
    func testIsNewMonth() {
        let thisMonth = Date()
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: thisMonth)!

        XCTAssertTrue(Date.isNewMonth(firstDate: thisMonth, secondDate: nextMonth))
        XCTAssertFalse(Date.isNewMonth(firstDate: thisMonth, secondDate: thisMonth))
    }

    // Test for startOfDay
    func testStartOfDay() {
        let date = Date()
        let startOfDay = date.startOfDay
        let calendar = Calendar(identifier: .gregorian)

        XCTAssertTrue(calendar.isDate(startOfDay, equalTo: date, toGranularity: .day))
        XCTAssertEqual(calendar.component(.hour, from: startOfDay), 0)
        XCTAssertEqual(calendar.component(.minute, from: startOfDay), 0)
        XCTAssertEqual(calendar.component(.second, from: startOfDay), 0)
    }

    // Test for globalTime
    func testGlobalTime() {
        let localDate = Date()
        let globalDate = localDate.globalTime
        let timeZoneOffset = TimeInterval(TimeZone.current.secondsFromGMT(for: localDate))

        XCTAssertEqual(globalDate, localDate.addingTimeInterval(-timeZoneOffset))
    }

    // Test for localTimeFromGMT
    func testLocalTimeFromGMT() {
        let globalDate = Date()
        let localDate = globalDate.localTimeFromGMT
        let timeZoneOffset = TimeInterval(TimeZone.current.secondsFromGMT(for: globalDate))

        XCTAssertEqual(localDate, globalDate.addingTimeInterval(timeZoneOffset))
    }

    // Test for days(from:)
    func testDaysFrom() {
        let today = Date()
        let tenDaysLater = today.days(from: 10)
        let tenDaysEarlier = today.days(from: -10)

        XCTAssertEqual(Calendar.current.date(byAdding: .day, value: 10, to: today), tenDaysLater)
        XCTAssertEqual(Calendar.current.date(byAdding: .day, value: -10, to: today), tenDaysEarlier)
    }
}
