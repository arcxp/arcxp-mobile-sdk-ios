//
//  ArcConfiguration.swift
//  Commerce
//
//  Created by Seitz, David on 4/7/2022.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation

/// Configuration details describing where to get the resources required by this Commerce mobile SDK.
struct ArcXPSubscriptionsConfiguration {

    private var _hostDomain: String = ""
    /// The base URL for the backend resources that this Commerce iOS SDK is supported by.
    /// Note that while this base URL used to be constructed via organization, site, and environment parameters,
    /// variations in base URL structures has made it necessary to provide specific base URLs.

    public var baseUrl: String {
            return _hostDomain.hasPrefix("https") ? _hostDomain : "https://\(_hostDomain)"
    }

    public var organization: String
    public var site: String
    public var environment: String

    public init(baseUrl: String, organization: String, site: String, environment: String) {
        // Note: This initializer needs to be made explicit because of internal restrictions if not done so.
        self._hostDomain = baseUrl
        self.organization = organization
        self.site = site
        self.environment = environment
    }
}
