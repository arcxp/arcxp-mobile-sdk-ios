//
//  LoginManager.swift
//  Commerce
//
//  Created by Seitz, David on 7/31/20.
//  Copyright © 2020 The Washington Post Company. All rights reserved.
//

public typealias UserResult = Result<UserProfile, Error>
public typealias UserCompletion = ((UserResult) -> Void)
public typealias ServiceCompletion = ((Result<Void, Error>) -> Void)

import Foundation

/// Handles values and operations related to Arc XP Subscriptions API's.
@available(iOS 13.0, *)
public class Subscriptions: NSObject {

    /// Determines which version of the Subscriptions web API should be accessed. For example: `"baseUrl/sales/public/v1/entitlements"` or `"baseUrl/sales/public/v2/entitlements"`
    enum WebAPIVersion: String { case v1, v2 }
    static var salesWebAPIVersion: WebAPIVersion = .v1
    static var retailWebAPIVersion: WebAPIVersion = .v1

// swiftlint: disable identifier_name
    public struct Identity {

        /// Returns any existing user profile updates that are waiting to be committed.
        static var queuedUserProfileUpdates = [String: Encodable]()

        /// The local persistence of the access token
        static var _accessToken: String?

        /// The local persistence of the refresh token
        static var _refreshToken: String?

        /// A convenient way to access a saved user access token. If this token isn't available, the user will need to sign in to provide an access token.
        static var accessToken: String? {
            get {
                if TestConstant.useTestValue {
                    return TestConstant.testAccessToken
                }
                return _accessToken ?? storedAccessToken
            }
            set {
                _accessToken = newValue
                if rememberMe {
                    storedAccessToken = _accessToken
                }
            }
        }

        /// A token required to extend the user session by updating the accessToken
        static var refreshToken: String? {
            get {
                return _refreshToken ?? storedRefreshToken
            }
            set {
                _refreshToken = newValue
                if rememberMe {
                    storedRefreshToken = _refreshToken
                }
            }
        }

        /// The cached access token, if one exists.
        static var storedAccessToken: String? {
            get {
                guard let token = CacheManager.getValue(forKey: .accessTokenKey) as? String else { return nil }
                return token
            }
            set {
                CacheManager.set(value: newValue, forKey: .accessTokenKey)
            }
        }

        /// The cached refresh token, if one exists.
        static var storedRefreshToken: String? {
            get {
                guard let token = CacheManager.getValue(forKey: .refreshTokenKey) as? String else { return nil }
                return token
            }
            set {
                CacheManager.set(value: newValue, forKey: .refreshTokenKey)
            }
        }

        struct TestConstant {
            static var useTestValue = false
            static var testAccessToken: String?
        }
    }
// swiftlint: enable identifier_name
    // MARK: - Properties

    /// Determines whether or not there should be an attempt to refresh the user's login session.
    static var rememberMe: Bool {
        get {
            guard let value = CacheManager.getValue(forKey: .rememberMeKey) as? Bool else {
                return false
            }
            return value
        }
        set {
            CacheManager.set(value: newValue, forKey: .rememberMeKey)
        }
    }

    /// The most recently fetched user profile. For the most up to date user profile, call `Commerce.Identity.fetchUserProfile(completion:)`.
    public static var cachedUserProfile: UserProfile?

    /// The configuration for the application. It's either the staging configuration or a provided one.
    static var configuration: ArcXPSubscriptionsConfiguration {
        guard let configuration = clientConfiguration else {
            fatalError("Arc Commerce - Configuration details are required. Please call `Commerce.setUp(configuration:)` to provide configuration details.")
        }
        return configuration
    }

    /// Configuration data, detailing backend details for where to fetch Commerce data from.
    private static var clientConfiguration: ArcXPSubscriptionsConfiguration?

    /// Various settings for use by front-end apps and SDK, known as the tenant configuration.
    public static var configOptions: ConfigOptions?
    // swiftlint: disable nesting
    struct Mock {
        enum Result: String { case success, failure }
        enum WebAPIVersion: String { case v1, v2 }
        var result: Result = .success
        var version: WebAPIVersion = .v1
        /// When set to `true`, local mock network responses will be returned.
        var mockNetworkResponseEnabled = false
    }
    // swiftlint: enable nesting

    /// The mock property used for testing purposes.
    static var mock: Mock = Mock()

    // MARK: - Commerce Setup

    /// Sets up the Commerce SDK with necessary configuration details.
    /// - Parameters:
    ///     - configuration: Configuration data which the Commerce SDK will use to reach a Commerce backend.
    static func setUp(configuration: ArcXPSubscriptionsConfiguration) {
        self.clientConfiguration = configuration
        PaywallManager.setup()
    }

    /// Reports whether a user's details have been saved after logging in.
    /// - parameter completion: Reports when finished checking if logged in, including a boolean determining whether logged in or not.
    public static func isLoggedIn(completion: @escaping (Bool) -> Void) {
        if let accessToken = Identity.accessToken,
           Identity.validateAccessToken(accessToken: accessToken) {
            return completion(true)
        } else if rememberMe {
            Identity.extendUserSession { result in
                switch result {
                case .success:
                    return completion(true)
                case .failure(_):
                    return completion(false)
                }
            }
        } else {
            logOut()
            return completion(false)
        }
    }

    // MARK: - Commerce Registration and Login

    /// Log the user out, and clear all user account details.
    public static func logOut() {
        rememberMe = false
        cachedUserProfile = nil
        configOptions = nil
        Identity.accessToken = nil
        Identity.refreshToken = nil
        Identity.storedAccessToken = nil
        Identity.storedRefreshToken = nil
        Identity.queuedUserProfileUpdates.removeAll()
    }

    public struct Retail {
        public static func getPaywallRules(completion: @escaping (Result<[PaywallRule], Error>) -> Void) {
            let endpoint = RetailEndpoint.paywall
            NetworkManager.requestForCodable(from: endpoint, completion: completion)
        }
    }

    public struct Sales {
        public static func getAllSubscriptions(completion: @escaping (Result<SubscriptionsResponse, Error>) -> Void) {
            let endpoint = SalesEndpoint.allSubscriptions
            NetworkManager.requestForCodable(from: endpoint, completion: completion)
        }

        public static func getAllActiveSubscriptions(completion: @escaping (Result<SubscriptionsResponse, Error>) -> Void) {
            let endpoint = SalesEndpoint.allActiveSubscriptions
            NetworkManager.requestForCodable(from: endpoint, completion: completion)
        }

        public static func fetchEntitlements(completion: @escaping (Result<EntitlementsResponse, Error>) -> Void) {
            let endpoint = SalesEndpoint.entitlements
            NetworkManager.requestForCodable(from: endpoint, completion: completion)
        }
    }
}
