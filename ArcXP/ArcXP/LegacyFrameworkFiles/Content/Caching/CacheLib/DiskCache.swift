//
//  DiskCache.swift
//  PostKit
//
//  Created by Vadim Gritsenko on 1/17/17.
//  Copyright © 2017 The Washington Post. All rights reserved.
//

import Foundation

// TODO: Remove this
public typealias Failable<Value> = Result<Value, Error>

public extension Result {

    /// Returns true if the Failable operation succeeded, or False if it failed.
    var successful: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    /// Retrieves the value, if any, from the Failable instance. If the operation failed, returns nil.
    var value: Success? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }

    /// Retrieves the error, if any, from the Failable instance. If the operation succeeded, returns nil.
    var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }

}

public extension Error {

    /// Returns true if this is itself a "file not found" error, or this error was caused
    /// by a "file not found" error.
    var isFileNotFoundError: Bool {
        (self as NSError).isFileNotFoundError
    }

}

public extension NSError {

    /// Returns true if this is itself a "file not found" error, or this error was caused
    /// by a "file not found" error.
    var isFileNotFoundError: Bool {
        if domain == NSCocoaErrorDomain, code == NSFileNoSuchFileError || code == NSFileReadNoSuchFileError {
            return true
        } else if domain == NSPOSIXErrorDomain && code == Int(ENOENT) {
            return true
        }

        if let error = userInfo[NSUnderlyingErrorKey] as? NSError {
            return error.isFileNotFoundError
        }

        return false
    }

    /// Constructs a good ol' NSError with specified domain, error code, and optional
    /// error description string which goes under `NSLocalizedDescriptionKey` key.
    ///
    /// - parameter domain: Error domain string
    /// - parameter code: Error code value, RawRepresentable
    /// - parameter description: Error description string, optional
    convenience init<T>(domain: String, code: T, description: String? = nil) where T: RawRepresentable, T.RawValue == Int {
        self.init(domain: domain, code: code.rawValue, description: description)
    }

    /// Constructs a good ol' NSError with specified domain, error code, and optional
    /// error description string which goes under `NSLocalizedDescriptionKey` key.
    ///
    /// - parameter domain: Error domain string
    /// - parameter code: Error code value, optional, defaults to 0
    /// - parameter description: Error description string, optional
    convenience init(domain: String, code: Int = 0, description: String?) {
        let userInfo: [String: Any]?
        if let description = description {
            userInfo = [NSLocalizedDescriptionKey: description]
        } else {
            userInfo = nil
        }
        self.init(domain: domain, code: code, userInfo: userInfo)
    }

}

/// Disk cache implementation featuring:
///
/// - unlimited key size
/// - multiple reader asynchronous access
/// - single writer asynchronous access
/// - granular access time interval
/// - asynchronous cache index maintenance
///
/// Access time is updated with specified time interval granularity:
/// if it was recently updated, it will not be updated again, thus
/// reducing excessive cache index dirtying when accessing the same
/// resource repeatedly.
///
/// This disk cache should be periodically maintained by calling
/// trim, cleanup, or clear. Trim removes files which are expired
/// and keeps cache size under disk quota. Cleanup ensures there
/// are no unreferenced files (possible if application crashed
/// with dirty cache index), and clear removes all files.
final class DiskCache {

    /// Container for the cache entry metadata which is returned from
    /// `check` and `fetch` functions.
    struct Entry {
        /// Key of the cache entry
        let key: String
        /// Size of the data for this entry in bytes
        let size: Int
        /// Last modification date.
        /// This is date when contents of this entry was last modified.
        let modified: Date
        /// Last verification date.
        /// This is date when contents of this entry was last confirmed to be valid.
        let verified: Date
        /// Last access date.
        /// This is date when contents of this entry was last accessed, modulo
        /// configured access interval value.
        let accessed: Date

        fileprivate init(_ entry: DiskCacheEntry) {
            key = entry.key
            size = entry.size
            modified = entry.modified
            verified = entry.verified
            accessed = entry.accessed
        }
    }

    /// Tuple with entry UUID and entry metadata
    fileprivate typealias UUIDEntry = (uuid: UUID, entry: Entry)

    /// Tuple with cache entry metadata and entry data
    typealias EntryData = (entry: Entry, data: Data)

    /// Cache name, used to construct disk path
    let name: String

    /// Path to the cache on disk
    private let path: URL

    /// Minimum interval for updating access timestamp
    private let accessInterval: TimeInterval

