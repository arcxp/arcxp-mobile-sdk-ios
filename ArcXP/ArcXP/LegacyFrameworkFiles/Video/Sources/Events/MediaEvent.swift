//  Copyright © 2021 The Washington Post. All rights reserved.

import AVFoundation
import Foundation

// swiftlint:disable cyclomatic_complexity identifier_name comma

/// Data that objects can pass to ``MediaEventCenter/sendEvent(_:)``, which in
/// turn sends them to ``MediaEventSubscriber``s. These will eventually replace
/// the ``PlayerDelegate`` callbacks.
public enum MediaEvent: Equatable {

    // swiftlint:disable function_body_length

    /// Compare two events. In most cases, they have to be the same type, and
    /// any associated data also has to be equal.
    public static func == (lhs: MediaEvent, rhs: MediaEvent) -> Bool {
        switch (lhs, rhs) {

        // Captioning

        case (.playerCaptionsOn(let p1, captionType: let t1), .playerCaptionsOn(let p2, captionType: let t2)):
            return p1 === p2 && t1 == t2
        case (.playerCaptionsOff(let p1),                     .playerCaptionsOff(let p2)):
            return p1 === p2

        // Player Lifecycle

        case (.playerCurrentItemChanged(let p1, let i1), .playerCurrentItemChanged(let p2, let i2)):
            return p1 === p2 && i1 === i2
        case (.playerError(let p1, let e1),              .playerError(let p2, let e2)):
            return p1 === p2 && e1?.localizedDescription == e2?.localizedDescription
        case (.playerAppeared(let p1),                   .playerAppeared(let p2)):
            return p1 === p2
        case (.playerReady(let p1),                      .playerReady(let p2)):
            return p1 === p2
        case (.playerStatusUnknown(let p1),              .playerStatusUnknown(let p2)):
            return p1 === p2

        // AVPlayerItem Lifecycle

        case (.playerItemError(let p1, let i1, let e1), .playerItemError(let p2, let i2, let e2)):
            return p1 === p2 && i1 === i2 && e1?.localizedDescription == e2?.localizedDescription
        case (.playerItemReady(let p1, let i1),         .playerItemReady(let p2, let i2)):
            return p1 === p2 && i1 === i2
        case (.playerItemStatusUnknown(let p1, let i1), .playerItemStatusUnknown(let p2, let i2)):
            return p1 === p2 && i1 === i2

        // Playback

        case (.playerItemCompleted(let p1, let i1),               .playerItemCompleted(let p2, let i2)):
            return p1 === p2 && i1 === i2
        case (.playerItemPlayed25Percent(let p1, let i1),         .playerItemPlayed25Percent(let p2, let i2)):
            return p1 === p2 && i1 === i2
        case (.playerItemPlayed50Percent(let p1, let i1),         .playerItemPlayed50Percent(let p2, let i2)):
            return p1 === p2 && i1 === i2
        case (.playerItemPlayed75Percent(let p1, let i1),         .playerItemPlayed75Percent(let p2, let i2)):
            return p1 === p2 && i1 === i2
        case (.playerItemPlayedPercent(let p1, let i1, let pct1), .playerItemPlayedPercent(let p2, let i2, let pct2)):
            return p1 === p2 && i1 === i2 && pct1 == pct2

        // AVPlayer.isMuted & .volume

        case (.playerMuted(let p1),                  .playerMuted(let p2)):
            return p1 === p2
        case (.playerUnmuted(let p1),                .playerUnmuted(let p2)):
            return p1 === p2
        case (.playerVolumedChanged(let p1, let v1), .playerVolumedChanged(let p2, let v2)):
            return p1 === p2 && v1 == v2

        // User Interaction

        case (.playerPaused(let p1, let i1),  .playerPaused(let p2, let i2)):
            return p1 === p2 && i1 === i2
        case (.playerPlaying(let p1, let i1), .playerPlaying(let p2, let i2)):
            return p1 === p2 && i1 === i2
        case (.playerWaiting(let p1, let i1), .playerWaiting(let p2, let i2)):
            return p1 === p2 && i1 === i2
        case (.playerTapped(let p1, let i1),  .playerTapped(let p2, let i2)):
            return p1 === p2 && i1 === i2

        // Ad Interactions

        case (.playerAdSkipped(let p1, _),               .playerAdSkipped(let p2, _)):
            return p1 === p2
        case (.playerAdTapped(let p1, _),                .playerAdTapped(let p2, _)):
            return p1 === p2
        case (.playerAdReturnedToNormalSize(let p1, _),  .playerAdReturnedToNormalSize(let p2, _)):
            return p1 === p2
        case (.playerAdWentFullscreen(let p1, _),        .playerAdWentFullscreen(let p2, _)):
            return p1 === p2
        case (.playerAdVolumeChanged(let p1, _, let v1), .playerAdVolumeChanged(let p2, _, let v2)):
            return p1 === p2 && v1 == v2
        case (.playerAdMuted(let p1, _),                 .playerAdMuted(let p2, _)):
            return p1 === p2
        case (.playerAdUnmuted(let p1, _),               .playerAdUnmuted(let p2, _)):
            return p1 === p2

        // Ad Lifecycle

        case (.playerAdError(let p1, _, let e1), .playerAdError(let p2, _, let e2)):
            return p1 === p2 && e1?.localizedDescription == e2?.localizedDescription
        case (.playerAdLoaded(let p1, _),        .playerAdLoaded(let p2, _)):
            return p1 === p2
        case (.playerAdPaused(let p1, _),        .playerAdPaused(let p2, _)):
            return p1 === p2
        case (.playerAdPlaying(let p1, _),       .playerAdPlaying(let p2, _)):
            return p1 === p2

        // Ad Playback

        case (.playerAdBreakStarted(let p1, let break1), .playerAdBreakStarted(let p2, let break2)):
            return p1 === p2 && break1 == break2
        case (.playerAdBreakEnded(let p1, let break1),   .playerAdBreakEnded(let p2, let break2)):
            return p1 === p2 && break1 == break2
        case (.playerAdStarted(let p1, _),               .playerAdStarted(let p2, _)):
            return p1 === p2
        case (.playerAdImpression(let p1, _),            .playerAdImpression(let p2, _)):
            return p1 === p2
        case (.playerAdPlayed25Percent(let p1, _),       .playerAdPlayed25Percent(let p2, _)):
            return p1 === p2
        case (.playerAdPlayed50Percent(let p1, _),       .playerAdPlayed50Percent(let p2, _)):
            return p1 === p2
        case (.playerAdPlayed75Percent(let p1, _),       .playerAdPlayed75Percent(let p2, _)):
            return p1 === p2
        case (.playerAdCompleted(let p1, _),             .playerAdCompleted(let p2, _)):
            return p1 === p2
        case (.playerAdClicked(let p1, adInfo: _), .playerAdClicked(let p2, adInfo: _)):
            return p1 === p2
        case (.playerAdWillOpenExternalApplication(let p1), .playerAdWillOpenExternalApplication(let p2)):
            return p1 === p2
        case (.playerAdWillOpenInAppLink(let p1), .playerAdWillOpenInAppLink(let p2)):
            return p1 === p2
        case (.playerAdDidOpenInAppLink(let p1), .playerAdDidOpenInAppLink(let p2)):
            return p1 === p2
        case (.playerAdWillCloseInAppLink(let p1), .playerAdWillCloseInAppLink(let p2)):
            return p1 === p2
        case (.playerAdDidCloseInAppLink(let p1), .playerAdDidCloseInAppLink(let p2)):
            return p1 === p2

        default:
            fatalError("Not all event types are accounted for: \(lhs), \(rhs)")
        }
    }
    // swiftlint:enable function_body_length

