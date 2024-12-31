//
//  ServiceCache.swift
//  PostKit
//
//  Created by Vadim Gritsenko on 1/11/17.
//  Copyright © 2017 The Washington Post. All rights reserved.
//

import Foundation


///
/// Two level generic cache for PostKit services:
///  - Memory cache backed by NSCache,
///  - Disk cache backed by DiskCache.
///
public class ServiceCache<T: CacheValue> {

    /// Container for the cache entry metadata which is returned from
    /// `check` and `fetch` functions.
    public struct Entry {
        public let key: String
        public let size: Int
        public let modified: Date
        public let verified: Date
        public let accessed: Date

        fileprivate init?(_ entry: DiskCache.Entry?) {
            guard let entry = entry else {
                return nil
            }

            self.init(entry)
        }

        fileprivate init(_ entry: DiskCache.Entry) {
            key = entry.key
            size = entry.size
            modified = entry.modified
            verified = entry.verified
            accessed = entry.accessed
        }

        fileprivate init(_ entry: ServiceCacheEntry<T>) {
            key = entry.key
            size = entry.size
            modified = entry.modified
            verified = entry.verified
            accessed = entry.accessed
        }
    }

    /// Tuple with cache entry metadata and value object
    public typealias EntryValue = (entry: Entry, value: T)

    /// Name of the cache
    public let name: String

    private let memoryCache: NSCache<AnyObject, ServiceCacheEntry<T>>
    private let diskCache: DiskCache


    public init(config: CacheConfig) {
        name = config.name

        memoryCache = NSCache<AnyObject, ServiceCacheEntry<T>>()
        if let cost = config.memoryCapacity {
            memoryCache.totalCostLimit = cost
        }

        diskCache = DiskCache(config: config)
    }

    /// Check if cache contains an entry for the given key.
    ///
    /// If entry is present in the in-memory cache, this function calls result handler
    /// synchronously on the calling thread. Otherwise, handler is called asynchronously
    /// on a background thread.
    ///
    /// - parameter key: entry key
    /// - parameter hint: cache value hint
    /// - parameter result: completion handler
    public func check(key: String, hint: T.Hint = [], result: @escaping (Entry?) -> Void) {
        let accessed = !hint.contains(T.Hint.untouched)
        if let entry = memoryCache.object(forKey: key as NSString) {
            if accessed {
                entry.touch()
                diskCache.touch(key: key)
            }
            result(Entry(entry))
            return
        }

        diskCache.check(key: key, accessed: accessed) { entry in
            result(Entry(entry))
        }
    }

    /// Convert EntryData loaded from disk into EntryValue returned from fetch.
    /// This also updates memoryCache and diskCache on success and failure, as appropriate,
    /// unless the cache hints indicate otherwise.
    ///
    /// - parameter key: entry key
    /// - parameter hint: cache value hint
    /// - parameter entryData: entry metadata and data tuple from disk cache
    private func convert(key: String, hint: T.Hint, entryData: DiskCache.EntryData) -> EntryValue? {
        if let value = T.value(from: entryData.data, hint: hint) {
            let entry = ServiceCacheEntry(entryData.entry, value)
            if !hint.contains(T.Hint.uncached) {
                let cost = value.cost(with: entryData.data)
                memoryCache.setObject(entry, forKey: key as NSString, cost: cost)
            }
            return (Entry(entry), value)
        }

        diskCache.remove(key: key)
        return nil
    }

    /// Fetch an entry for the given key.
    ///
    /// - parameter key: entry key
    /// - parameter hint: cache value hint
    public func fetch(key: String, hint: T.Hint = []) -> EntryValue? {
        let accessed = !hint.contains(T.Hint.untouched)
        if let entry = memoryCache.object(forKey: key as NSString) {
            if accessed {
                entry.touch()
                diskCache.touch(key: key)
            }
            return (Entry(entry), entry.value)
        }

        if let entryData = diskCache.fetch(key: key, accessed: accessed) {
            return convert(key: key, hint: hint, entryData: entryData)
        }

        return nil
    }

    /// Fetch an entry for the given key.
    ///
    /// If entry is present in the in-memory cache, this function calls result handler
    /// synchronously on the calling thread. Otherwise, handler is called asynchronously
    /// on a background thread.
    ///
    /// - parameter key: entry key
    /// - parameter hint: cache value hint
    /// - parameter result: completion handler
    public func fetch(key: String, hint: T.Hint = [], result handler: @escaping (Failable<EntryValue>) -> Void) {
        let accessed = !hint.contains(T.Hint.untouched)
        if let entry = memoryCache.object(forKey: key as NSString) {
            if accessed {
                entry.touch()
                diskCache.touch(key: key)
            }
            handler(.success((Entry(entry), entry.value)))
            return
        }

        diskCache.fetch(key: key, accessed: accessed) { [weak self] result in
            switch result {
            case .success(let entryData):
                if let entryValue = self?.convert(key: key, hint: hint, entryData: entryData) {
                    handler(.success(entryValue))
                } else {
                    handler(.failure(CacheError.serialization(key: key)))
                }
            case .failure(let error):
                handler(.failure(error))
            }
        }
    }

