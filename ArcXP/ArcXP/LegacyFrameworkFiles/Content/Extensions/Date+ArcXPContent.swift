//
//  Date+ArcXPContent.swift
//  ArcXPContent
//
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//  Created by Davis, Tyler on 1/19/22.
//

import Foundation

extension DateFormatter {
    static let jsonFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