    // MARK: - Captioning

    /// The user turned captions on, or the system re-enabled them from a
    /// previous run. The type indicates what kind type of captions (embedded in
    /// the stream, or in an associated VTT file) were turned on.
    case playerCaptionsOn(_ player: AVPlayer, captionType: AVPlayerItem.CaptionType)

    /// The user turned captions off, or the system re-disabled them from a
    /// previous run.
    case playerCaptionsOff(_ player: AVPlayer)

    // MARK: - Player Lifecycle

    // The `AVPlayer.currentItem` has changed. The new item is set to the
    /// `AVPlayer.currentItem` property, and the *previous* item (if any) is
    /// passed into this casetion.
    case playerCurrentItemChanged(_ player: AVPlayer, fromOldItem: AVPlayerItem?)

    /// There was a non-ad-related error during playback. (Ad-related errors
    /// handled by `adError()`.)
    case playerError(_ player: AVPlayer, error: Error?)

    /// Called when the `AVPlayer` is loaded in a view controller. This doesn't
    /// necessarily mean that the player is *visible* on the screen yet.
    case playerAppeared(_ player: AVPlayer)

    /// The `AVPlayer.status` has changed to `.ready`.
    ///
    /// - parameter player: The player.
    case playerReady(_ player: AVPlayer)

