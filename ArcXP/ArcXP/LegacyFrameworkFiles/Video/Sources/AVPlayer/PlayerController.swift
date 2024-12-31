//  Copyright © 2020 The Washington Post. All rights reserved.

import AVFoundation
import UIKit

/// Controls an `AVPlayer`'s playback functions, sets up pre-roll and
/// livestream ads (if applicable), and observes changes to the `AVPlayer`'s
/// properties in order to fire ``MediaEvent``s and call ``PlayerDelegate``
/// callbacks. By controlling playback with this controller, instead of
/// manipulating the `AVPlayer` directly, the framework ensures that ads and
/// callbacks are supported, regardless of which media player
/// (`ArcMediaPlayerViewController or `AVPlayerViewController`) is used.
public class PlayerController: NSObject {

    // MARK: - Public Properties

    /// Controls pre-roll ads, and mid-roll and post-roll ads for
    /// non-livestream videos.
    public var adController: AdController?

    /// Whether to show Google IMA or livestream ads.
    public var adsEnabled: Bool = false

    /// A delegate that tracks player lifecycle and ad and video playback
    /// events.
    public weak var delegate: PlayerDelegate? {
        didSet {
            guard let delegate = delegate else {
                delegatingEventSubscriber = nil

                return
            }

            delegatingEventSubscriber = DelegatingMediaEventSubscriber(delegate: delegate)
        }
    }

    /// The `DelegatingMediaEventSubscriber` that calls functions on the
    /// `delegate` for each corresponding ``MediaEvent``s that it receives.
    private var delegatingEventSubscriber: DelegatingMediaEventSubscriber? {
        didSet {
            if let oldSubscriber = oldValue {
                MediaEventCenter.shared.removeSubscriber(oldSubscriber)
            }

            if let newSubscriber = delegatingEventSubscriber {
                MediaEventCenter.shared.addSubscriber(newSubscriber)
            }
        }
    }

    /// The `AVPlayer` that this player controller controls. Note that it's
    /// `unowned` to avoid memory leaks, and because the player should always
    /// outlive any player controllers that use it.
    public unowned var player: AVPlayer

    /// Observes property changes in the `AVPlayer`.
    var playerObserver: PlayerObserver?

    /// The view controller that contains & owns this controller. It's
    /// `unowned` to avoid cyclical references.
    public unowned var viewController: UIViewController

    // MARK: - Initialization

    /// Construct the controller with an `AVPlayer` and the `UIViewController`
    /// that owns it.
    ///
    /// - parameter player: The `AVPlayer`, which this controller will hold as
    ///   `unowned`.
    /// - parameter viewController: The `UIViewController` that will own this
    ///   `PlayerController` instance. It will also be passed to the
    ///   `GoogleIMAAdController`.
    /// - parameter delegate: The `PlayerDelegate`, which is will be used to
    ///   make callbacks.
    public init(player: AVPlayer,
                playerView: UIView,
                containedInViewController viewController: UIViewController & PlayerControllerContainer,
                delegate: PlayerDelegate? = nil) {
        self.player = player
        self.delegate = delegate
        self.viewController = viewController
        super.init()

        self.adController = GoogleIMAAdController(presentingViewController: viewController,
                                                  playerController: self)
        self.playerObserver = LivestreamPlayerObserver(player: self.player,
                                                       playerView: playerView)

        addLifecycleObservers()
    }

    deinit {
        player.replaceCurrentItem(with: nil)
        playerObserver?.stop()

        // Setting the delegate to nil also unsubscribes the
        // delegatingMediaEventSubscriber from the shared MediaEventCenter.
        delegate = nil
    }

    /// Configure the ad settings. This simply passes the configuration to the
    /// ``adController``.
    ///
    /// - parameter config: The configuration.
    open func configureAds(_ config: ArcMediaAdConfig) {
        adController?.configure(config)
    }

    /// Request ads through ima sdk. This will load the ads and play.
    open func requestAds() {
        adController?.requestAds()
    }

    // MARK: - Load & Play

    /// `true` if the `AVPlayer.timeControlStatus` is `.playing`.
    public var isPlaying: Bool {
        return player.timeControlStatus == .playing
    }

    /// Load an `AVPlayerItem` in the `AVPlayer`, but don't play it.
    ///
    /// - parameter playerItem: The new item.
    open func load(playerItem: AVPlayerItem) {
        player.replaceCurrentItem(with: playerItem)

        if adsEnabled {
            // check for ad to configure
            if let arcVideo = playerItem.asset as? ArcVideo, let adTagUrl = arcVideo.adTagUrl {
                adController?.configure(adTagUrl: adTagUrl)
            }
        }
    }

    /// Pause the player if a Google IMA ad isn't playing.
    open func pause() {
        guard let adControllerIsPlaying = adController?.isAdPlaying,
              !adControllerIsPlaying else {
            return
        }

        // The PlayerObserver will fire a pause event for the item or
        // livestream ad.
        player.pause()
    }

