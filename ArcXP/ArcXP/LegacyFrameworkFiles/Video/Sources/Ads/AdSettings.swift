//  Copyright © 2020 The Washington Post. All rights reserved.

import Foundation

/// Implemented by classes and structs that store settings for a specific ad
/// provider, such as Google IMA ads or livestream ads. They are typically
/// passed to the
/// `ArcMediaClient.video(forOrganizationName:mediaID:adSettings:accessToken:handleResult:)`
/// and set in the `ArcVideo.adSettings`.
public protocol AdSettings {
    // empty
}