    /// Minimum interval for the cache index flush
    private let flushInterval: TimeInterval

    /// Maximum cache size on disk, as enforced by trim()
    private let diskCapacity: Int

    /// Maximum cache entry age, as enforced by trim()
    private let ageCapacity: TimeInterval

    /// Cache index
    private var index: [String: DiskCacheEntry]

    /// Concurrent cache index access queue
    private let queue: DispatchQueue

    /// Serial number tracking number of index modifications
    private var serial: Int = 0

    /// Flag indicating if cache index is dirty
    private var dirty: Bool = false

    /// Concurrent cache disk access queue
    private let diskQueue: DispatchQueue


    init(config: CacheConfig) {
        name = config.name
        path = config.location.base.appendingPathComponent(name)
        index = [:]

        accessInterval = max(0, config.accessInterval)
        flushInterval = max(0, config.flushInterval)
        diskCapacity = max(0, config.diskCapacity ?? Int.max)
        ageCapacity = max(0, config.ageCapacity ?? Double.greatestFiniteMagnitude)

        queue = DispatchQueue(label: name.appending(".Disk.Index"), attributes: [.concurrent])
        diskQueue = DispatchQueue(label: name.appending(".Disk.IO"), attributes: [.concurrent])

        load()
    }

    /// Loads cache index asynchronously. This function is called exactly once,
    /// on cache initialization.
    private func load() {
        let name = self.name
        let meta = type(of: self)

        queue.async(flags: .barrier) { [weak self, path] in
            self?.index = meta.loadIndex(for: path, name: name)
        }
    }

    /// Checks if entry for the given key exists, and returns it with completion
    /// handler. This function also updates the access timestamp if necessary.
    ///
    /// - parameter key: Entry key
    /// - parameter accessed: If true, updates entry access timestamp. Defaults to true.
    /// - parameter result: Completion handler
    func check(key: String, accessed: Bool = true, result: @escaping (Entry?) -> Void) {
        queue.async { [weak self] in
            self?.checkEntry(key: key, accessed: accessed, result: result)
        }
    }

    /// Loads entry for the given key and returns entry and the data.
    /// This function also updates the access timestamp if necessary.
    ///
    /// - parameter key: Entry key
    /// - parameter accessed: If true, updates entry access timestamp. Defaults to true.
    /// - parameter result: Completion handler
    func fetch(key: String, accessed: Bool = true) -> EntryData? {
        if let tuple = queue.sync(execute: { loadEntry(key: key, accessed: accessed) }),
           let data = readFile(uuid: tuple.uuid, entry: tuple.entry) {
            return EntryData(tuple.entry, data)
        }

        return nil
    }

    /// Loads entry for the given key and returns entry and the data with completion
    /// handler. This function also updates the access timestamp.
    ///
    /// - parameter key: Entry key
    /// - parameter accessed: If true, updates entry access timestamp. Defaults to true.
    /// - parameter result: Completion handler
    func fetch(key: String, accessed: Bool = true, result: @escaping (Failable<EntryData>) -> Void) {
        queue.async { [weak self] in
            self?.loadEntry(key: key, accessed: accessed, result: result)
        }
    }

    /// Updates entry's access timestamp and/or verification timestamp for
    /// the given key.
    ///
    /// - parameter accessed: If true, access timestamp will be updated. Defaults to true.
    /// - parameter verified: If true, both access and verification timestamp will be updated
    /// - parameter key: Entry key
    func touch(key: String, accessed: Bool = true, verified: Bool = false) {
        queue.async { [weak self] in
            self?.checkEntry(key: key, accessed: accessed, verified: verified)
        }
    }

    /// Updates entry's access timestamp and/or verification timestamp for
    /// the set of given keys.
    ///
    /// - parameter accessed: If true, access timestamp will be updated. Defaults to true.
    /// - parameter verified: If true, both access and verification timestamp will be updated
    /// - parameter keys: Entry keys
    func touch<C: Collection>(keys: C, accessed: Bool = true, verified: Bool = false) where C.Element == String {
        queue.async { [weak self] in
            for key in keys {
                self?.checkEntry(key: key, accessed: accessed, verified: verified)
            }
        }
    }

    /// Creates or updates an entry with the given key.
    ///
    /// - parameter key: Entry key
    /// - parameter value: Entry data
    /// - parameter result: Completion handler
    func save(key: String, value: Data, modified: Date, result: ((Failable<Void>) -> Void)? = nil) {
        queue.async(flags: .barrier) { [weak self] in
            self?.saveEntry(key: key, value: value, modified: modified, result: result)
        }
    }

