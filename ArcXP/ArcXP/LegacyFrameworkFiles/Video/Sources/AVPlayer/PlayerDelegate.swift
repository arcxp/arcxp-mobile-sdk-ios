//  Copyright © 2020 The Washington Post. All rights reserved.

import AVFoundation
import Foundation
// swiftlint: disable file_length
/// Implemented by callers to track the playback- and ad-related activities of
/// an `AVPlayer`. It's class-bound so that it can be weakly owned by an
/// object, as delegates usually are.
@available(*, deprecated, renamed: "PlayerDelegate")
public typealias AVPlayerDelegate = PlayerDelegate

/// Implemented by callers to track the playback- and ad-related activities of
/// an `AVPlayer`. It's class-bound so that it can be weakly owned by an
/// object, as delegates usually are.
public protocol PlayerDelegate: AnyObject {

    // MARK: - Captioning

    /// The user turned captions on, or the system re-enabled them from a
    /// previous run.
    ///
    /// - parameter player: The player.
    /// - parameter captionType : The type of captions (embedded in the stream,
    ///   or in an associated VTT file) that were turned on.
    func player(_ player: AVPlayer, captionsOn captionType: AVPlayerItem.CaptionType)

    /// The user turned captions off, or the system re-disabled them from a
    /// previous run.
    ///
    /// - parameter player: The player.
    func playerCaptionsOff(_ player: AVPlayer)

    // MARK: - Player Lifecycle

    // The `AVPlayer.currentItem` has changed. The new item is set to the
    /// `AVPlayer.currentItem` property, and the *previous* item (if any) is
    /// passed into this function.
    ///
    /// - parameter player: The player.
    /// - parameter oldItem: The previous `AVPlayerItem`, if any.
    func player(_ player: AVPlayer,
                currentItemChangedFrom oldItem: AVPlayerItem?)

    /// There was a non-ad-related error during playback. (Ad-related errors
    /// handled by `adError()`.)
    ///
    /// - parameter player: The player.
    func player(_ player: AVPlayer,
                error: Error?)

    /// Called when the `AVPlayer` is loaded in a view controller.
    ///
    /// - parameter player: The player.
    ///
    /// - note: This doesn't necessarily mean that the player is *visible* on
    ///   the screen yet.
    func playerAppeared(_ player: AVPlayer)

    /// The `AVPlayer.status` has changed to `.ready`.
    ///
    /// - parameter player: The player.
    func playerReady(_ player: AVPlayer)

    /// The `AVPlayer.status` has changed to `.unknown`.
    ///
    /// - parameter player: The player.
    func playerStatusUnknown(_ player: AVPlayer)

    // MARK: - AVPlayerItem Lifecycle

    /// The `AVPlayerItem.status` has changed to `.error`.
    ///
    /// - Parameters:
    ///   - player: The player.
    ///   - item: The player's `currentItem`.
    func player(_ player: AVPlayer,
                item: AVPlayerItem?,
                error: Error?)

    /// The `AVPlayerItem.status` has changed to `.ready`.
    ///
    /// - Parameters:
    ///   - player: The player.
    ///   - item: The player's `currentItem`.
    func player(_ player: AVPlayer,
                itemReady item: AVPlayerItem?)

    /// The `AVPlayerItem.status` has changed to `.unknown`.
    ///
    /// - Parameters:
    ///   - player: The player.
    ///   - item: The player's `currentItem`.
    func player(_ player: AVPlayer,
                itemStatusUnknown item: AVPlayerItem?)

    // MARK: - AVPlayerItem Playback

    /// The entire video has played.
    ///
    /// - Parameters:
    ///   - player: The player.
    ///   - item: The player's `currentItem`.
    func player(_ player: AVPlayer,
                completed item: AVPlayerItem?)

    /// 25% of the video has played.
    ///
    /// - Parameters:
    ///   - player: The player.
    ///   - item: The player's `currentItem`.
    func player(_ player: AVPlayer,
                played25Percent item: AVPlayerItem?)

    /// Half of the video has played.
    ///
    /// - Parameters:
    ///   - player: The player.
    ///   - item: The player's `currentItem`.
    func player(_ player: AVPlayer,
                played50Percent item: AVPlayerItem?)

