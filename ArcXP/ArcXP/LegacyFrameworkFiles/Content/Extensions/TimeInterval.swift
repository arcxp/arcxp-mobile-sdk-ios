//
//  TimeInterval.swift
//  UtilityBelt
//
//  Copyright © 2019 The Washington Post. All rights reserved.
//

import Foundation

/// Adds convenience functions to construct frequently used time interval
/// values, such as 5 minutes or 7 days. Example usage:
///
///    let interval: TimeInterval = .days(5)
///
/// or:
///
///    let policy: CachePolicy = .age(.days(5))
///
/// Please note that functions in this extension do not perform calendar
/// calculations and as such should not be used for situations where one needs
/// to construct a date object with high precision. These are intended to be used
/// only for specifying relative time intervals.
public extension TimeInterval {

    /// Returns time interval with duration equal to specified number of minutes
    ///
    /// - parameter number: Number of minutes
    /// - returns: Time interval for specified number of minutes
    static func minutes(_ number: Double) -> TimeInterval {
        return number * 60
    }

    /// Returns time interval with duration equal to specified number of hours
    ///
    /// - parameter number: Number of hours
    /// - returns: Time interval for specified number of hours
    static func hours(_ number: Double) -> TimeInterval {
        return number * 3600
    }

    /// Returns time interval with duration equal to specified number of days
    ///
    /// - parameter number: Number of days
    /// - returns: Time interval for specified number of days
    static func days(_ number: Double) -> TimeInterval {
        return number * 24 * 3600
    }

    /// Returns time interval with duration equal to specified number of weeks
    ///
    /// - parameter number: Number of weeks
    /// - returns: Time interval for specified number of weeks
    static func weeks(_ number: Double) -> TimeInterval {
        return number * 7 * 24 * 3600
    }
}

// MARK: - Sugar

public extension TimeInterval {

    static func minutes(_ number: Int) -> TimeInterval {
        return minutes(Double(number))
    }

    static func minutes(_ number: Float) -> TimeInterval {
        return minutes(Double(number))
    }

    static func hours(_ number: Int) -> TimeInterval {
        return hours(Double(number))
    }

    static func hours(_ number: Float) -> TimeInterval {
        return hours(Double(number))
    }

    static func days(_ number: Int) -> TimeInterval {
        return days(Double(number))
    }

    static func days(_ number: Float) -> TimeInterval {
        return days(Double(number))
    }

    static func weeks(_ number: Int) -> TimeInterval {
        return weeks(Double(number))
    }

    static func weeks(_ number: Float) -> TimeInterval {
        return weeks(Double(number))
    }
}
