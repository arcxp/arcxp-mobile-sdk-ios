//
//  CacheError.swift
//  PostKit
//
//  Created by Vadim Gritsenko on 1/17/17.
//  Copyright © 2017 The Washington Post. All rights reserved.
//

import Foundation


/// Errors returned by PostKit Cache
public enum CacheError: Error {

    /// Miss: Specified key was not found
    case miss(key: String)

    /// Disk access error: Could not read file
    case access(key: String, reason: Error?)

    /// Serialization error: Could not construct object from file data
    case serialization(key: String)

}
