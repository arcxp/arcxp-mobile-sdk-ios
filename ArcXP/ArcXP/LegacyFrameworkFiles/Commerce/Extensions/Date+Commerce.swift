//
//  Date+Commerce.swift
//  ArcXPCommerce
//
//  Created by David Seitz Jr on 7/29/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation

extension Date {

    /// Checks if two dates are on different days
    /// - Parameters:
    ///    - firstDate: The first date to compare.
    ///    - secondDate: The second date to compare.
    /// - Returns: A boolean value indicating whether the two dates are on different days
    static func isNewDay(firstDate: Date, secondDate: Date) -> Bool {
        let calendar = Calendar.current
        return !calendar.isDate(firstDate, inSameDayAs: secondDate)
    }

    /// Checks if two dates are in different weeks
    /// - Parameters:
    ///    - firstDate: The first date to compare.
    ///    - secondDate: The second date to compare.
    ///    - Returns: A boolean value indicating whether the two dates are in different weeks
    static func isNewWeek(firstDate: Date, secondDate: Date) -> Bool {
        let calendar = Calendar.current
        let firstWeek = calendar.component(.weekOfYear, from: firstDate)
        let secondWeek = calendar.component(.weekOfYear, from: secondDate)
        return firstWeek != secondWeek
    }

    /// Checks if two dates are in different months
    /// - Parameters:
    ///    - firstDate: The first date to compare.
    ///    - secondDate: The second date to compare.
    ///    - Returns: A boolean value indicating whether the two dates are in different months
    static func isNewMonth(firstDate: Date, secondDate: Date) -> Bool {
        let calendar = Calendar.current
        let firstMonth = calendar.component(.month, from: firstDate)
        let secondMonth = calendar.component(.month, from: secondDate)
        return firstMonth != secondMonth
    }
}

extension Date {

    /// Start of the date (midnight)
    var startOfDay: Date {
        let cal = Calendar(identifier: .gregorian)
        return cal.startOfDay(for: self)
    }

    /// Converts local time to UTC (or GMT)
    var globalTime: Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: -seconds, since: self)
    }

    /// Converts UTC (or GMT) to local time
    var localTimeFromGMT: Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }

    func days(from value: Int) -> Date {
        var dateComponents = DateComponents()
        dateComponents.setValue(value, for: .day)

        return Calendar.current.date(byAdding: dateComponents, to: self)!
    }
}
