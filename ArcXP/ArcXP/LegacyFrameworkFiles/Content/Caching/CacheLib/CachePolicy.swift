//
//  CachePolicy.swift
//  PostKit
//
//  Created by Schoenfeld, Andrew on 9/10/16.
//  Copyright © 2016 The Washington Post. All rights reserved.
//

import Foundation


public enum CachePolicy: Equatable {

    /// Always use cached version if we have it
    case allow

    /// Never use cached version
    case bypass

    /// Use the cached version if it's equal to or newer than the associated date
    case compareTo(modified: Date?, requested: TimeInterval?)


    /// Initialize cache policy Bypass, compare to previous modified/requested date, otherwise Allow
    ///
    /// - parameter bypass: option if request should go straight to web
    /// - parameter modified: previously modified time, optional
    /// - parameter requested: maximum age of cached item in cache, optional
    public init(bypass bypassed: Bool = false, modified: Date? = nil, requested: TimeInterval? = nil) {
        if bypassed {
            self = .bypass
        } else if modified != nil || requested != nil {
            self = .compareTo(modified: modified, requested: requested)
        } else {
            self = .allow
        }
    }

    /// Convenience to create cache policy comparing last requested date against specified age,
    /// in seconds.
    public init(age: TimeInterval) {
        self.init(requested: age)
    }

    /// Combines this cache policy with another, returning the policy which is as strict as
    /// both policies combined.
    public func union(_ other: CachePolicy) -> CachePolicy {
        switch (self, other) {
        case (.bypass, _):
            return self
        case (_, .bypass):
            return other
        case (.compareTo, .allow):
            return self
        case (.allow, .compareTo):
            return other
        case (.compareTo(let aModified, let aRequested), .compareTo(let bModified, let bRequested)):
            let modified = max(aModified, bModified)
            let requested = min(aRequested, bRequested)
            return .compareTo(modified: modified, requested: requested)
        case (.allow, .allow):
            return self
        }
    }

    /// Use the cached version if .Allow or modified/requested date is sooner than param
    /// - parameter lastModified: lastModified time
    /// - parameter lastRequested: lastRequested time
    /// - returns: True if we should use the cached version
    public func shouldAllowCached(lastModified: Date? = nil, lastRequested: Date? = nil) -> Bool {
        switch self {
        case .allow:
            return true

        case .bypass:
            return false

        case .compareTo(let modifiedDate, let requestedInterval):
            var result = true
            if let modifiedDate = modifiedDate {
                result = result && (modifiedDate <= lastModified ?? .distantPast)
            }
            if let requestedInterval = requestedInterval {
                result = result && (requestedInterval >= -(lastRequested ?? .distantPast).timeIntervalSinceNow)
            }
            return result
        }
    }

    public static func age(_ age: TimeInterval) -> CachePolicy {
        return CachePolicy(age: age)
    }

    public static func == (lhs: CachePolicy, rhs: CachePolicy) -> Bool {
        switch (lhs, rhs) {
        case (.allow, .allow):
            return true

        case (.bypass, .bypass):
            return true

        case (let .compareTo(modified1, requested1), let .compareTo(modified2, requested2)):
            return modified1 == modified2 && requested1 == requested2

        default:
            return false
        }
    }

}

// MARK: - Helpers

private func max(_ a: Date?, _ b: Date?) -> Date? {
    if let a = a, let b = b {
        return max(a, b)
    } else {
        return a ?? b
    }
}

private func min(_ a: TimeInterval?, _ b: TimeInterval?) -> TimeInterval? {
    if let a = a, let b = b {
        return min(a, b)
    } else {
        return a ?? b
    }
}
