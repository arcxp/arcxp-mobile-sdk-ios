//
//  KeychainManager.swift
//  ArcXPCommerce
//
//  Created by David Seitz Jr on 11/18/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation
import Security

enum KeychainItemAccessibility {

    case afterFirstUnlock
    case afterFirstUnlockThisDeviceOnly
    case always
    case whenPasscodeSetThisDeviceOnly
    case alwaysThisDeviceOnly
    case whenUnlocked
    case whenUnlockedThisDeviceOnly

    static func accessibilityForAttributeValue(_ keychainAttrValue: CFString) -> KeychainItemAccessibility? {
        for (key, value) in keychainItemAccessibilityLookup {
            if value == keychainAttrValue { return key }
        }
        return nil
    }
}

let keychainItemAccessibilityLookup: [KeychainItemAccessibility:CFString] = {
    var lookup: [KeychainItemAccessibility: CFString] = [.afterFirstUnlock: kSecAttrAccessibleAfterFirstUnlock,
                                                         .afterFirstUnlockThisDeviceOnly: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                                                         .always: kSecAttrAccessibleAlways,
                                                         .whenPasscodeSetThisDeviceOnly: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                         .alwaysThisDeviceOnly : kSecAttrAccessibleAlwaysThisDeviceOnly,
                                                         .whenUnlocked: kSecAttrAccessibleWhenUnlocked,
                                                         .whenUnlockedThisDeviceOnly: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
    return lookup
}()

protocol KeychainAttrRepresentable {
    var keychainAttrValue: CFString { get }
}

extension KeychainItemAccessibility: KeychainAttrRepresentable {
    internal var keychainAttrValue: CFString {
        return keychainItemAccessibilityLookup[self]!
    }
}

/// KeychainManager is a wrapper around the iOS Keychain services that allows for easy access to Keychain items.
struct KeychainManager {

    // MARK: Properties

    static let standard = KeychainManager(serviceName: "CommerceSecureCache", accessGroup: nil)

    /// ServiceName is used for the kSecAttrService property to uniquely identify this keychain accessor. If no service name is specified, KeychainWrapper will default to using the bundleIdentifier.
    private (set) var serviceName: String

    /// AccessGroup is used for the kSecAttrAccessGroup property to identify which Keychain Access Group this entry belongs to. This allows you to use the KeychainWrapper with shared keychain access between different applications.
    private (set) var accessGroup: String?

    private let SecMatchLimit: String! = kSecMatchLimit as String
    private let SecReturnData: String! = kSecReturnData as String
    private let SecValueData: String! = kSecValueData as String
    private let SecAttrAccessible: String! = kSecAttrAccessible as String
    private let SecClass: String! = kSecClass as String
    private let SecAttrService: String! = kSecAttrService as String
    private let SecAttrGeneric: String! = kSecAttrGeneric as String
    private let SecAttrAccount: String! = kSecAttrAccount as String
    private let SecAttrAccessGroup: String! = kSecAttrAccessGroup as String
    private let SecAttrSynchronizable: String = kSecAttrSynchronizable as String

    private func setupKeychainQueryDictionary(forKey key: String,
                                              withAccessibility accessibility: KeychainItemAccessibility? = nil,
                                              isSynchronizable: Bool = false) -> [String:Any] {

        // Setup default access as generic password (rather than a certificate, internet password, etc).
        var keychainQueryDictionary: [String: Any] = [SecClass: kSecClassGenericPassword]

        // Uniquely identify this keychain accessor.
        keychainQueryDictionary[SecAttrService] = serviceName

        // Only set accessibiilty if its passed in, we don't want to default it here in case the user didn't want it set.
        if let accessibility = accessibility {
            keychainQueryDictionary[SecAttrAccessible] = accessibility.keychainAttrValue
        }

        // Set the keychain access group if defined.
        if let accessGroup = self.accessGroup {
            keychainQueryDictionary[SecAttrAccessGroup] = accessGroup
        }

        // Uniquely identify the account who will be accessing the keychain
        let encodedIdentifier: Data? = key.data(using: String.Encoding.utf8)
        keychainQueryDictionary[SecAttrGeneric] = encodedIdentifier
        keychainQueryDictionary[SecAttrAccount] = encodedIdentifier
        keychainQueryDictionary[SecAttrSynchronizable] = isSynchronizable ? kCFBooleanTrue : kCFBooleanFalse

        return keychainQueryDictionary
    }

    /// Stores the value in the keychain.
    /// - Parameters:
    ///  - value: The value to store.
    ///  - key: The key to store the value under.
    ///  - withAccessibility: Optional accessibility to use when storing the value.
    ///  - isSynchronizable: Optional parameter to store the keychain item as synchronizable or not.
    ///  - Returns: True if the value was successfully stored, otherwise false.
    @discardableResult func set(_ value: String,
                                forKey key: String,
                                withAccessibility accessibility: KeychainItemAccessibility? = nil,
                                isSynchronizable: Bool = false) -> Bool {

        // Verify that the value can be converted to data.
        guard let data = value.data(using: .utf8) else { return false }

        // Get the standard Keychain query dictionary.
        var keychainQueryDictionary: [String: Any] = setupKeychainQueryDictionary(forKey: key,
                                                                                  withAccessibility: accessibility,
                                                                                  isSynchronizable: isSynchronizable)
        // Add the value to store into the dictionary.
        keychainQueryDictionary[SecValueData] = data

        // If an accessibility value exists, add that to the dictionary as well.
        if let accessibility = accessibility {
            keychainQueryDictionary[SecAttrAccessible] = accessibility.keychainAttrValue
        } else {
            // Assign default protection - Protect the keychain entry so it's only valid when the device is unlocked
            keychainQueryDictionary[SecAttrAccessible] = KeychainItemAccessibility.whenUnlocked.keychainAttrValue
        }

        // Attempt to add the value to Keychain, and store it's success.
        let status: OSStatus = SecItemAdd(keychainQueryDictionary as CFDictionary, nil)

        // Check if adding the value was successful.
        if status == errSecSuccess {
            return true
        } else if status == errSecDuplicateItem {
            // Add failed due to the value already existing in Keychain. Attempt to update instead.
            return update(data,
                          forKey: key,
                          withAccessibility: accessibility,
                          isSynchronizable: isSynchronizable)
        } else {
            // Adding to Keychain failed for an unexpected reason.
            return false
        }
    }

    /// Updates the value in the keychain.
    /// - Parameters:
    /// - value: The updated value to store.
    /// - key: The key to update the value of.
    /// - withAccessibility: Optional accessibility to use when updating the value.
    /// - isSynchronizable: Optional parameter to store the keychain item as synchronizable or not.
    /// - Returns: True if the value was successfully updated, otherwise false.
    private func update(_ value: Data,
                        forKey key: String,
                        withAccessibility accessibility: KeychainItemAccessibility? = nil,
                        isSynchronizable: Bool = false) -> Bool {

        var keychainQueryDictionary: [String: Any] = setupKeychainQueryDictionary(forKey: key,
                                                                                  withAccessibility: accessibility,
                                                                                  isSynchronizable: isSynchronizable)
        let updateDictionary = [SecValueData: value]

        // on update, only set accessibility if passed in
        if let accessibility = accessibility {
            keychainQueryDictionary[SecAttrAccessible] = accessibility.keychainAttrValue
        }

        // Update
        let status: OSStatus = SecItemUpdate(keychainQueryDictionary as CFDictionary, updateDictionary as CFDictionary)

        return status == errSecSuccess
    }

    /// Fetches the value for the key provided from the keychain.
    /// - Parameters:
    /// - key: The key to lookup and return the value for.
    /// - withAccessibility: Optional accessibility to use when fetching the value.
    /// - isSynchronizable: Optional parameter to fetch the keychain item as synchronizable or not.
    /// - Returns: The value from the keychain. If no value exists, nil is returned.
    func data(forKey key: String,
              withAccessibility accessibility: KeychainItemAccessibility? = nil,
              isSynchronizable: Bool = false) -> Data? {

        var keychainQueryDictionary = setupKeychainQueryDictionary(forKey: key,
                                                                   withAccessibility: accessibility,
                                                                   isSynchronizable: isSynchronizable)
        // Limit search results to one
        keychainQueryDictionary[SecMatchLimit] = kSecMatchLimitOne

        // Specify we want Data/CFData returned
        keychainQueryDictionary[SecReturnData] = kCFBooleanTrue

        // Search
        var result: AnyObject?
        let status = SecItemCopyMatching(keychainQueryDictionary as CFDictionary, &result)

        return status == noErr ? result as? Data : nil
    }

    /// Fetches the value for the key as a string from the keychain.
    /// - Parameters:
    /// - key: The key to lookup and return the value for.
    /// - withAccessibility: Optional accessibility to use when fetching the value.
    /// - isSynchronizable: Optional parameter to fetch the keychain item as synchronizable or not.
    /// - Returns: The value from the keychain as a string. If no value exists, nil is returned
    func string(forKey key: String,
                withAccessibility accessibility: KeychainItemAccessibility? = nil,
                isSynchronizable: Bool = false) -> String? {

        guard let keychainData = data(forKey: key,
                                      withAccessibility: accessibility,
                                      isSynchronizable: isSynchronizable) else {
            return nil
        }

        return String(data: keychainData, encoding: .utf8) as String?
    }

    /// Removes the value for the key from the keychain.
    /// - Parameters:
    /// - key: The key to remove the value for.
    /// - withAccessibility: Optional accessibility to use when removing the value.
    /// - isSynchronizable: Optional parameter to remove the keychain item as synchronizable or not.
    /// - Returns: True if the value was successfully deleted, otherwise false
    @discardableResult func removeObject(forKey key: String,
                                         withAccessibility accessibility: KeychainItemAccessibility? = nil,
                                         isSynchronizable: Bool = false) -> Bool {

        let keychainQueryDictionary: [String: Any] = setupKeychainQueryDictionary(forKey: key,
                                                                                  withAccessibility: accessibility,
                                                                                  isSynchronizable: isSynchronizable)
        // Delete
        let status: OSStatus = SecItemDelete(keychainQueryDictionary as CFDictionary)

        return status == errSecSuccess
    }
}
