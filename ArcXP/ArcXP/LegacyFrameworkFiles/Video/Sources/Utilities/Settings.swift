//  Copyright © 2020 The Washington Post. All rights reserved.

import Foundation

/// Until we can use property wrappers (which require iOS 13), this is a
/// simple protocol for types that can get and set a particular key in
/// `UserDefaults.standard`. The main advantage is that they key is set only
/// once, so you don't need to worry about defining constants for them, i.e.
///
/// ```
/// // Instead of this,
///
/// let key = "some key"
/// UserDefaults.standard.set(false, forKey: key)
/// let value = UserDefaults.standard.bool(forKey: key)
///
/// // you just use
/// var setting = BooleanSetting(key: "some key")
/// setting.set(true)
/// let value = setting.get
protocol Setting {

    /// The data type of the `UserDefaults` entry.
    associatedtype Value

    /// The setting's `UserDefaults` dictionary key.
    var key: String { get }

    /// Get the value from `UserDefaults.standard`.
    var get: Value { get }

    /// Set the value in `UserDefaults.standard`.
    ///
    /// - parameter value: The new value.
    func set(_ value: Value)

}

/// A `Setting` implementation for boolean `UserDefaults` values.
struct BooleanSetting: Setting {

    /// The setting's `UserDefaults` dictionary key.
    var key: String

    /// Get the value from `UserDefaults.standard`.
    var get: Bool {
        return UserDefaults.standard.bool(forKey: key)
    }

    /// Set the value in `UserDefaults.standard`.
    ///
    /// - parameter value: The new value.
    func set(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: key)
    }

}

/// Framework-wide settings that are stored in `UserDefaults.standard`.
struct Settings {

    /// Whether to show closed captions, if they're available.
    static var showClosedCaptions = BooleanSetting(key: "ArcMediaPlayer.showClosedCaptions")
    // Note that it still uses the old name of the framework, so that existing
    // instances can still access any previously-saved data.

}