    /// The `AVPlayer.status` has changed to `.unknown`.
    ///
    /// - parameter player: The player.
    case playerStatusUnknown(_ player: AVPlayer)

    // MARK: - AVPlayerItem Lifecycle

    /// The `AVPlayerItem.status` has changed to `.error`.
    case playerItemError(_ player: AVPlayer, item: AVPlayerItem?, error: Error?)

    /// The `AVPlayerItem.status` has changed to `.ready`.
    case playerItemReady(_ player: AVPlayer, item: AVPlayerItem?)

    /// The `AVPlayerItem.status` has changed to `.unknown`.
    case playerItemStatusUnknown(_ player: AVPlayer, item: AVPlayerItem?)

    // MARK: - Playback

    /// The entire video has played.
    case playerItemCompleted(_ player: AVPlayer, item: AVPlayerItem?)

    /// 25% of the video has played.
    case playerItemPlayed25Percent(_ player: AVPlayer, item: AVPlayerItem?)

    /// Half of the video has played.
    case playerItemPlayed50Percent(_ player: AVPlayer, item: AVPlayerItem?)

    /// 75% of the video has played.
    case playerItemPlayed75Percent(_ player: AVPlayer, item: AVPlayerItem?)

    /// A given percentage of the video has played.
    case playerItemPlayedPercent(_ player: AVPlayer, item: AVPlayerItem?, percent: Double)

    // MARK: - AVPlayer.isMuted & .volume

    /// The player volume was muted explicitly, either by tapping the
    /// mute/unmute button, or by calling `ArcMediaPlayerView.mute()`.
    ///
    /// - note: This is _not_ called when the volume reaches `0.0` by
    /// pressing the device's volume-down button, or by sliding the volume
    /// slider to the minimum value.
    case playerMuted(_ player: AVPlayer)

    /// The player volume was unmuted explicitly, either by tapping the
    /// mute/unmute button, or by calling `ArcMediaPlayerView.unmute()`.
    ///
    /// - note: This is _not_ called when the volume reaches `1.0` by
    /// pressing the device's volume-up button, or by sliding the volume
    /// slider to the maximum value.
    case playerUnmuted(_ player: AVPlayer)

    /// The volume of the player has changed. **Note:** Setting the
    /// `player.volume` to `0.0` will call this _and_ `playerMuted()`, just as
    /// setting it to any value above `0.0` when it's muted will also call
    /// `playerUnmuted()`.
    case playerVolumedChanged(_ player: AVPlayer, previousVolume: Float?)

    // MARK: - User Interaction

    /// The video was paused.
    case playerPaused(_ player: AVPlayer, item: AVPlayerItem?)

    /// The video was unpaused. Note that this doesn't distinguish between
    /// playing a video for the first time vs. playing after being paused.
    case playerPlaying(_ player: AVPlayer, item: AVPlayerItem?)

    /// The player view was tapped by the user.
    case playerTapped(_ player: AVPlayer, item: AVPlayerItem?)

    /// The player is waiting for the item's next batch of data to be loaded.
    case playerWaiting(_ player: AVPlayer, item: AVPlayerItem?)

    //// The user is now viewing the player in fullscreen mode.
    case playerBeganFullScreenPresentation(_ player: AVPlayer, item: AVPlayerItem?)

    /// The player has returned from fullscreen mode to the normal size.
    case playerEndedFullScreenPresentation(_ player: AVPlayer, item: AVPlayerItem?)

