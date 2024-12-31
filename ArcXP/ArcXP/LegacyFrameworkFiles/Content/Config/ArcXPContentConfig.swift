//
//  ArcXPContentConfig.swift
//  ArcXPContent
//
//  Created by Cassandra Balbuena on 1/13/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation

/// Represents the configuration for the ``ArcXPContentClient``.
public struct ArcXPContentConfig {
    /// The name of the organization that the client fetches content for.
    public let organizationName: String

    /// The ArcXP server environment.
    public let serverEnvironment: ServerEnvironment

    /// The site to fetch from (whether multi-site or single)
    public let site: String

    private var _hostDomain: String = ""

    /// Host domain url for the arc feeds to fetch the content data.
    public var hostDomain: String {
        get {
            return _hostDomain.hasPrefix("https") ? _hostDomain : "https://\(_hostDomain)"
        }
        set {
            _hostDomain = newValue
        }
    }

    public init(organizationName: String, serverEnvironment: ServerEnvironment, site: String, hostDomain: String) {
        self.organizationName = organizationName
        self.serverEnvironment = serverEnvironment
        self.site = site
        self._hostDomain = hostDomain
    }
}