    /// Removes an entry with the given key.
    ///
    /// - parameter key: Entry key
    /// - parameter result: Completion handler
    func remove(key: String, result: ((Failable<Void>) -> Void)? = nil) {
        queue.async(flags: .barrier) { [weak self] in
            self?.removeEntry(key: key, result: result)
        }
    }

    /// Removes all entries with given keys.
    ///
    /// - parameter keys: Entry keys
    /// - parameter result: Completion handler
    func remove<C: Collection>(keys: C, result: ((Failable<Void>) -> Void)? = nil) where C.Element == String {
        var outcome: Failable<Void> = .success(())

        let group: DispatchGroup?
        let next: ((Failable<Void>) -> Void)?
        if result != nil {
            group = DispatchGroup()
            next = { [queue] result in
                queue.async { outcome = !result.successful ? result : outcome }
                group?.leave()
            }
        } else {
            group = nil
            next = nil
        }

        queue.async(flags: .barrier) { [weak self] in
            for key in keys {
                if let self = self {
                    group?.enter()
                    self.removeEntry(key: key, result: next)
                }
            }
        }

        group?.notify(queue: queue) {
            result?(outcome)
        }
    }

    /// Flushes the cache index to disk if it is necessary.
    ///
    /// - parameter result: Completion handler
    func flush(result: ((Failable<Void>) -> Void)? = nil) {
        queue.async(flags: .barrier) { [weak self] in
            self?.flushIfDirty(result: result)
        }
    }

    /// Trims the cache of expired or excess entries as specified by configuration.
    ///
    /// - parameter result: Completion handler
    func trim(result: ((Failable<Void>) -> Void)? = nil) {
        queue.async(flags: .barrier) { [weak self] in
            self?.removeStaleEntries(result: result)
        }
    }

    /// Performs maintenance on the cache directory. Should be periodically invoked
    /// to keep directory contents in sync with cache index.
    ///
    /// - parameter result: Completion handler
    func cleanup(result: ((Failable<Void>) -> Void)? = nil) {
        listAllFiles { [weak self] listResult in
            switch listResult {
            case .success(let list):
                self?.queue.async { [weak self] in
                    self?.removeLostFiles(files: list, result: result)
                }

            case .failure(let error):
                result?(.failure(error))
            }
        }
    }

    /// Removes all entries.
    ///
    /// - parameter result: Completion handler
    func clear(result: ((Failable<Void>) -> Void)? = nil) {
        queue.async(flags: .barrier) { [weak self] in
            self?.removeAllEntries(result: result)
        }
    }

    /// Returns a map of all entries in the cache. This is a synchronous call which can
    /// be used to inspect cache content for debug or reporting purposes.
    ///
    /// - returns: Map of cache entries
    func entries() -> [Entry] {
        var entries: [Entry] = []
        queue.sync {
            entries = self.index.values.map { Entry($0) }
        }
        return entries
    }

    deinit {
        // we could happen to be on the cache index access queue if deinit is called from
        // any of the above function closures' destructors; so can't use methods which
        // synchronize against the queue
        flushIfDirty()
    }

}

private extension CacheLocation {

    var base: URL {
        let directory: FileManager.SearchPathDirectory = self == .applicationSupport ? .applicationSupportDirectory : .cachesDirectory
        let path = NSSearchPathForDirectoriesInDomains(directory, .userDomainMask, true)[0]
        return URL(fileURLWithPath: path, isDirectory: true)
    }
}


// MARK: - Index Access Methods

private extension DiskCache {

    /// Updates entry's accessed or verified timestamp as and if needed. Schedules cache
    /// index flush if entry was modified as a result of this operation.
    ///
    /// If entry update is necessary, it is performed in a barrier block to prevent concurrent
    /// entry modification.
    ///
    /// - parameter entry: Entry to track
    /// - parameter accessed: If true, update entry's last access timestamp, if necessary
    /// - parameter verified: If true, update entry's last verification timestamp
    private func trackEntry(_ entry: DiskCacheEntry, accessed: Bool = true, verified: Bool = false) {
        guard entry.shouldTrack(accessed: accessed, verified: verified, granularity: accessInterval) else {
            return
        }

        queue.async(flags: .barrier) { [weak self, accessInterval] in
            if entry.track(accessed: accessed, verified: verified, granularity: accessInterval) {
                self?.markDirty()
            }
        }
    }

