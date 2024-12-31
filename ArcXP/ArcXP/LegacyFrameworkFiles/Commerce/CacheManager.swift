//
//  CacheManager.swift
//  AppAuth
//
//  Created by David Seitz Jr on 11/1/21.
//  Copyright © 2023 The Washington Post Company. All rights reserved.
//

import Foundation
import Security

/// Handles values and operations related to caching data for the Commerce service.
struct CacheManager {

    enum Constant: String {
        case accessTokenKey = "CommerceAccessTokenKey"
        case mobileConfigKey = "CommerceMobileConfigKey"
        case refreshTokenKey = "CommerceRefreshTokenKey"
        case rememberMeKey = "CommerceRememberLoginKey"
        case cachedUserRules = "CommerceRulesData"
        case successKey = "success"
        case deviceID = "deviceID"
        case pendingAnalytics = "PendingAnalytics"
        case lastPing = "LastPingTime"
        case install = "Install"
    }

    /// Sets a value for a given key in the cache.
    /// - Parameters:
    ///  - value: The value to store.
    ///  - key: The key to store the value under.
    static func set(value: Any?, forKey key: CacheManager.Constant) {

        switch key {
        case .accessTokenKey, .refreshTokenKey, .deviceID:
            // Save to Keychain
            guard value != nil else { removeValue(forKey: key); return }
            guard let value = value as? String else {
                // Unexpected value
                devPrint("Commerce CacheManager: Could not store value \(key.rawValue) because of an unexpected value type.")
                return
            }

            KeychainManager.standard.set(value, forKey: key.rawValue)

        default:
            // Save to UserDefaults
            UserDefaults.standard.set(value, forKey: key.rawValue)
        }
    }

    /// Fetches a value for a given key from the cache.
    /// - Parameters:
    /// - key: The key to fetch the value for.
    /// - Returns: The value stored for the given key.
    static func getValue(forKey key: CacheManager.Constant) -> Any? {
        switch key {

        case .accessTokenKey, .refreshTokenKey, .deviceID:
            // Fetch from Keychain
            return KeychainManager.standard.string(forKey: key.rawValue)

        case .rememberMeKey, .install:
            // Boolean is expected. Returns false if using generic value for key method.
            return UserDefaults.standard.bool(forKey: key.rawValue)

        case .cachedUserRules:

            guard let cachedUserRulesData = UserDefaults.standard.value(forKey: key.rawValue) as? Data else {
                devPrint("Commerce: CacheManager - There was a problem fetching cached user rules.")
                return nil
            }
            do {
                let cachedUserRules = try JSONDecoder().decode(UserRules.self, from: cachedUserRulesData)
                return cachedUserRules
            } catch {
                devPrint("Commerce: CacheManager - There was a problem decoding fetched cached user rules.")
                return nil
            }

        case .pendingAnalytics:
            // Return a string array of pending analytics events.
            return UserDefaults.standard.stringArray(forKey: key.rawValue)
        default:
            // Fetch from UserDefaults
            return UserDefaults.standard.value(forKey: key.rawValue) as? String
        }
    }

    /// Removes a value for a given key from the cache.
    /// - Parameters:
    /// - key: The key to remove the value for.
    static func removeValue(forKey key: CacheManager.Constant) {
        switch key {
        case .accessTokenKey, .refreshTokenKey:
            // Remove from Keychain
            KeychainManager.standard.removeObject(forKey: key.rawValue)
        default:
            // Remove from UserDefaults
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }
    }
}