    /// Play the player's current item, if a Google IMA ad isn't playing.
    open func play() {
        guard let adControllerIsPlaying = adController?.isAdPlaying,
              !adControllerIsPlaying else {
            return
        }

        // The PlayerObserver will fire a playing event for the item or
        // livestream ad.
        player.play()

        // Set the focus to the player view. This is required for the player
        // to receive TV remote-control events.
        viewController.setNeedsFocusUpdate()
    }

    /// Load and play a single item, including any ads that it may contain.
    /// Use this instead of  ``load(playerItem:)`` and ``play()`` if you don't need
    /// to do anything else in between those calls.
    ///
    /// - parameter playerItem: The new item for the player to play.
    open func play(playerItem: AVPlayerItem) {
        load(playerItem: playerItem)
        // When ads are enabled, just load the video and
        // the video will be played after ad is ended.
        if !adsEnabled {
            play()
        }
    }

    /// If the player is `.readyToPlay`, toggle it between ``play()`` and
    /// ``pause()``.
    public func togglePlayAndPause() {
        if player.status == .readyToPlay {
            switch player.timeControlStatus {
            case .paused:
                play()
            case .playing:
                pause()
            case .waitingToPlayAtSpecifiedRate:
                return
            @unknown default:
                return
            }
        }
    }

    // MARK: - Seek & Skip

    /// Set the playback point to the beginning of the current video.
    open func jumpToBeginning() {
        seek(to: 0.0)
    }

    /// Set the playback point to the end of the current video.
    open func jumpToEnd() {
        guard let endTime = player.currentItem?.endTime else {
            return
        }

        seek(to: endTime)
    }

    /// Jump to a specified playback percentage. This will have no effect if the
    /// player's current item is a livestream video.
    ///
    /// - parameter percent: The playback percentage to seek to. This must be between `0.0`
    ///    and `1.0`, inclusive.
    open func seek(to percent: Float) {
        let newTime = player.seek(to: percent)

        if let newTime = newTime,
           let currentItem = player.currentItem {
            MediaEventCenter.shared.sendEvent(.playerItemSkipped(player,
                                                                 item: currentItem,
                                                                 toTime: newTime))
        }
    }

    /// Jump to a specified playback time. This will have no effect if the
    /// player's current item is a livestream video.
    open func seek(to time: CMTime) {
        player.seek(to: time)

        if let currentItem = player.currentItem {
            MediaEventCenter.shared.sendEvent(.playerItemSkipped(player,
                                                                 item: currentItem,
                                                                 toTime: time))
        }
    }

    /// Jump back a specified number of seconds in the current video, or back to
    /// the beginning if the elapsed time is less than the interval.
    ///
    /// - parameter interval: The amount of time to skip backward.
    open func skipBackward(interval: CMTime) {
        let currentTime = player.currentTime()

        if currentTime > interval {
            seek(to: currentTime - interval)
        } else {
            jumpToBeginning()
        }
    }

    /// Jump forward a specified number seconds in the current video, or to
    /// the end if the remaining time is less than the interval.
    ///
    /// - parameter interval: The amount of time to skip forward.
    open func skipForward(interval: CMTime) {
        guard let currentItem = player.currentItem,
            let endTime = player.currentItem?.endTime else {
            return
        }

        if currentItem.isLive {
            jumpToEnd()
        } else {
            let currentTime = player.currentTime()
            let remainingTime = endTime - currentTime

            if remainingTime > interval {
                seek(to: currentTime + interval)
            } else {
                jumpToEnd()
            }
        }
    }

    // MARK: - Mute & Unmute

    /// `true` if the `player` is muted.
    public var isMuted: Bool {
        return player.isMuted
    }

    /// Mute the player.
    open func mute() {
        player.isMuted = true
    }

    /// Unmute the player.
    open func unmute() {
        player.isMuted = false
    }

    // MARK: - Key/Value Observing

    /// Observers for `NotificationCenter` notifications.
    private var lifecycleObservers = [AnyObject]()

    /// Add observers for the `UIApplication.willResignActiveNotification`,
    /// `.didBecomeActiveNotification`, and `.willTerminateNotification`
    /// notifications.
    private func addLifecycleObservers() {
        // Add app lifecycle notifications so that the player will pause when
        // the app is backgrounded.
        let notifier = NotificationCenter.default

        lifecycleObservers.append(
            notifier.addObserver(forName: UIApplication.willResignActiveNotification,
                                 object: nil,
                                 queue: nil) { [weak self] _ in
                                     ArcXPLogger.logIfNil(self)
                                     self?.pause()
                                 }
        )
        lifecycleObservers.append(
            notifier.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                 object: nil,
                                 queue: nil) { [weak self] _ in
                                     ArcXPLogger.logIfNil(self)
                                     self?.adController?.resumeAd()
                                 }
        )
        lifecycleObservers.append(
            notifier.addObserver(forName: UIApplication.willTerminateNotification,
                                 object: nil,
                                 queue: nil) { [weak self] _ in
                                     ArcXPLogger.logIfNil(self)
                                     self?.lifecycleObservers.forEach { (observer) in
                                         notifier.removeObserver(observer)
                                     }
                                 }
        )
    }

}

/// Deprecated name of the ``PlayerController``.
@available(*, deprecated, renamed: "PlayerController")
public typealias AVPlayerController = PlayerController