    /// 75% of the video has played.
    ///
    /// - Parameters:
    ///   - player: The player.
    ///   - item: The player's `currentItem`.
    func player(_ player: AVPlayer,
                played75Percent item: AVPlayerItem?)

    // A given percentage of the video has played.
    ///
    /// - Parameters:
    ///   - player: The player.
    ///   - item: The player's `currentItem`.
    ///   - percent: The percentage of the video that had played when
    ///     this was called.
    func player(_ player: AVPlayer,
                item: AVPlayerItem?,
                playedPercent percent: Double)

    /// Playback of the video started.
    ///
    /// - Parameters:
    ///   - player: The player.
    ///   - item: The player's `currentItem`.
    ///   - byUser: `true` if the user explicitly started a video;
    ///     `false` if it was auto-played (and autoplay is supported).
    func player(_ player: AVPlayer,
                started item: AVPlayerItem?,
                byUser: Bool)

    // MARK: - AVPlayer.isMuted & .volume

    /// The player volume was muted explicitly, either by tapping the
    /// mute/unmute button, or by calling `ArcMediaPlayerView.mute()`.
    ///
    /// - note: This is _not_ called when the volume reaches `0.0` by
    ///   pressing the device's volume-down button, or by sliding the volume
    ///   slider to the minimum value.
    ///
    /// - parameter player: The player.
    func playerMuted(_ player: AVPlayer)

    /// The player volume was unmuted explicitly, either by tapping the
    /// mute/unmute button, or by calling `ArcMediaPlayerView.unmute()`.
    ///
    /// - note: This is _not_ called when the volume reaches `1.0` by
    ///   pressing the device's volume-up button, or by sliding the volume
    ///   slider to the maximum value.
    ///
    /// - parameter player: The player.
    func playerUnmuted(_ player: AVPlayer)

    /// The volume of the player has changed. **Note:** Setting the
    /// `player.volume` to `0.0` will call this _and_ `playerMuted()`, just as
    /// setting it to any value above `0.0` when it's muted will also call
    /// `playerUnmuted()`.
    ///
    /// - parameter player: The player.
    /// - parameter previousVolume: The volume before it changed. To get the
    ///   _new_ volume, call `player.volume`.
    func player(_ player: AVPlayer,
                volumeChangedFrom previousVolume: Float?)

    // MARK: - User Interaction

    /// The video was paused. This doesn't indicate *how* it was paused.
    ///
    /// - Parameters:
    ///   - player: The player.
    ///   - item: The player's `currentItem`.
    func player(_ player: AVPlayer,
                paused item: AVPlayerItem?)

    /// The video was unpaused.
    ///
    /// - Parameters:
    ///   - player: The player.
    ///   - item: The player's `currentItem`.
    ///
    /// - note: This isn't always called accurately, because the `AVPlayer`
    ///   doesn't distinguish between playing for the first time vs. playing
    ///   after being paused.
    func player(_ player: AVPlayer,
                resumed item: AVPlayerItem?)

    /// The player view was tapped. If it was tapped while a livestream ad is
    /// playing, ``player(_:adTapped:)-5ndiw`` will be called instead.
    ///
    /// - Parameters:
    ///   - player: The player.
    ///   - item: The player's `currentItem`.
    func playerTapped(_ player: AVPlayer,
                      item: AVPlayerItem?)

    /// The player view was expanded to fullscreen. This is called when either
    /// the ``ArcMediaPlayerViewController`` or the `AVPlayerViewController` is
    /// used.
    ///
    /// - Parameters:
    ///   - player: The player.
    ///   - item: The player's `currentItem`.
    func playerBeganFullScreenPresentation(_ player: AVPlayer,
                                           item: AVPlayerItem?)

    /// The player view was returned to normal size. This is called when either
    /// the ``ArcMediaPlayerViewController`` or the `AVPlayerViewController` is
    /// used.
    ///
    /// - Parameters:
    ///   - player: The player.
    ///   - item: The player's `currentItem`.
    func playerEndedFullScreenPresentation(_ player: AVPlayer,
                                           item: AVPlayerItem?)

    /// The user skipped to a different point in the video.
    ///
    /// - parameter player: The player.
    /// - parameter item: The media item that's playing.
    /// - parameter skippedTo: The new playback time.
    func player(_ player: AVPlayer,
                item: AVPlayerItem?,
                skippedTo time: CMTime)

