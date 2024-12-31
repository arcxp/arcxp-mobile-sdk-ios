//
//  String+Alphanumeric.swift
//  ArcXPContent
//
//  Copyright © 2022 Arc XP. All rights reserved.
//  Created by Soldier Williams on 2/14/22.
//

import Foundation

extension String {
    /// Replaces the occurences of the provided regex pattern with empty strings.
    var alphanumericWithSpaces: String {
        let pattern = "[^A-Za-z0-9 -]+"
        let result = self.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        return result
    }
}
