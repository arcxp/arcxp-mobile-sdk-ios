//
//  CacheConfig.swift
//  PostKit
//
//  Created by Vadim Gritsenko on 1/17/17.
//  Copyright © 2017 The Washington Post. All rights reserved.
//

import Foundation


/// Cache directory location options.
///
/// Cache can be stored either in `Caches` directory, or in the `Application Support`
/// directory. Apple used to have documentation about file system use, but it is no
/// longer available. Parts of it are reproduced below.
///
/// **Determining Where to Store Your App-Specific Files**
///
/// The `Library` directory is the designated repository for files your app creates
/// and manages on behalf of the user.
///
///  - Use the `Application Support` directory for:
///    - Resource and data files that your app creates and manages for the user. You
///      might use this directory to store app state information, computed or downloaded
///      data, or even user created data that you manage on behalf of the user.
///    - Autosave files.
///  - Use the `Caches` directory for cached data files or any files that your app can
///    re-create easily.
///  - Read and write preferences using the `UserDefaults` class. This class automatically
///    writes preferences to the appropriate location.
///
/// https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/AccessingFilesandDirectories/AccessingFilesandDirectories.html#//apple_ref/doc/uid/TP40010672-CH3-SW11
public enum CacheLocation {
    /// Default option with chance of data removal
    case cache
    /// Location for essential data that will not be removed
    case applicationSupport
}


/// Cache Configuration.
///
/// When specifying cache configuration, it is always a good idea to specify
/// limits on cache size or maximum age of the items in the cache. At the very
/// least, either `diskCapacity` or `ageCapacity` should be speficied.
public struct CacheConfig {

    /// Cache name. Used to construct cache disk path.
    let name: String

    /// Location of Cache Directory
    let location: CacheLocation

    /// Memory capacity in bytes. Nil for unbounded.
    let memoryCapacity: Int?

    /// Disk capacity in bytes. Nil for unbounded.
    let diskCapacity: Int?

    /// Maximum age of the cache entries in seconds. Nil for unbounded.
    let ageCapacity: TimeInterval?

    /// Minimum interval for updating access timestamp. Defaults to 1 hour.
    public var accessInterval: TimeInterval = .hours(1)

    /// Minimum interval for flushing the index. Defaults to 1.3 seconds.
    public var flushInterval: TimeInterval = 1.3


    public init(name: String, location: CacheLocation = .cache, memoryCapacity: Int? = nil, diskCapacity: Int? = nil, ageCapacity: TimeInterval? = nil) {
        self.name = name
        self.location = location
        self.memoryCapacity = memoryCapacity
        self.diskCapacity = diskCapacity
        self.ageCapacity = ageCapacity
    }

}
