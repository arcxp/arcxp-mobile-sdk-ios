//  Copyright © 2020 The Washington Post. All rights reserved.

import ArcXP
import Foundation

/// Constants for settings in `UserDefaults`. They're `public` so that the
/// UI tests can access them.
public enum AppSettings: String, Codable {

    /// `UserDefaults` key for the most recent successfully-fetched video UUID.
    case mediaId = "media-id"

    /// `UserDefaults` key for the most recent successfully-used organization
    /// ID.
    case organizationName = "organization-name"

    /// `UserDefaults` key for the index of the video/virtual channel
    /// `UISegmentedControl`
    case selectedConfiguration = "selected-config"

    /// `UserDefaults` key for the most recent successfully-fetched virtual
    /// channel UUID.
    case virtualChannelId = "virtual-channel-id"

    /// `UserDefaults` key for storing the selected server environment
    /// segmented control index. `0` is ``ServerEnvironment.sandbox`, `1` is
    /// `.production`, etc.
    case serverEnvironment = "server-environment"

    /// Shortcut for setting a value in `UserDefaults.standard`. Just call
    /// `Settings.organizationName.set(value: "The Washington Post")`.
    public func set(value: Any?) {
        UserDefaults.standard.set(value, forKey: self.rawValue)
    }

    /// Shortcut for getting this key's value from `UserDefaults.standard`.
    public func get() -> Any? {
        return UserDefaults.standard.value(forKey: self.rawValue)
    }

}
