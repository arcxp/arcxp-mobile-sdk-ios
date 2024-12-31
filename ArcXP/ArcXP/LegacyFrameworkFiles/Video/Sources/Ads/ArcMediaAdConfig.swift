//  Copyright © 2020 The Washington Post. All rights reserved.

import Foundation

/// The cross-platform configuration for ad support. It currently applies only
/// to Google IMA (pre-roll and post-roll) ads; livestream ads are configured
/// on the server side.
public struct ArcMediaAdConfig {

    /// The URL that Google IMA ads use for various configuration settings.
    public var adConfigUrl: URL?

    /// `true` if ads should be played. **Note: This is currently used only to
    /// enable or disable Google pre-roll and post-roll ads; it does not
    /// affect mid-roll ads on livestreams, which are always enabled.**
    public var adEnabled: Bool

    public init(adConfigUrl: URL?, adEnabled: Bool) {
        self.adConfigUrl = adConfigUrl
        self.adEnabled = adEnabled
    }
}