    // concurrent access
    func checkEntry(key: String, accessed: Bool = true, verified: Bool = false) {
        guard let entry = index[key] else {
            return
        }

        trackEntry(entry, accessed: accessed, verified: verified)
    }

    // concurrent access
    func checkEntry(key: String, accessed: Bool = true, verified: Bool = false, result: ((Entry?) -> Void)? = nil) {
        guard let entry = index[key] else {
            if result != nil {
                diskQueue.async {
                    result?(nil)
                }
            }
            return
        }

        trackEntry(entry, accessed: accessed, verified: verified)

        if result != nil {
            let copy = Entry(entry)
            diskQueue.async {
                result?(copy)
            }
        }
    }

    // concurrent access
    func loadEntry(key: String, accessed: Bool = true) -> UUIDEntry? {
        guard let entry = index[key] else {
            return nil
        }

        trackEntry(entry, accessed: accessed)

        return (entry.uuid, Entry(entry))
    }

    // concurrent access
    func loadEntry(key: String, accessed: Bool = true, result: @escaping (Failable<EntryData>) -> Void) {
        guard let entry = index[key] else {
            diskQueue.async {
                result(.failure(CacheError.miss(key: key)))
            }
            return
        }

        trackEntry(entry, accessed: accessed)

        readFile(uuid: entry.uuid, entry: Entry(entry), result: result)
    }

    func saveEntry(key: String, value: Data, modified: Date, result: ((Failable<Void>) -> Void)?) {
        var entry: DiskCacheEntry
        if let temp = index[key] {
            entry = temp
            entry.trackWrite(size: value.count, modified: modified)
        } else {
            entry = DiskCacheEntry(key: key, size: value.count, modified: modified)
            index[key] = entry
        }
        markDirty()
        writeFile(uuid: entry.uuid, data: value, result: result)
    }

    func removeEntry(key: String, result: ((Failable<Void>) -> Void)?) {
        guard let entry = index[key] else {
            return
        }

        index.removeValue(forKey: key)
        markDirty()

        removeFile(uuid: entry.uuid, result: result)
    }

    func removeStaleEntries(result: ((Failable<Void>) -> Void)?) {
        let sorted = index.values.sorted { $0.accessed > $1.accessed }

        var capacity: Int = 0
        var expired: [String] = []

        for entry in sorted {
            if entry.accessed.timeIntervalSinceNow < -ageCapacity {
                expired.append(entry.uuid.uuidString)
                index.removeValue(forKey: entry.key)
                continue
            }

            if capacity >= diskCapacity {
                expired.append(entry.uuid.uuidString)
                index.removeValue(forKey: entry.key)
                continue
            }

            capacity += entry.size
        }

        if !expired.isEmpty {
            markDirty()
        }

        removeFiles(list: expired, result: result)
    }

    // concurrent access
    func removeLostFiles(files: [String], result: ((Failable<Void>) -> Void)?) {
        // filter all files in the cache directory against index
        var lost = Set(files)
        index.values.forEach {
            _ = lost.remove($0.uuid.uuidString)
        }

        // remove all files which are not in the index
        let list = [String](lost)
        removeFiles(list: list, result: result)
    }

    func removeAllEntries(result: ((Failable<Void>) -> Void)?) {
        index.removeAll()
        removeAllFiles(result: result)
    }

    /// Marks the cache index dirty and schedules a flush
    func markDirty() {
        dirty = true
        serial += 1

        // schedule flush at a later time
        let current = serial
        queue.asyncAfter(deadline: .now(), flags: .barrier) { [weak self] in
            if self?.serial == current {
                self?.flushIfDirty()
            }
        }
    }

    /// Flushes the cache index to disk if it has changes
    func flushIfDirty(result: ((Failable<Void>) -> Void)? = nil) {
        guard dirty else {
            if let result = result {
                diskQueue.async {
                    result(.success(()))
                }
            }
            return
        }

        // A thread safe reimplementation of `let index = self.index` statement
        var index: [String: DiskCacheEntry] = [:]
        self.index.forEach { index[$0.key] = DiskCacheEntry($0.value) }
        dirty = false

        saveIndex(index, result: result)
    }

}


// MARK: - Disk Access Methods

private let indexFileName = "Index"

private extension DiskCache {

