//
//  Codable+Commerce.swift
//  Commerce
//
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation

extension Encodable {
    /// Converts the object to JSON encoded data.
    /// - Returns: A JSON encoded data object.
    func toJSONData() -> Data? { try? JSONEncoder().encode(self) }
}
