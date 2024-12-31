//
//  Services.swift
//  ArcXP
//
//  Created by David Seitz Jr on 2/23/23.
//  Copyright © 2023 The Washington Post Company. All rights reserved.
//

import UIKit

/// An interface for the setup of ArcXP services..
public struct Services {

    /// Configure a specific Arc XP service with your specific backend details.
    /// Note that the configuration parameter should be a specific configuration type, based on the service you'd like to configure.
    /// - parameter service: The specific Arc XP service you'd like the configure.
    /// - parameter configuration: The configuration details for the service you'd like to set up.
    public static func configure(service: ArcXPService) {
        switch service {
        case .subscriptions(let config):
            Subscriptions.setUp(configuration: ArcXPSubscriptionsConfiguration(baseUrl: config.baseUrl,
                                                                               organization: config.organization,
                                                                               site: config.site,
                                                                               environment: config.environment.rawValue))
        case .content(let config):
            ArcXPContentManager.setUp(configuration: ArcXPContentConfig(organizationName: config.organization,
                                                               serverEnvironment: config.environment,
                                                               site: config.site,
                                                               hostDomain: config.baseUrl),
                                      cacheConfig: config.cacheConfiguration)
        case .video(let config):
            ArcMediaClientManager.client = ArcMediaRealClient(organizationID: config.organization,
                                                              serverEnvironment: config.environment,
                                                              enableLivestreamAds: config.enableLivestreamAds ?? false)
        }
    }
}