    // MARK: - Ad Breaks

    /// One or more ads just finished playing.
    ///
    /// - note: This is currently called only for livestream mid-roll ads, not
    ///   Google IMA pre- or post-roll ads.
    ///
    /// - parameter player: The player.
    /// - parameter adInfo: Information about the ad sequence that just played.
    ///   For livestream mid-roll ads from AWS Media Tailor, this is an
    ///   instance of `LivestreamAdBreak`, which has an `ads` property with the
    ///   list of ads that are contained in the sequence.
    func player(_ player: AVPlayer,
                adBreakEnded adInfo: Any?)

    /// One or more ads just is about to play.
    ///
    /// - note: This is currently called only for livestream mid-roll ads, not
    ///   Google IMA pre- or post-roll ads.
    ///
    /// - parameter player: The player.
    /// - parameter adInfo: Information about the ad sequence that's about to
    ///   play.
    ///   For livestream mid-roll ads from AWS Media Tailor, this is an
    ///   instance of `LivestreamAdBreak`, which has an `ads` property with the
    ///   list of ads that are contained in the sequence.
    func player(_ player: AVPlayer,
                adBreakStarted adInfo: Any?)

    // MARK: - Ad Playback

    /// The ad finished playing normally.
    ///
    /// - parameter player: The player.
    /// - parameter adInfo: The ad data. This must be cast to the appropriate
    ///   type. For livestream mid-roll ads, this will be a
    ///   `LivestreamAd`. For Google IMA ads, this will be an `IMAAd`.
    func player(_ player: AVPlayer,
                adCompleted adInfo: Any?)

    /// The user watched an ad. The exact definition of an impression may vary
    /// by ad platform. For example, a livestream impression is fired when an
    /// ad is finished playing, but for IAM Open Measurement, it's when the ad
    /// content is fully downloaded from the ad server.
    ///
    /// - parameter player: The player.
    /// - parameter adInfo: The ad data. This must be cast to the appropriate
    ///   type. For livestream mid-roll ads, this will be a
    ///   `LivestreamAd`. For Google IMA ads, this will be an `IMAAd`.
    func player(_ player: AVPlayer,
                adImpression adInfo: Any?)

    /// There was an error playing an ad.
    ///
    /// - parameter player: The player.
    /// - parameter adInfo: The ad data. This must be cast to the appropriate
    ///   type. For livestream mid-roll ads, this will be a
    ///   `LivestreamAd`. For Google IMA ads, this will always be
    ///   `nil`.
    /// - parameter error: The error that was thrown.
    func player(_ player: AVPlayer,
                adInfo: Any?,
                adError error: Error?)

    /// The ad is 25% complete.
    ///
    /// - parameter player: The player.
    /// - parameter adInfo: The ad data. This must be cast to the appropriate
    ///   type. For livestream mid-roll ads, this will be a
    ///   `LivestreamAd`. For Google IMA ads, this will be an `IMAAd`.
    func player(_ player: AVPlayer,
                adPlayed25Percent adInfo: Any?)

    /// The ad is halfway complete.
    ///
    /// - parameter player: The player.
    /// - parameter adInfo: The ad data. This must be cast to the appropriate
    ///   type. For livestream mid-roll ads, this will be a
    ///   `LivestreamAd`. For Google IMA ads, this will be an `IMAAd`.
    func player(_ player: AVPlayer,
                adPlayed50Percent adInfo: Any?)

    /// The ad is 75% complete.
    ///
    /// - parameter player: The player.
    /// - parameter adInfo: The ad data. This must be cast to the appropriate
    ///   type. For livestream mid-roll ads, this will be a
    ///   `LivestreamAd`. For Google IMA ads, this will be an `IMAAd`.
    func player(_ player: AVPlayer,
                adPlayed75Percent adInfo: Any?)

    /// An ad started playing.
    ///
    /// - parameter player: The player.
    /// - parameter adInfo: The ad data. This must be cast to the appropriate
    ///   type. For livestream mid-roll ads, this will be a
    ///   `LivestreamAd`. For Google IMA ads, this will be an `IMAAd`.
    func player(_ player: AVPlayer,
                adStarted adInfo: Any?)

    // MARK: - Ad User Interaction

