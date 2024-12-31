//
//  KeychainManagerTests.swift
//  ArcXPTests
//
//  Created by David Seitz on 1/25/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class KeychainManagerTests: XCTestCase {

    private let testKey = "TestKey"
    private let testValue = "TestValue"

    func testEnumCases() {
        XCTAssertNotNil(KeychainItemAccessibility.afterFirstUnlock, "afterFirstUnlock should be instantiable")
        XCTAssertNotNil(KeychainItemAccessibility.afterFirstUnlockThisDeviceOnly, "afterFirstUnlockThisDeviceOnly should be instantiable")
        XCTAssertNotNil(KeychainItemAccessibility.always, "always should be instantiable")
        XCTAssertNotNil(KeychainItemAccessibility.whenPasscodeSetThisDeviceOnly, "whenPasscodeSetThisDeviceOnly should be instantiable")
        XCTAssertNotNil(KeychainItemAccessibility.alwaysThisDeviceOnly, "alwaysThisDeviceOnly should be instantiable")
        XCTAssertNotNil(KeychainItemAccessibility.whenUnlocked, "whenUnlocked should be instantiable")
        XCTAssertNotNil(KeychainItemAccessibility.whenUnlockedThisDeviceOnly, "whenUnlockedThisDeviceOnly should be instantiable")
    }

    func testAccessibilityForAttributeValue() {
        for (key, value) in keychainItemAccessibilityLookup {
            XCTAssertEqual(KeychainItemAccessibility.accessibilityForAttributeValue(value), key)
        }

        let nonMatchingValue: CFString = "nonMatchingValue" as CFString
        XCTAssertNil(KeychainItemAccessibility.accessibilityForAttributeValue(nonMatchingValue))
    }
}
