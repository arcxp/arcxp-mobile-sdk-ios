//
//  ArcXPContentManager.swift
//  ArcXPContent
//
//  Created by Cassandra Balbuena on 1/12/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation

/// The type for content IDs requested from ArcXP feeds.
public typealias ArcXPContentID = String

/// The `Result` type with ``ArcXPContent``as the successful associated type that's passed into an
/// ``ArcXPStoryResultHandler`` block.
public typealias ArcXPStoryResult = Result<ArcXPContent, Error>

/// A type of handler used for  ``ArcXPStoryResult``s  that's passed to an ``ArcXPContentClient`` function.
public typealias ArcXPStoryResultHandler = (ArcXPStoryResult) -> Void

/// The `Result` type with ``ArcXPContentList`` as the successful associated type that's passed into an
/// ``ArcXPCollectionResultHandler`` block.
public typealias ArcXPCollectionResult = Result<ArcXPContentList, Error>

/// A type of handler used for ``ArcXPCollectionResult``s that's passed to an ``ArcXPContentClient`` function.
public typealias ArcXPCollectionResultHandler = (ArcXPCollectionResult) -> Void

/// The `Result` type with ``SectionList`` as the successful associated type that's passed into an
/// ``ArcXPSectionListHandler`` block.
public typealias ArcXPSectionListResult = Result<SectionList, Error>

/// A type of handler used for ``ArcXPSectionListResult``s that's passed to an ``ArcXPContentClient`` function.
public typealias ArcXPSectionListHandler = (ArcXPSectionListResult) -> Void

/// Holds a static property that points to a singleton ``ArcContentClient``
/// instance that will be used throughout the app.
public struct ArcXPContentManager {
    /// The singleton instance of the ``ArcContentClient``.
    public static var client = ArcXPContentClient()

    /// Sets up the ``ArcXPContentManager`` with the provided configurations.
    /// - Parameters:
    ///    - config: The configuration for the ``client``.
    ///    - cacheConfig: The configuration for the cache.
    public static func setUp(configuration config: ArcXPContentConfig, cacheConfig: ArcXPCacheConfig? = nil) {
        self.client.configuration = config
        if let cacheConfig = cacheConfig {
            self.client.cacheConfiguration = cacheConfig
        }
    }
}
