//
//  CachingManager.swift
//  ArcXPCommerce
//
//  Created by Davis, Tyler on 8/13/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation

/// Manages the caching of paywall rules.
public struct PaywallCacheManager {

    /// A cache containing rules the user has interacted with.
    public static var userRules: UserRules {
        get {
            // Allowing fetch on every instance to make sure we're getting the latest saved details possible.
            return fetchUserRules()
        }
        set {
            cache(rules: newValue)
        }
    }

    /// Fetch the latest cached UserRules from `UserDefaults` via `CacheManager`.
    /// - returns: A collection of cached UserRule objects.
    private static func fetchUserRules() -> UserRules {
        if let cachedUserRules = CacheManager.getValue(forKey: .cachedUserRules) as? UserRules {
            return cachedUserRules
        } else {
            // No user rules exist in CacheManager. Create and save new set of user rules.
            let userRules = UserRules(rules: [Int: UserRules.UserRule]())
            cache(rules: userRules)
            return userRules
        }
    }

    /// Saves a specific `UserRule` object to `UserDefaults` via `CacheManager`.
    /// - parameter rule: The rule to be cached.
    /// - parameter ruleID: The ID of the rule.
    static func cache(rule: UserRules.UserRule, withID ruleID: Int) {
        userRules.rules[ruleID] = rule
        cache(rules: userRules)
    }

    /// Saves the provided UserRules to `UserDefaults` via `CacheManager`.
    /// - parameter userRules: The `UserRules` to be cached.
    static func cache(rules userRules: UserRules) {
        do {
            let userRulesJson = try JSONEncoder().encode(userRules)
            CacheManager.set(value: userRulesJson, forKey: .cachedUserRules)
        } catch {
            devPrint("Commerce: PaywayllCacheManager - An error occured while saving rules data. Error: \(error)")
        }
    }

    /// Removes all UserRules from `UserDefaults` via `CacheManager`.
    public static func clearPaywallCache() {
        CacheManager.removeValue(forKey: .cachedUserRules)
        let userRules = UserRules(rules: [Int: UserRules.UserRule]())
        cache(rules: userRules)
    }
}
