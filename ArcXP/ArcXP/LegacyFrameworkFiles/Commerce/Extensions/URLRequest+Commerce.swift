//
//  File.swift
//  Commerce
//
//  Created by Seitz, David on 7/21/20.
//  Copyright © 2020 The Washington Post Company. All rights reserved.
//

import Foundation

extension URLRequest {

    /// Adds the given headers to the URLRequest object.
    /// - Parameters:
    ///     - headers: The headers to be added to the URLRequest.
    mutating func addHeaders(_ headers: [String: String]?) {
        if let headers = headers {
            for value in headers {
                self.addValue(value.value, forHTTPHeaderField: value.key)
            }
        }
    }
}
