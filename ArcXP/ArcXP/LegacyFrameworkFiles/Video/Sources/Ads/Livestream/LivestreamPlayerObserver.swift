//  Copyright © 2020 The Washington Post. All rights reserved.

import AVFoundation
import ProgrammaticAccessLibrary
import UIKit
#if os(iOS)
import OMSDK_Washpost
#endif
// swiftlint: disable file_length
/// Fetches livestream ad break data from the ad server at regular intervals
/// (see `adBreakCheckInterval`) during playback, and then registers boundary
/// time observers on an `AVPlayer` to do two things:
///
/// 1. Call `LivestreamAd.TrackingEvent.beaconUrl`s on the ad server to track
///    ad views and user interactions.
/// 2. Send ``MediaEvent``s to the ``MediaEventCenter`` whenever playback
///    milestones are reached, the volume is changed while an ad is playing,
///    the user interacts with the ad, etc. Other components throughout the
///    SDK can register for and handle these events as they see fit. For
///    example, there is a `DelegatingMediaEventSubscriber` class that calls
///    corresponding ``PlayerDelegate`` functions when events are received.
class LivestreamPlayerObserver: PlayerObserver {

    // MARK: - Public Properties

    /// The number of seconds between checks for updated ad break data from the
    /// ad server. On the web and Android, this is hardcoded to 18 seconds, but
    /// I've made it 15 because some ads are shorter than 18 seconds.
    public var adBreakCheckInterval = TimeInterval(15.0) // seconds

    /// The livestream ad that's currently playing. This should be set when
    /// the ad starts, and set to `nil` when it ends.
    public var currentAd: LivestreamAd?

    // MARK: - Internal Properties

    /// The unique set of ads, keyed by ad ID.
    ///
    /// - seealso: ``LivestreamAd/hash(into:)``
    var ads = Set<LivestreamAd>()

    /// The unique set of ad breaks, keyed by `adBreakId`.
    var adBreaks: [String: LivestreamAdBreak] = [:]

    /// The boundary observer that checks for new ad break data every
    /// `adBreakCheckInterval` minutes. Only one is set at a time; when it
    /// fires, a new one is created for the next check.
    var adBreaksObserver: Any? {
        didSet(oldObserver) {
            if let oldObserver = oldObserver {
                ArcXPLogger.log("adBreaksObserver changed; removing old one: \(oldObserver)")
                player.removeTimeObserver(oldObserver)
            }

            if let newObserver = adBreaksObserver {
                ArcXPLogger.log("adBreaksObserver set to \(newObserver)")
            }
        }
    }

