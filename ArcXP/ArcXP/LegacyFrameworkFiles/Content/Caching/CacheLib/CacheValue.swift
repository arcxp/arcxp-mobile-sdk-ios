//
//  CacheValue.swift
//  PostKit
//
//  Created by Vadim Gritsenko on 1/17/17.
//  Copyright © 2017 The Washington Post. All rights reserved.
//

import Foundation


/// Protocol for hint option set passed into the cache
public protocol CacheHint: OptionSet {
    var rawValue: Int { get }

    static var none: Self.Element { get }
    static var uncached: Self.Element { get }
    static var untouched: Self.Element { get }
}


/// Protocol for values stored in the cache
public protocol CacheValue: Codable {
    associatedtype Value where Value == Self
    associatedtype Hint: CacheHint

    /// Memory cost estimation (size in bytes) based on object itself or the passed in data
    ///
    /// - parameter data: Data used to construct this value, can be used for cost estimation
    /// - returns: Estimated cache cost of this value
    func cost(with data: Data?) -> Int

    /// Constructs value from the data stored in the disk cache
    ///
    /// - parameter data: Data from which new cache value should be constructed
    /// - parameter hint: Options for constructing the cache value
    /// - returns: Constructed cache value
    static func value(from data: Data, hint: Hint) -> Value?
}


/// Default implementation for `CacheHint` implementing `none` and `uncached` values.
public struct DefaultCacheHint: CacheHint {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let none: DefaultCacheHint = []
    public static let uncached = DefaultCacheHint(rawValue: 1)
    public static let untouched = DefaultCacheHint(rawValue: 2)
}


// MARK: - Helpers

public extension CacheValue {

    /// Default implementation of the `cost(with:)` function suitable for most adopters. Can be
    /// overriden by implementors to provide better cost estimation.
    func cost(with data: Data?) -> Int {
        return data?.count ?? 1
    }

    /// Default implementation of the `value(from:hint:)` function for the values decodable from JSON
    static func value<Value: Codable>(from data: Data, hint: Hint) -> Value? {
        if let parsedObject: Value = try? JSONDecoder().decode(Value.self, from: data) {
            return parsedObject
        }

        return nil
    }

    // TODO: Needed?
    /// Helper function for loading value from a named resource in the bundle
    static func value(bundle: Foundation.Bundle, resource: String, type: String = "json", hint: Hint) -> Value? {
        guard let path = bundle.path(forResource: resource, ofType: type),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path, isDirectory: false), options: .mappedIfSafe) else {
            assert(false, "Error loading resource: \(resource).\(type)")
            return nil
        }

        return value(from: data, hint: hint)
    }

}
