//
//  TestConstants.swift
//  ArcXPCommerceTests
//
//  Created by David Seitz Jr on 5/3/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation
@testable import ArcXP

/// A collection of constants intended to be used for test data.
struct TestConstant {
    static var mockValidAccessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
    static let mockAccessToken = "MOCK_ACCESS_TOKEN"
    static let mockRefreshToken = "MOCK_REFRESH_TOKEN"
    static let mockUUID = "MOCK_UUID"

    static let expectationTimeout: Double = 10
    static let configurationBaseUrl = "TestBaseURL"
    static let configurationOrganization = "TestOrganization"
    static let configurationSite = "TestSite"
    static let configurationEnvironment = "TestEnvironment"
    static let mockNonce = "nonce"

    // Mock User Values
    static let mockUserFirstName = "Mock"
    static let mockUserLastName = "User"
    static let mockUserSecondLastname = "Second"
    static let mockUserEmail = "mockuser@mock.arcxp.com"
    static let mockBirthDay: Int = 1
    static let mockBirthMonth: Int = 1
    static let mockBirthYear: Int = 2000
    static let mockUsername = "mockuser123"
    static let mockUserPassword = "Test123!"
    static let mockUserDisplayName = "MockUser"
    static let mockGender = UserProfile.Gender.male
    static let mockPictureURL = URL(string: "TestPictureURL")

    static let mockAddress = UserProfile.Address(line1: "TestAddressLine1",
                                                 line2: "TestAddressLine2",
                                                 city: "TestAddressCity",
                                                 type: .other)
    static let mockAddresses = [mockAddress]

    static let mockContact = UserProfile.Contact(phoneNumber: "TestPhoneNumber", type: .other)
    static let mockContacts = [mockContact]

    /// A standard amount of time to wait for tests to complete.
    static let standardTimeout = 15.0

    /// A longer amount of time based on failed Bitrise tests that appeared to only be based on time outs.
    static let longTimeout = 20.0

    // MARK: - Configuration

    // Subscriptions
    static let subscriptionsConfigBaseUrl = "arcsales-arcsales-sandbox.api.cdn.arcpublishing.com"
    static let subscriptionsConfigOrg = "arcsales"
    static let subscriptionsConfigEnv: ServerEnvironment = .sandbox
    static let subscriptionsConfigSite = "arcsales"

    // Content
    static let contentConfigBaseUrl = "arcsales-arcsales-sandbox.web.arc-cdn.net"
    static let contentConfigOrg = "arcsales"
    static let contentConfigEnv: ServerEnvironment = .sandbox
    static let contentConfigSite = "arcsales"
    static let contentCacheConfig: ArcXPCacheConfig = ArcXPCacheConfig(cacheTimeUntilUpdate: 10)

    // Video
    static let videoConfigOrg = "arcsales"
    static let videoConfigEnv: ServerEnvironment = .sandbox
    static let videoConfigUseGeorestrictions = false
}
