//  Copyright © 2020 The Washington Post. All rights reserved.

import Foundation

/// Implemented by objects that load, play, and manage third-party pre- and
/// post-roll ads.
public protocol AdController: AnyObject {

    // MARK: - Configuration

    /// Configure the ad settings from a JSON configuration file.
    func configure(_ config: ArcMediaAdConfig)

    /// Configure the ad from the `adTagUrl`.
    func configure(adTagUrl: URL)

    // MARK: - Play & Pause

    /// `true` if an ad is visible onscreen.
    var isAdVisible: Bool { get }

    /// `true` if an ad is playing. ``isAdVisible`` should also be `true`.
    var isAdPlaying: Bool { get set }

    /// Pause  the current ad. ``isAdPlaying`` should be `false`, but
    /// ``isAdVisible`` may still be `true`.
    func pauseAd()

    /// Request ads from the third-party service. This is called when a video
    /// is played.
    func requestAds()

    /// Resume playing the current ad, such as when the app returns from the
    /// background or a view controller becomes active again. ``isAdPlaying``
    /// and ``isAdVisible`` should be set to `true`
    func resumeAd()

    /// Resume playing the non-ad content, such as after an ad is finished or
    /// an ad error occurred.
    func resumeContent()

}
