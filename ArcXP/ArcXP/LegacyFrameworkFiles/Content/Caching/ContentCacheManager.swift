//
//  ContentCacheManager.swift
//  ArcXPContent
//
//  Created by Davis, Tyler on 2/4/22.
//  Copyright © 2022 Arc XP. All rights reserved.
//

import Foundation

/// Manages the caching of content data.
struct ContentCacheManager<Representation: CacheValue> {

    /// The memory cache the ContentCacheManager will manage.
    private let serviceCache: ServiceCache<Representation>?

    init() {
        let clientCacheConfig = ArcXPContentManager.client.cacheConfiguration

        let cacheConfig = CacheConfig(name: "ArcXPContentCache",
                                      location: .applicationSupport,
                                      diskCapacity: clientCacheConfig.maxCacheSize * 1024 * 1024, // cacheSize in MB
                                      ageCapacity: clientCacheConfig.cacheTimeUntilUpdate * 60)                // timeToConsider in sec
        serviceCache = ServiceCache(config: cacheConfig)
    }

    /// Fetch an entry for the given key from the cache.
    /// - Parameters:
    ///  - key: the key for the object to fetch from the cache.
    ///  - completion: the completion handler for the operation.
    func fetchContentFromCache(key: String, completion: @escaping (Failable<ServiceCache<Representation>.EntryValue>) -> Void) {
        if let cache = serviceCache {
            cache.fetch(key: key, result: completion)
        } else {
            completion(.failure(NetworkError.cacheError(reason: .cacheMiss)))
        }
    }

    /// Saves and loads the provided data into the cache with the given key.
    /// - Parameters:
    ///  - contentData:the data to save to the cache.
    ///  - cacheKey: the key to associate with the data saved to the cache.
    func saveContentToCache<T: Codable>(_ contentData: T, key cacheKey: String) {
        if let encoded = try? JSONEncoder().encode(contentData) {
            clearStaleEntriesIfDiskCacheLimitReached()
            serviceCache?.save(key: cacheKey, value: contentData as? Representation, data: encoded, modified: Date())
        }
    }

    /// Removes an item from the cache for the given key.
    /// - Parameters:
    ///  - cacheKey: the key of the cached object to be removed.
    func removeFromCache(cacheKey: String) {
        serviceCache?.remove(key: cacheKey)
    }

    /// Checks if an item should be cached based on the time it was last modified and the current time to consider.
    /// Returns true if it can be cached, false otherwise.
    /// - Returns:true if it can be cached, false otherwise.
    public func shouldAllowCached(lastModified: Date, timeToConsider: Double) -> Bool {
        if TimeInterval.minutes(timeToConsider) > -lastModified.timeIntervalSinceNow {
            return true
        }
        return false
    }

    /// Clears stale entries in the cache if the cache limit has been reached.
    private func clearStaleEntriesIfDiskCacheLimitReached() {
        serviceCache?.trim()
    }

    /// Clears all entries in the cache.
    func clearAllCache(result: ((Failable<Void>) -> Void)? = nil) {
        serviceCache?.clear(result: result)
    }
}
