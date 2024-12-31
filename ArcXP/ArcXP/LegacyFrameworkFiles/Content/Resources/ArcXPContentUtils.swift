//
//  ArcXPContentUtils.swift
//  ArcXP
//
//  Created by Mahesh Venkateswarlu on 7/15/22.
//  Copyright © 2022 Arc XP. All rights reserved.
//

import Foundation

public struct ArcXPContentUtils {

    /// Converts the given date String into a readable format.
    /// i/p -> 2022-04-07T08:00:00.000Z
    /// o/p -> April 7, 2022 at 8:00 AM EDT
    /// - Parameter dateString: date `String` that needs to formatted
    /// - Returns: Formatted date `String`. If formating fails, returns nil
    public static func formattedDate(dateString: String?) -> String? {
        guard let dateString = dateString else {
            return nil
        }
        let formattedDate = convertDateFormat(fromFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                                              toFormat: "MMMM d, yyyy 'at' h:mm a ",
                                              dateString)
        if let formattedDate = formattedDate,
           let timeZone = TimeZone.current.abbreviation() {
            return formattedDate + timeZone
        }
        return nil
    }

    /// Converts the given date String into the formats as provided in the arguments
    /// - Parameters:
    ///   - fromFormat: `String` the format of the input dateString
    ///   - toFormat: `String` the expected format to get convert into
    ///   - dateString: `String` date that needs to be converted
    /// - Returns: `String` formatted dateString with respect to the given format, If formatting fails, returns nil.
    public static func convertDateFormat(fromFormat: String,
                                         toFormat: String,
                                         _ dateString: String) -> String? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = fromFormat
        let formattedDate = formatter.date(from: dateString)
        formatter.dateFormat = toFormat
        if let formattedDate = formattedDate {
            return formatter.string(from: formattedDate)
        }
        return nil
    }

    /// Constructs the URL with the given relative path and the host domain.
    public static func prefixOrgDomain(relativePath: String) -> String? {
        return ArcXPContentManager.client.configuration.hostDomain + relativePath
    }
}

func encodeToString<T: Encodable>(_ value: T) -> String? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted // Makes the JSON string more readable
    guard let data = try? encoder.encode(value) else { return nil }
    return String(data: data, encoding: .utf8)
}
