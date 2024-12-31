//
//  ArcXPService.swift
//  ArcXP
//
//  Created by David Seitz Jr on 2/23/23.
//  Copyright © 2023 The Washington Post Company. All rights reserved.
//

import Foundation

/// The ArcXP server environment. For most partners, this will be either
/// ``production`` or ``sandbox``. Some partners don't use separate environments,
/// so they should use ``none`` instead.
public enum ServerEnvironment: String {

    /// When there's no need to specify a server environment.
    case none

    /// The production server environment.
    case production = "prod"

    /// The sandbox server environment, usually reserved for testing.
    case sandbox
}

// MARK: - Configuration Types
public struct ArcXPConfig {
    public let organization: String
    public let environment: ServerEnvironment
    public let site: String
}

/// The configuration for the subscriptions service.
public struct SubscriptionsConfiguration {
    public let baseUrl: String
    public let organization: String
    public let environment: ServerEnvironment
    public let site: String

    public init(baseUrl: String, organization: String, environment: ServerEnvironment, site: String) {
        self.baseUrl = baseUrl
        self.organization = organization
        self.environment = environment
        self.site = site
    }
}

/// The configuration for the content service.
public struct ContentConfiguration {
    public let baseUrl: String
    public let organization: String
    public let environment: ServerEnvironment
    public let site: String
    public let cacheConfiguration: ArcXPCacheConfig?

    public init(baseUrl: String, organization: String, environment: ServerEnvironment, site: String, cacheConfiguration: ArcXPCacheConfig?) {
        self.baseUrl = baseUrl
        self.organization = organization
        self.environment = environment
        self.site = site
        self.cacheConfiguration = cacheConfiguration
    }
}

/// The configuration for the video service.
public struct VideoConfiguration {
    public let organization: String
    public let environment: ServerEnvironment
    public var enableLivestreamAds: Bool?
    public let useGeorestrictions: Bool?

    public init(organization: String, environment: ServerEnvironment, enableLivestreamAds: Bool? = nil, useGeorestrictions: Bool?) {
        self.organization = organization
        self.environment = environment
        self.enableLivestreamAds = enableLivestreamAds
        self.useGeorestrictions = useGeorestrictions
    }
}

// MARK: - ArcXPService

/// Contains information about a specific service provided by Arc XP.
public enum ArcXPService {
    case subscriptions(_ configuration: SubscriptionsConfiguration)
    case content(_ configuration: ContentConfiguration)
    case video(_ configuration: VideoConfiguration)
}