    /// The URL that's fetched every `adBreakCheckInterval` seconds to get
    /// updated  ``LivestreamAdBreak`` information. Setting this also sets up
    /// the player to fetch ad breaks at every interval.
    var adBreaksTrackingUrl: URL? {
        didSet {
            resetObservers()

            let updateInterval = CMTime(seconds: adBreakCheckInterval, preferredTimescale: 1)

            // Set up the ad break check heartbeat. The first check can't be
            // made until after the video stream has been fetched, so a timer
            // is set for 1/2 second after the video starts. This timer will
            // check for new ad breaks, and then check them repeatedly at
            // specified intervals.
            if adBreaksTrackingUrl != nil {
                // Set a new timer. The old one will be invalidated in the
                // firstAdBreakCheckTimer's didSet block.
                firstAdBreakCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                    ArcXPLogger.logIfNil(self)
                    self?.adBreaksObserver = self?.player.fire(every: updateInterval) { [weak self] _ in
                        ArcXPLogger.logIfNil(self)
                        self?.fetchAdBreakData()
                    }
                }
            }
        }
    }

    /// Reports Google Ad Manager programmatic ads through the PAL SDK.
    var palTracker: PALTracker?

    /// The video player `UIView`. This is used by the `PALTracker` and the
    /// Open Measurement ad session.
    private var playerView: UIView?

    // MARK: - Initialization

    /// Construct the observer with a player instance and optional delegate. If
    /// the delegate never gets set, then there's not much point to using an
    /// instance of this, but that's up to you.
    public init(player: AVPlayer,
                playerView: UIView? = nil) {
        self.playerView = playerView

        palTracker = PALTracker(playerView: playerView)
        super.init(player: player)

        MediaEventCenter.shared.addSubscriber(self)

        #if os(iOS)
        OMIDWashpostSDK.shared.activate()
        #endif
    }

    // MARK: - PlayerObserver Functions

    /// When the player's `AVPlayerItem` changes, get the livestream ad-tracking
    /// URL from the item's `adSettings`. This sets up the timer that will
    /// poll for ad updates at regular intervals.
    open override func currentPlayerItemChanged(from oldPlayerItem: AVPlayerItem?,
                                                to newPlayerItem: AVPlayerItem?) {
        super.currentPlayerItemChanged(from: oldPlayerItem, to: newPlayerItem)

        // Setting the adBreakCheckInterval sets up a timer to fetch them.
        if let arcVideo = newPlayerItem?.asset as? ArcVideo,
           let livestreamAdSettings = arcVideo.adSettings as? LivestreamAdSettings {
            adBreaksTrackingUrl = livestreamAdSettings.trackingUrl
        }

        palTracker?.requestNonceManager(videoDescriptionUrl: nil) // what should we use?
    }

    /// If an error occurred while an ad is playing, fire the ad's error event
    /// and call `AdDelegate.player(_:adInfo:adError:)` instead of
    /// `PlayerDelegate.player(_:error:)`.
    open override func errorChanged(to error: Error?) {
        if let currentAd = currentAd {
            currentAd.trackingEvent(ofType: .error)?
                .fire(currentAd, headers: livestreamAdHeaders(from: player.currentItem))
            MediaEventCenter.shared.sendEvent(.playerAdError(player, adInfo: currentAd, error: error))
        } else {
            super.errorChanged(to: error)
        }
    }

    /// Send ``MediaEvent/playerAdMuted(_:adInfo:)`` or
    /// ``MediaEvent/playerAdUnmuted(_:adInfo:)`` when the player is muted or
    /// unmuted.
    override func playerMutedOrUnmuted(_ player: AVPlayer) {
        guard let currentAd = currentAd else {
            super.playerMutedOrUnmuted(player)

            return
        }

        let trackingEvent: LivestreamAd.TrackingEvent?
        let mediaEvent: MediaEvent

        if player.isMuted {
            trackingEvent = currentAd.trackingEvent(ofType: .mute)
            mediaEvent = .playerAdMuted(player, adInfo: currentAd)
        } else {
            trackingEvent = currentAd.trackingEvent(ofType: .unmute)
            mediaEvent = .playerAdUnmuted(player, adInfo: currentAd)
        }

        trackingEvent?.fire(currentAd, headers: livestreamAdHeaders(from: player.currentItem))
        MediaEventCenter.shared.sendEvent(mediaEvent)
    }

    /// Send ``MediaEvent/playerAdVolumeChanged(_:adInfo:previousVolume:)``
    /// when the player's volume changes.
    override func player(volumeChangedFrom previousVolume: Float?) {
        guard let currentAd = currentAd else {
            super.player(volumeChangedFrom: previousVolume)

            return
        }

        // There is no tracking event for volume changes, AFAIK.
        MediaEventCenter.shared.sendEvent(.playerAdVolumeChanged(player,
                                                                 adInfo: currentAd,
                                                                 previousVolume: previousVolume))
    }

    /// If the playing is paused while an ad is playing, fire the ad's `paused`
    /// tracking event and send a `MediaEvent.playerAdPaused` to the event
    /// center.
    open override func playerPaused() {
        if let currentAd = currentAd {
            currentAd.trackingEvent(ofType: .pause)?.fire(currentAd,
                                                          headers: livestreamAdHeaders(from: player.currentItem))
            MediaEventCenter.shared.sendEvent(.playerAdPaused(player, adInfo: currentAd))
        } else {
            super.playerPaused()
        }
    }

    /// If the playing is unpaused while an ad is paused, fire the ad's `resume`
    /// tracking event and send a `MediaEvent.playerAdPlaying` to the event
    /// center.
    override func playerPlaying() {
        if let currentAd = currentAd {
            currentAd.trackingEvent(ofType: .resume)?
                .fire(currentAd, headers: livestreamAdHeaders(from: player.currentItem))
            MediaEventCenter.shared.sendEvent(.playerAdPlaying(player, adInfo: currentAd))
        } else {
            super.playerPlaying()
        }
    }

    /// If the player is tapped while an ad is playing, fire the ad's
    /// `.clickThrough` tracking event and call `AdDelegate.player(_:adTapped:)`
    /// instead of `PlayerDelegate.player(_:tapped:)`.
    open override func playerTapped() {
        if let currentAd = currentAd {
            currentAd.trackingEvent(ofType: .clickThrough)?
                .fire(currentAd, headers: livestreamAdHeaders(from: player.currentItem))
            MediaEventCenter.shared.sendEvent(.playerAdTapped(player, adInfo: currentAd))
            palTracker?.sendAdClick()
        } else {
            super.playerTapped()
        }
    }

    /// Call `super.start()`, then unsubscribe from the ``MediaEventCenter``.
    /// You **must** call this to prevent a memory leak when this observer
    /// would otherwise go out of scope.
    override func stop() {
        MediaEventCenter.shared.removeSubscriber(self)
        super.stop()
    }

    // MARK: - Processing Ad Breaks

    /// A map of all ad break observers for each ad break.
    var allAdBreakObservers = [LivestreamAdBreak: LivestreamAdBreakObservers]()

    /// Add a ``LivestreamAdBreak`` and create a `LivestreamAdBreakObservers`
    /// for it.
    private func addAdBreak(_ adBreak: LivestreamAdBreak) {
        guard let adBreakId = adBreak.adBreakId else {
            return
        }

        adBreaks[adBreakId] = adBreak

        let adBreakObserver = LivestreamAdBreakObservers(adBreak: adBreak,
                                               player: player,
                                               palTracker: palTracker)

        allAdBreakObservers[adBreak] = adBreakObserver
    }

    /// Remove a ``LivestreamAdBreak`` and its associated
    /// `LivestreamAdBreakObservers`.
    private func removeAdBreak(_ adBreak: LivestreamAdBreak) {
        if let adBreakObserver = allAdBreakObservers.removeValue(forKey: adBreak) {
            ArcXPLogger.log("Removing observers")
            adBreakObserver.cancel()
        }
    }

    /// Remove all the old adBreak observers, which cancels all of their
    /// boundary time observers on the `AVPlayer`.
    private func resetObservers() {
        allAdBreakObservers.values.forEach { (observers) in
            observers.cancel()
        }

        allAdBreakObservers.removeAll()
        adBreaks.removeAll()
    }

    // MARK: - Fetching Ad Break Data

    /// The timer that's fired to fetch ad break data for the first time after a
    /// stream begins.
    private var firstAdBreakCheckTimer: Timer? {
        didSet {
            oldValue?.invalidate()
        }
    }

    /// Fetch ad breaks from the `adBreaksTrackingUrl` and add them.
    private func fetchAdBreakData() {
        adBreaksTrackingUrl?.callAndExpectCodable { [weak self] (result: Result<LivestreamAdBreak.Response, Error>) in
            ArcXPLogger.logIfNil(self)
            switch result {
            case .success(let response):
                self?.handleSuccessfulAdBreakFetch(response.adBreaks)
            case .failure(let error):
                if let player = self?.player {
                    MediaEventCenter.shared.sendEvent(.playerAdError(player, adInfo: nil, error: error))
                }

                ArcXPLogger.log("Failed to get upcoming livestream ad break data", error: error)
            }
        }
    }

    /// Called by `fetchAdBreakData()` when the response is successful. All
    /// existing ad breaks and their observers are removed, and the new ones
    /// are added.
    private func handleSuccessfulAdBreakFetch(_ newAdBreaks: [LivestreamAdBreak]) {
        if newAdBreaks.isEmpty {
            ArcXPLogger.log("No upcoming ad breaks")
            return
        }

        ArcXPLogger.log("New ad breaks: \(newAdBreaks.count)")

        resetObservers()

        // Add all of the new ad breaks, even if some of them are the same as
        // ones that we just removed. It's just safer, and not particular
        // inefficient.
        newAdBreaks.forEach { [weak self] (adBreak) in
            ArcXPLogger.logIfNil(self)
            self?.addOrUpdateAdBreak(adBreak)
        }
    }

    /// Calls `addAdBreak(:)` for the `newAdBreak`. If there's already one with
    /// the same ID, the existing one is removed.
    private func addOrUpdateAdBreak(_ newAdBreak: LivestreamAdBreak) {
        addAdBreak(newAdBreak)
    }

    /// Return the player item's ``LivestreamAdSettings/beaconHeaders``, if
    /// any.
    private func livestreamAdHeaders(from item: AVPlayerItem?) -> [String: String] {
        guard let arcVideo = item?.asset as? ArcVideo,
              let adSettings = arcVideo.adSettings as? LivestreamAdSettings else {
            return [:]
        }

        return adSettings.livestreamBeaconHeaders
    }

    #if os(iOS)
    /// Create a new ``OpenMeasurementAdSession``. If there's an existing one,
    /// log it. (I can't remember why this important.)
    var openMeasurementAdSession: OpenMeasurementAdSession? {
        didSet {
            if let oldValue = oldValue {
                ArcXPLogger.log("Ending open measurement ad session \(oldValue)")
            }

            if let newSession = openMeasurementAdSession {
                ArcXPLogger.log("Starting open measurement ad session \(newSession)")
            }
        }
    }
    #endif

}