    static func loadIndex(for path: URL, name: String) -> [String: DiskCacheEntry] {
        let url = path.appendingPathComponent(indexFileName)
        do {
            let data = try Data(contentsOf: url, options: [.uncached])
            let entries = try JSONSerialization.jsonObject(with: data, options: [])

            if let entries = entries as? [Any] {
                var index: [String: DiskCacheEntry] = [:]
                for obj in entries {
                    if let json = obj as? [String: Any], let entry = DiskCacheEntry(json: json) {
                        index[entry.key] = entry
                    }
                }
                return index
            }

            print("\(name): Error loading index")
        } catch {
            if !error.isFileNotFoundError {
                print("\(name): Error loading index")
            }
        }

        return [:]
    }

    func saveIndex(_ index: [String: DiskCacheEntry], result: ((Failable<Void>) -> Void)?) {
        diskQueue.async { [name, path] in
            let url = path.appendingPathComponent(indexFileName)
            let entries = index.map { $0.value.toJSON() }

            do {
                let data = try JSONSerialization.data(withJSONObject: entries, options: [])
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
                try data.write(to: url, options: [.atomic])
                result?(.success(()))
            } catch {
                print("\(name): Error saving index")
                result?(.failure(error))
            }
        }
    }

    func readFile(uuid: UUID, entry: Entry) -> Data? {
        let item = uuid.uuidString
        let url = path.appendingPathComponent(item)

        do {
            return try Data(contentsOf: url, options: [.uncached])
        } catch {
            if !error.isFileNotFoundError {
                print("\(name): Error reading entry")
            }
            return nil
        }
    }

    func readFile(uuid: UUID, entry: Entry, result: @escaping (Failable<EntryData>) -> Void) {
        diskQueue.async { [name, path] in
            let item = uuid.uuidString
            let url = path.appendingPathComponent(item)

            var data: Data
            do {
                data = try Data(contentsOf: url, options: [.uncached])
                result(.success(EntryData(entry, data)))
            } catch {
                if !error.isFileNotFoundError {
                    print("\(name): Error reading entry")
                }
                result(.failure(CacheError.access(key: item, reason: error)))
            }
        }
    }

    func writeFile(uuid: UUID, data: Data, result: ((Failable<Void>) -> Void)?) {
        diskQueue.async { [name, path] in
            let item = uuid.uuidString
            let url = path.appendingPathComponent(item)

            do {
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
                try data.write(to: url, options: [.atomic])
                result?(.success(()))
            } catch {
                print("\(name): Error writing entry")
                result?(.failure(CacheError.access(key: item, reason: error)))
            }
        }
    }

    func removeFile(uuid: UUID, result: ((Failable<Void>) -> Void)?) {
        diskQueue.async { [name, path] in
            let item = uuid.uuidString
            let url = path.appendingPathComponent(item)
            // Change made to Lib
            // If result callback is nil, we still want to remove the cache file
            if let result = result {
                result(DiskCache.removeFile(name: name, url: url))
            } else {
                let _ = DiskCache.removeFile(name: name, url: url)
            }
        }
    }

    func removeFiles(list: [String], result: ((Failable<Void>) -> Void)?) {
        guard !list.isEmpty else {
            result?(.success(()))
            return
        }

        diskQueue.async { [name, path] in
            var r: Failable<Void> = .success(())

            for item in list {
                let url = path.appendingPathComponent(item)

                if let error = DiskCache.removeFile(name: name, url: url).error {
                    r = .failure(CacheError.access(key: item, reason: error))
                }
            }

            result?(r)
        }
    }

    func listAllFiles(result: @escaping (Failable<[String]>) -> Void) {
        diskQueue.async { [name, path] in
            var contents: [String] = []

            do {
                contents = try FileManager.default.contentsOfDirectory(atPath: path.path)
                if let index = contents.firstIndex(of: indexFileName) {
                    contents.remove(at: index)
                }
            } catch {
                if !error.isFileNotFoundError {
                    print("\(name): Error listing files")
                    result(.failure(CacheError.access(key: "", reason: error)))
                    return
                }
            }

            result(.success(contents))
        }
    }

    func removeAllFiles(result: ((Failable<Void>) -> Void)?) {
        diskQueue.async(flags: .barrier) { [name, path] in
            do {
                try FileManager.default.removeItem(at: path)
            } catch {
                if !error.isFileNotFoundError {
                    print("\(name): Error clearing cache")
                    result?(.failure(error))
                    return
                }
            }

            result?(.success(()))
        }
    }

