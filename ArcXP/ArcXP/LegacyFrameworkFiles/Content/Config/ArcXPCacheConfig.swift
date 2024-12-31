//
//  ArcXPCacheConfig.swift
//  ArcXPContent
//
//  Created by Mahesh Venkateswarlu on 2/16/22.
//  Copyright © 2022 Arc XP. All rights reserved.
//

import Foundation

/// Represents the configuration for the cache.
public struct ArcXPCacheConfig {
    /// Cache age limit in mins.
    public var cacheTimeUntilUpdate: Double

    /// Cache size in MB
    public var maxCacheSize: Int

    /// A boolean to determine whether the cache should be preloading.
    public var shouldPreloadCache: Bool

    public init(cacheTimeUntilUpdate: Double = 3.0, maxCacheSize: Int = 120, shouldPreloadCache: Bool = true) {
        self.cacheTimeUntilUpdate = cacheTimeUntilUpdate
        self.maxCacheSize = maxCacheSize
        self.shouldPreloadCache = shouldPreloadCache
    }
}