    /// Update entry's access/verification timestamps for the given key.
    ///
    /// - parameter key: entry key
    public func touch(key: String, accessed: Bool = true, verified: Bool = false) {
        if let entry = memoryCache.object(forKey: key as NSString) {
            entry.touch(accessed: accessed, verified: verified)
        }

        diskCache.touch(key: key, accessed: accessed, verified: verified)
    }

    /// Update entry's access/verification timestamps for the set of given keys.
    ///
    /// - parameter keys: entry keys
    public func touch<C: Collection>(keys: C, accessed: Bool = true, verified: Bool = false) where C.Element == String {
        for key in keys {
            if let entry = memoryCache.object(forKey: key as NSString) {
                entry.touch(accessed: accessed, verified: verified)
            }
        }

        diskCache.touch(keys: keys, accessed: accessed, verified: verified)
    }

    /// Save an entry for the given key. Either value, or data, or both
    /// arguments should be specified.
    ///
    /// - parameter key: entry key
    /// - parameter value: optional value stored in the in-memory cache
    /// - parameter data: optional data stored in the disk cache
    public func save(key: String, value: T? = nil, data: Data? = nil, modified: Date = .distantPast) {
        if let value = value {
            let cost = value.cost(with: data)
            let entry = ServiceCacheEntry(key: key, size: data?.count ?? 0, value: value, modified: modified)
            memoryCache.setObject(entry, forKey: key as NSString, cost: cost)
        }

        if let data = data {
            diskCache.save(key: key, value: data, modified: modified)
        }
    }

    /// Remove an entry for the given key.
    ///
    /// - parameter key: entry key to remove
    public func remove(key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        diskCache.remove(key: key)
    }

    /// Remove entries for the given collection of keys.
    ///
    /// - parameter keys: entry keys to remove
    public func remove<C: Collection>(keys: C) where C.Element == String {
        for key in keys {
            memoryCache.removeObject(forKey: key as NSString)
        }

        diskCache.remove(keys: keys)
    }

    /// Flushes disk cache index to disk. It is a good idea to call this
    /// function just before application is suspended.
    public func flush(result: ((Failable<Void>) -> Void)? = nil) {
        diskCache.flush(result: result)
    }

    /// Trims cache down according to cache configuration and performs
    /// cache directory consistency checks.
    ///
    /// - parameter result: completion handler
    public func trim(result: ((Failable<Void>) -> Void)? = nil) {
        diskCache.trim { [diskCache] trimResult in
            switch trimResult {
            case .success:
                diskCache.cleanup(result: result)
            case .failure:
                result?(trimResult)
            }
        }
    }

    /// Clears cache of all data.
    ///
    /// - parameter result: completion handler
    public func clear(result: ((Failable<Void>) -> Void)? = nil) {
        memoryCache.removeAllObjects()
        diskCache.clear(result: result)
    }

    /// Returns the list of entries in the disk cache. This is a synchronous call
    /// which can be used to inspect cache content for debug or reporting purposes.
    public func entries() -> [Entry] {
        return diskCache.entries().map { Entry($0) }
    }

    #if DEBUG
    /// There is no unfortunately no API to inspect contents of the `NSCache` object. This
    /// function provides best effort approximation of number of entries stored in `NSCache`,
    /// and, additionally, it prints number of entries stored on disk and total number of bytes.
    public func report() {
        var size = 0
        let diskKeys: [String] = diskCache.entries().map { size += $0.size; return $0.key }
        let memKeys: [String] = diskKeys.filter { memoryCache.object(forKey: $0 as NSString) != nil }
        print(memKeys)
    }
    #endif

}


// MARK: - ServiceCacheEntry

///
/// Internal service cache entry object for the memory cache.
/// - keeps track of the entry meta data
/// - keeps reference to the entry value
///
private final class ServiceCacheEntry<T: CacheValue>: NSObject {

    /// Unique key of this entry
    let key: String

    /// Size of the cache entry in bytes
    let size: Int

    /// Date this entry was last written to
    private(set) var modified: Date

    /// Date this entry was last written to
    private(set) var verified: Date

    /// Date this entry was last read from
    private(set) var accessed: Date

    /// The value object
    let value: T


    init(key: String, size: Int, value: T, modified: Date) {
        self.key = key
        self.size = size
        self.modified = modified
        verified = Date()
        accessed = Date()
        self.value = value
    }

    init(_ entry: DiskCache.Entry, _ value: T) {
        key = entry.key
        size = entry.size
        modified = entry.modified
        verified = entry.verified
        accessed = entry.accessed
        self.value = value
    }

    func touch(accessed: Bool = true, verified: Bool = false, modified: Date? = nil) {
        let now = Date()
        if accessed || verified {
            self.accessed = now
        }
        if verified {
            self.verified = now
        }
        if let modified = modified {
            self.modified = modified
        }
    }

}