    static func removeFile(name: String, url: URL) -> Failable<Void> {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            if !error.isFileNotFoundError {
                print("\(name): Error removing entry")
                return .failure(error)
            }
        }

        return .success(())
    }

}


// MARK: - DiskCacheEntry

///
/// Internal disk cache entry object persisted in the disk cache index.
/// - maps entry key to the file name
/// - keeps track of entry size and access timestamp
///
private final class DiskCacheEntry: Encodable, Decodable {

    // NOTE: The current JSON format is `Codable` compatible
    private struct Keys {
        static let key = "key"
        static let uuid = "uuid"
        static let size = "size"
        static let modified = "modified"
        static let verified = "verified"
        static let accessed = "accessed"
    }

    /// Unique key of this entry
    let key: String
    let uuid: UUID

    /// Size of the cache entry in bytes
    private(set) var size: Int

    /// Date this entry was last modified with new data
    private(set) var modified: Date

    /// Date this entry was last verified to have latest data
    private(set) var verified: Date

    /// Date this entry was last accessed, modulo granularity
    private(set) var accessed: Date


    init(key: String, size: Int, modified: Date) {
        let now = Date()

        self.key = key
        self.uuid = UUID()
        self.size = size
        self.modified = modified
        self.verified = now
        self.accessed = now
    }

    init(_ other: DiskCacheEntry) {
        self.key = other.key
        self.uuid = other.uuid
        self.size = other.size
        self.modified = other.modified
        self.verified = other.verified
        self.accessed = other.accessed
    }

    init?(json: [String: Any]) {
        guard let key: String = json[Keys.key] as? String,
              let uuidString: String = json[Keys.uuid] as? String,
              let uuid = UUID(uuidString: uuidString),
              let modified: Double = json[Keys.modified] as? TimeInterval,
              let accessed: Double = json[Keys.accessed] as? TimeInterval else {
            return nil
        }

        let verified = (json[Keys.verified] as? TimeInterval) ?? modified

        self.key = key
        self.uuid = uuid
        self.size = (json[Keys.size] as? Int) ?? 0
        self.modified = Date(timeIntervalSince1970: modified)
        self.verified = Date(timeIntervalSince1970: verified)
        self.accessed = Date(timeIntervalSince1970: accessed)
    }

    func toJSON() -> [String: Any] {
        return [
            Keys.key: key,
            Keys.uuid: uuid.uuidString,
            Keys.size: size,
            Keys.modified: modified.timeIntervalSince1970,
            Keys.verified: verified.timeIntervalSince1970,
            Keys.accessed: accessed.timeIntervalSince1970
        ]
    }

    /// Checks if entry's access or verification timestamps should be updated
    ///
    /// - parameter accessed: If true, check if access timestamp should be updated
    /// - parameter verified: If true, check if verification timestamp should be updated
    /// - parameter granularity: access time granularity
    /// - returns: true if any of the timestamps should be updated
    func shouldTrack(accessed: Bool, verified: Bool, granularity: TimeInterval) -> Bool {
        if verified {
            return true
        } else if accessed {
            return self.accessed.timeIntervalSinceNow < -granularity
        }
        return false
    }

    /// Tracks cache entry reads or verifications by updating corresponding timestamps.
    ///
    /// - parameter granularity: access time granularity
    /// - returns: true if any of the timestamps has been updated
    func track(accessed: Bool, verified: Bool, granularity: TimeInterval) -> Bool {
        if verified {
            return trackVerify()
        } else if accessed {
            return trackRead(granularity: granularity)
        }
        return false
    }

    /// Tracks cache entry reads by updating last access timestamp
    /// with specified granularity: series of frequent accesses will
    /// bump the timestamp just once.
    ///
    /// - parameter granularity: access time granularity
    /// - returns: true if access time was updated
    private func trackRead(granularity: TimeInterval) -> Bool {
        if accessed.timeIntervalSinceNow < -granularity {
            accessed = Date()
            return true
        }

        return false
    }

    /// Tracks cache entry verifications. Sets verified and accessed to the
    /// current time.
    private func trackVerify() -> Bool {
        let now = Date()
        verified = now
        accessed = now
        return true
    }

    /// Tracks cache entry writes. Updates modified timestamp with provided
    /// value, as well sets verified and accessed to the current time.
    ///
    /// - parameter size: size of the updated entry data
    func trackWrite(size newSize: Int, modified newModified: Date) {
        let now = Date()
        size = newSize
        modified = newModified
        verified = now
        accessed = now
    }

}