    /// The ad was paused.
    ///
    /// - parameter player: The player.
    /// - parameter adInfo: The ad data. This must be cast to the appropriate
    ///   type. For livestream mid-roll ads, this will be a
    ///   `LivestreamAd`. For Google IMA ads, this will always be `nil`.
    func player(_ player: AVPlayer,
                adPaused adInfo: Any?)

    /// The ad was unpaused.
    ///
    /// - parameter player: The player.
    /// - parameter adInfo: The ad data. This must be cast to the appropriate
    ///   type. For livestream mid-roll ads, this will be a
    ///   `LivestreamAd`. For Google IMA ads, this will always be `nil`.
    func player(_ player: AVPlayer,
                adResumed adInfo: Any?)

    /// The user skipped an ad.
    ///
    /// - parameter player: The player.
    /// - parameter adInfo: The ad data. This must be cast to the appropriate
    ///   type. For livestream mid-roll ads, this will be a
    ///   `LivestreamAd`. For Google IMA ads, this will be an `IMAAd`.
    ///
    /// - note: This is called only for Google IMA ads.
    func player(_ player: AVPlayer,
                adSkipped adInfo: Any?)

    /// The user tapped on an ad to see more info.
    ///
    /// - parameter adInfo: The ad data. This must be cast to the appropriate
    ///   type. For livestream mid-roll ads, this will be a
    ///   `LivestreamAd`. For Google IMA ads, this will be `nil`.
    func player(_ player: AVPlayer,
                adTapped adInfo: Any?)

    // MARK: - Ad Muted, Unmuted, & Volume changed

    /// The player was muted during an ad.
    ///
    /// - parameter player: The player.
    /// - parameter adInfo: The ad data. This must be cast to the appropriate
    ///   type. For livestream mid-roll ads, this will be a
    ///   `LivestreamAd`. For Google IMA ads, this will be an `IMAAd`.
    func player(_ player: AVPlayer,
                adMuted: Any?)

    /// The player was unmuted during an ad.
    ///
    /// - parameter player: The player.
    /// - parameter adInfo: The ad data. This must be cast to the appropriate
    ///   type. For livestream mid-roll ads, this will be a
    ///   `LivestreamAd`. For Google IMA ads, this will be an `IMAAd`.
    func player(_ player: AVPlayer,
                adUnmuted: Any?)

    /// The player's volume was changed during an ad.
    ///
    /// - parameter player: The player.
    /// - parameter adInfo: The ad data. This must be cast to the appropriate
    ///   type. For livestream mid-roll ads, this will be a
    ///   `LivestreamAd`. For Google IMA ads, this will be an `IMAAd`.
    func player(_ player: AVPlayer,
                adInfo: Any?,
                volumeChangedFrom previousVolume: Float?)

    /// The player's ad was clicked (the player tapped "Learn More").
    ///
    /// - parameter player: The player.
    /// - parameter adClicked: The ad data. This must be cast to the appropriate
    ///   type. For livestream mid-roll ads, this will be a
    ///   `LivestreamAd`. For Google IMA ads, this will be an `IMAAd`.
    func player(_ player: AVPlayer, adClicked: Any?)

    // MARK: - PAL events
    /// Player was initialized with PAL nonce data
    /// - Parameter nonce: Nonce String of the PAL data
    func playerInitializedwithPAL(nonce: String)

    /// Error while initializing the PAL
    /// - Parameter error: error from PAL SDK
    func player(palError: Error?)

    /// Player reported when an ad is tapped
    /// - Parameter nonce: Nonce of the PAL
    func playerReportedAdClickPAL(nonce: String?)

    /// Player reported the start of the playback to PAL
    /// - Parameter nonce: Nonce of the PAL
    func playerReportedVideoStartPAL(nonce: String?)

    /// Player reported the end of the playback to PAL
    /// - Parameter nonce: Nonce of the PAL
    func playerReportedVideoEndPAL(nonce: String?)

    // MARK: - Link Opener

    func playerAdWillOpenExternalApplication(player: AVPlayer)
    func playerAdWillOpenInAppLink(player: AVPlayer)
    func playerAdDidOpenInAppLink(player: AVPlayer)
    func playerAdWillCloseInAppLink(player: AVPlayer)
    func playerAdDidCloseInAppLink(player: AVPlayer)
}
// swiftlint: enable file_length