extension LivestreamPlayerObserver: MediaEventSubscriber {
// swiftlint: disable cyclomatic_complexity
    /// Handle ``MediaEvent``s  that trigger Open Measurement events.
    func receiveEvent(_ event: MediaEvent) {
        switch event {
        case .playerItemCompleted(_, item: _):
            palTracker?.sendPlaybackEnd()

        case .playerItemStarted(_, item: _):
            palTracker?.sendPlaybackStart()

        case .playerAdTapped(_, adInfo: _):
            palTracker?.sendAdClick()

        case .playerAdStarted(let player, let adInfo):
            if let adInfo = adInfo as? LivestreamAd {
                playerAdStarted(player, adInfo: adInfo)
            }
        case .playerAdCompleted(let player, let adInfo):
            if let adInfo = adInfo as? LivestreamAd {
                currentAd = nil
#if os(iOS)
                openMeasurementAdSession?.receiveEvent(.playerAdCompleted(player, adInfo: adInfo))
                openMeasurementAdSession = nil
#endif
            }

        case .playerAdError(_, let adInfo, error: _):
            if adInfo is LivestreamAd {
                currentAd = nil
            }
        case .playerBeganFullScreenPresentation(let player, _):
            MediaEventCenter.shared.sendEvent(
                MediaEvent.playerAdWentFullscreen(player, adInfo: currentAd)
            )

#if os(iOS)
            openMeasurementAdSession?.receiveEvent(.playerAdWentFullscreen(player, adInfo: currentAd))
#endif
        case .playerEndedFullScreenPresentation(let player, _):
            MediaEventCenter.shared.sendEvent(
                MediaEvent.playerAdReturnedToNormalSize(player, adInfo: currentAd)
            )

#if os(iOS)
            openMeasurementAdSession?.receiveEvent(.playerAdReturnedToNormalSize(player, adInfo: currentAd))
#endif
        default:
            return
        }
    }
// swiftlint: enable cyclomatic_complexity
    /// When a livestream ad starts, try to initialize an
    /// `OpenMeasurementAdSession` and fire a
    /// ``MediaEvent/playerAdStarted(_:adInfo:)`` event.
    private func playerAdStarted(_ player: AVPlayer, adInfo: LivestreamAd) {
        currentAd = adInfo

#if os(iOS)
        let scripts = adInfo.omidVerificationScriptResources

        if scripts.isEmpty {
            ArcXPLogger.log("No Open Measurement scripts were found in " +
                       "the livestream configuration, so no OM session will be created")
        } else {
            do {
                let adSession = try OpenMeasurementAdSession(vastVerificationScriptResources: scripts,
                                                             contentUrl: nil,
                                                             playerView: playerView)
                openMeasurementAdSession = adSession // so the lines above aren't too long
                openMeasurementAdSession?.receiveEvent(.playerAdStarted(player, adInfo: adInfo))
            } catch {
                ArcXPLogger.log("Failed to create an OpenMeasurementAdSession. " +
                           "This probably isn't an actual error; it usually " +
                           "means that no OM validation needs to be done for " +
                           "this ad. (\(error.localizedDescription))")
            }
        }
#endif
    }
}
// swiftlint: enable file_length