    /// The user skipped to a different point in the video.
    case playerItemSkipped(_ player: AVPlayer, item: AVPlayerItem?, toTime: CMTime)

    /// Playback of the video started.
    case playerItemStarted(_ player: AVPlayer, item: AVPlayerItem?)

    // MARK: - Ad Interactions

    /// The current ad was manually skipped by the user. This applies only to
    /// Google IMA ads; livestream ads are not currently skippable.
    case playerAdSkipped(_ player: AVPlayer, adInfo: Any?)

    /// The user tapped the ad. This applies only to Google IMA ads; livestream
    /// ads are not currently interactive.
    case playerAdTapped(_ player: AVPlayer, adInfo: Any?)

    /// The player view returned to its normal size after being in fullscreen
    /// mode. **Note:** this is sent only when the
    /// ``ArcMediaPlayerViewController`` is used, not the
    /// `AVPlayerViewController`.
    case playerAdReturnedToNormalSize(_ player: AVPlayer, adInfo: Any?)

    /// The player view changed to fullscreen mode. **Note:** this is sent only
    /// when the ``ArcMediaPlayerViewController`` is used, not the
    /// `AVPlayerViewController`.
    case playerAdWentFullscreen(_ player: AVPlayer, adInfo: Any?)

    /// The player volume changed while an ad was playing.
    case playerAdVolumeChanged(_ player: AVPlayer, adInfo: Any?, previousVolume: Float?)

    /// The player was muted while an ad was playing.
    case playerAdMuted(_ player: AVPlayer, adInfo: Any?)

    /// The player was unmuted while an ad was playing.
    case playerAdUnmuted(_ player: AVPlayer, adInfo: Any?)

    /// The user clicked the "Learn More" button on the ad.
    case playerAdClicked(_ player: AVPlayer, adInfo: Any?)

    // MARK: - Ad Lifecycle

    /// An error occurred when an ad was played.
    case playerAdError(_ player: AVPlayer, adInfo: Any?, error: Error?)

    /// Ad data was loaded.
    case playerAdLoaded(_ player: AVPlayer, adInfo: Any?)

    /// An ad was paused.
    case playerAdPaused(_ player: AVPlayer, adInfo: Any?)

    /// An ad was resumed.
    case playerAdPlaying(_ player: AVPlayer, adInfo: Any?)

    // MARK: - Ad Playback

    /// A livestream ad break, consisting of multiple ads, started.
    case playerAdBreakStarted(_ player: AVPlayer, adBreak: LivestreamAdBreak?)

    /// A livestream ad break finished.
    case playerAdBreakEnded(_ player: AVPlayer, adBreak: LivestreamAdBreak?)

    /// An ad started.
    case playerAdStarted(_ player: AVPlayer, adInfo: Any?)

    /// An ad impression occurred. For livestream ads, this is fired when the ad
    /// starts; for Google IMA ads, it's fired when the ad is completed.
    case playerAdImpression(_ player: AVPlayer, adInfo: Any?)

    /// 25% of an ad played.
    case playerAdPlayed25Percent(_ player: AVPlayer, adInfo: Any?)

    /// 50% of an ad played.
    case playerAdPlayed50Percent(_ player: AVPlayer, adInfo: Any?)

    /// 75% of an ad played.
    case playerAdPlayed75Percent(_ player: AVPlayer, adInfo: Any?)

    /// An ad finished playing.
    case playerAdCompleted(_ player: AVPlayer, adInfo: Any?)

    // MARK: - Ad Lifecycle

    case playerInitializedWithPAL(nonce: String)

    case player(palError: Error)

    case playerReportedAdClickPAL(nonce: String?)

    case playerReportedVideoStartPAL(nonce: String?)

    case playerReportedVideoEndPAL(nonce: String?)

    // MARK: - Link Opener

    case playerAdWillOpenExternalApplication(player: AVPlayer)

    case playerAdWillOpenInAppLink(player: AVPlayer)

    case playerAdDidOpenInAppLink(player: AVPlayer)

    case playerAdWillCloseInAppLink(player: AVPlayer)

    case playerAdDidCloseInAppLink(player: AVPlayer)
}
// swiftlint:enable cyclomatic_complexity identifier_name comma
