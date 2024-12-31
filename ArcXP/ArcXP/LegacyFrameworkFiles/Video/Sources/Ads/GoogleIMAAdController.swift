//  Copyright © 2020 The Washington Post. All rights reserved.

import AVFoundation
import GoogleInteractiveMediaAds
import UIKit

/// An ``AdController`` that manages pre- and post-roll ads from the Google IMA
/// SDK. There should be only a single instance *per view controller*, as all
/// of its external properties (that is, properties that were set by passing
/// arguments to the initializer) are declared `weak` to avoid retain cycles.
public class GoogleIMAAdController: NSObject, AdController {

    // MARK: - Public Properties

    /// A view which is passed to the `IMAAdDisplayContainer` for rendering
    /// ads on top of. This should be the view that contains the `AVPlayer`.
    public private(set) weak var adDisplayContainerView: UIView!

    /// Loads Google IMA ads and sets up the ad display view that's overlaid on
    /// the video player. **Note:** There should be only one instance of this
    /// in the entire app, so it's only set up in this view controller if it's
    /// still `nil` when `viewDidLoad()` is called.
    public private(set) var adsLoader: IMAAdsLoader?

    /// Manages Google IMA ads.
    public private(set) var adsManager: IMAAdsManager?

    /// The Google IMA ad tag URL. This contains all of the configuration
    /// information for how many ads to display, what type of ads, etc.
    /// https://support.google.com/admanager/answer/1068325 explains what this
    /// URL's parameters can be.'
    public var adTagUrl: URL?

    /// Tracks playback status for Google IMA ads.
    public private(set) var contentPlayhead: IMAAVPlayerContentPlayhead?

    /// The `AVPlayer` whose progress is monitored by the `contentPlayhead`.
    public var player: AVPlayer {
        return playerController.player
    }

    /// The ``PlayerController`` that owns this ad controller.
    /// ``PlayerController/play()`` is called when a Google ad has completed.
    public weak var playerController: PlayerController!

    /// The `UIViewController` that Google IMA will use to display modal view
    /// controllers or open web content from.
    public weak var presentingViewController: UIViewController?

    /// The view controller that will present a modal web page if the user taps
    /// the **Learn More** button in the ad.
    public private(set) weak var webOpenerPresentingController: UIViewController! {
        didSet {
            adDisplayContainerView = webOpenerPresentingController.view
        }
    }

    // MARK: - Initialization

    /// Create the ad manager.
    ///
    /// - paramter adsLoader: The Google `IMAAdsLoader`. Since there must be
    ///   only a single instance of this class in the app, callers should pass
    ///   in the instance; if there isn't one, one will be created in this
    ///   initializer, and can be used elsewhere.
    /// - parameter presentingViewController: The view controller that will
    ///   present a modal web page if the user taps the **Learn More** button
    ///   in the ad.
    /// - parameter player: The `AVPlayer`, which will be controlled by the
    ///   Google `IMAAdManager` while an ad is playing.
    public init(adsLoader: IMAAdsLoader = IMAAdsLoader(settings: nil),
                presentingViewController: UIViewController,
                playerController: PlayerController) {
        self.adsLoader = adsLoader
        self.presentingViewController = presentingViewController
        self.adDisplayContainerView = presentingViewController.view
        self.playerController = playerController
        self.webOpenerPresentingController = presentingViewController

        super.init()
    }

    // MARK: - AdController Functions

    /// Configure the ad settings. This currently sets only the Google IMA
    /// ad tag URL that will be used by default for all videos. Individual
    /// ``ArcVideo``s can specify their own ad tag URL to be used instead.
    ///
    /// - note: This is a function, not a property, so that it can be applied
    ///   and not stored.
    ///
    /// - parameter config: The configuration. If it contains separate entries
    ///   for tvOS & iOS, those will be used; otherwise, the
    /// ``ArcMediaAdConfig/adConfigUrl`` will be used.
    public func configure(_ config: ArcMediaAdConfig) {
        // config.adEnabled isn't used here; it's used by the caller to
        // determine whether to even use this ad controller in the first
        // place.
        adTagUrl = config.adConfigUrl
    }

    /// Set the default configuration for IMA ads. Sample config URLs can be
    /// found at Google's [IMA sample
    /// tags](https://developers.google.com/interactive-media-ads/docs/sdks/ios/client-side/tags).
    /// Note that individual ``ArcVideo`` objects can have their own ad config
    /// URLs, which will take precedence over this default ``adTagUrl``.
    ///
    /// - parameter adTagUrl: The `URL` for configuring the ad that will be
    ///   shown.
    public func configure(adTagUrl: URL) {
        self.adTagUrl = adTagUrl
    }

    /// Make the asynchronous request for ad content. When content is received
    /// (or an error occurs), the `IMAAdsLoaderDelegate`'s functions are called
    /// to handle it. This should be called just before or when a video starts.
    /// In some cases, the real content will play briefly before the ad
    /// appears; there doesn't seem to be any way around that.
    public func requestAds() {
        setUpAdsContent()
        guard let adRequestUrl = adTagUrl?.absoluteString else {
            // No ads will be shown. Do we want to add a delegate call for
            // this? Maybe it's entirely intentional.
            return
        }

        // Create an ad display container for ad rendering.
        let adDisplayContainer = IMAAdDisplayContainer(adContainer: adDisplayContainerView,
                                                       viewController: presentingViewController)

        if let obstructions = (adDisplayContainerView as? ArcMediaPlayerView)?.friendlyAdObstructions {
            for obstruction in obstructions {
                obstruction.register(with: adDisplayContainer)
            }
        }

        // Create an ad request with our ad tag, display container, and
        // optional user context.
        let request = IMAAdsRequest(adTagUrl: adRequestUrl,
                                    adDisplayContainer: adDisplayContainer,
                                    contentPlayhead: contentPlayhead,
                                    userContext: nil)

        adsLoader?.requestAds(with: request)
    }

    // MARK: - Play & Pause

    /// `true` if an ad is on the screen right now, whether it's playing or
    /// paused.
    public var isAdVisible: Bool = false

    /// `true` if an ad is currently on the screen and not paused.
    public var isAdPlaying: Bool = false

    /// Tell the `IMAAdsManager` to `pause()`.
    public func pauseAd() {
        adsManager?.pause()
    }

    /// Tell the `IMAAdsManager` to `resume()`.
    public func resumeAd() {
        adsManager?.resume()
    }

    /// Tell the `IMAAdsManager` to `destory()`.
    private func destroyAd() {
        adsManager?.destroy()
    }

    /// Tell the ``PlayerController`` to resume playing. Note that we're not just
    /// telling the player controller's _player_ to resume, because the player
    /// controller may need to do other things (like load client-side captions).
    public func resumeContent() {
        // Mark the ad player as not visible BEFORE telling the playerController
        // to play; otherwise, the playerController will think that the ad is
        // still visible, and do nothing.
        isAdPlayerVisible = false
        playerController.play()
    }

    // MARK: - Private Functions

    /// Notify the ad loader that the video has finished playing.
    @objc private func contentFinishedPlaying(notification: NSNotification) {
        // Only handle our *own* player's item completion, not the Google IMA
        // player's ad completion.
        if let currentItem = player.currentItem,
            let notificationItem = notification.object as? AVPlayerItem,
            currentItem === notificationItem {
            adsLoader?.contentComplete()
        }
    }

    /// Configure the IMA content playhead, which monitors the progress of the
    /// video to determine when ads should be played, and add a notification
    /// handler for when the video content is finished playing.
    private func setUpAdsContent() {
        // Set up the Google IMA ad stuff.
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: player)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentFinishedPlaying(notification:)),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: player.currentItem)

        adsLoader?.delegate = self
    }

    /// Set both `isAdVisible` and `isAdPlaying` to the specified value.
    private var isAdPlayerVisible: Bool = false {
        didSet {
            isAdVisible = isAdPlayerVisible
            isAdPlaying = isAdPlayerVisible
        }
    }

}

// MARK: - IMAAdsLoaderDelegate

extension GoogleIMAAdController: IMAAdsLoaderDelegate {

    //// Called when ads are successfully loaded from the ad servers by the
    /// loader. The manager's delegate is set to `self` and ad-rendering
    /// settings are initialized with the `webOpenerPresentingController`.
    public func adsLoader(_ loader: IMAAdsLoader,
                          adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        adsManager = adsLoadedData.adsManager
        adsManager?.delegate = self

        // Create ads rendering settings and tell the SDK to use the in-app
        // browser.
        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsRenderingSettings.linkOpenerPresentingController = webOpenerPresentingController
        adsRenderingSettings.linkOpenerDelegate = self

        // Initialize the ads manager.
        adsManager?.initialize(with: adsRenderingSettings)
    }

    /// Send a ``MediaEvent/playerAdError(_:adInfo:error:)`` and resume playing
    /// the non-ad content.
    public func adsLoader(_ loader: IMAAdsLoader,
                          failedWith adErrorData: IMAAdLoadingErrorData) {
        // IMAAdLoadingErrors aren't NSErrors. Seriously, Google?
        let error = ArcMediaAdError(withIMAAdError: adErrorData.adError)
        MediaEventCenter.shared.sendEvent(.playerAdError(player, adInfo: nil, error: error))
        destroyAd()
        resumeContent()
    }

}

// MARK: - IMAAdsManagerDelegate

extension GoogleIMAAdController: IMAAdsManagerDelegate {

    /// Handle IMA callbacks for playback milestones, video loading, and user
    /// interaction. Most of these send corresponding ``MediaEvent``s.
    /// `.LOADED` also starts the Google IMA ad manager.
    public func adsManager(_ adsManager: IMAAdsManager,
                           didReceive event: IMAAdEvent) {
        // swiftlint:disable identifier_name
        let ad = event.ad

        switch event.type {
        // Playback
        case .FIRST_QUARTILE:
            MediaEventCenter.shared.sendEvent(.playerAdPlayed25Percent(player, adInfo: ad))
        case .MIDPOINT:
            MediaEventCenter.shared.sendEvent(.playerAdPlayed50Percent(player, adInfo: ad))
        case .THIRD_QUARTILE:
            MediaEventCenter.shared.sendEvent(.playerAdPlayed75Percent(player, adInfo: ad))
        // Lifecycle
        case .LOADED:
            // When the SDK notifies us that ads have been loaded, play them.
            MediaEventCenter.shared.sendEvent(.playerAdStarted(player, adInfo: ad))
            adsManager.start()
        // User Interaction
        case .PAUSE:
            MediaEventCenter.shared.sendEvent(.playerAdPaused(player, adInfo: ad))
            isAdPlaying = false
        case .RESUME:
            MediaEventCenter.shared.sendEvent(.playerAdPlaying(player, adInfo: ad))
            isAdPlaying = true
            isAdVisible = true
        case .SKIPPED:
            MediaEventCenter.shared.sendEvent(.playerAdSkipped(player, adInfo: ad))
            isAdPlaying = false
            isAdVisible = false
        case .TAPPED:
            MediaEventCenter.shared.sendEvent(.playerAdTapped(player, adInfo: ad))
        case .CLICKED:
            MediaEventCenter.shared.sendEvent((.playerAdClicked(player, adInfo: ad)))
        default:
            return
        }
        // swiftlint:enable identifier_name
    }

    /// Handle an ad error by sending a
    /// ``MediaEvent/playerAdError(_:adInfo:error:)`` and resuming the video.
    public func adsManager(_ adsManager: IMAAdsManager,
                           didReceive adError: IMAAdError) {
        // Something went wrong with the ads manager after ads were loaded.
        isAdPlaying = false
        isAdVisible = false
        let error = ArcMediaAdError(withIMAAdError: adError)
        MediaEventCenter.shared.sendEvent(.playerAdError(player, adInfo: nil, error: error))
        resumeContent()
    }

    /// Called just before the ad is about to play.
    public func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
        // Pause the content while an ad plays.
        player.pause()
        isAdPlayerVisible = true
    }

    /// Called when the ad is finished.
    public func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
        // The SDK is done playing its current ad, so resume the content.
        MediaEventCenter.shared.sendEvent(.playerAdCompleted(player, adInfo: adsManager.adPlaybackInfo))
        resumeContent()

        // For LIVE, jump to the current live position
        if let item = player.currentItem, item.isLive {
            player.jumpToEnd()
        }
    }
}

// MARK: - IMALinkOpenerDelegate

extension GoogleIMAAdController: IMALinkOpenerDelegate {

    public func linkOpenerWillOpenExternalApplication(_ linkOpener: NSObject) {
        MediaEventCenter.shared.sendEvent(.playerAdWillOpenExternalApplication(player: player))
    }

    public func linkOpenerWillOpen(inAppLink linkOpener: NSObject) {
        MediaEventCenter.shared.sendEvent(.playerAdWillOpenInAppLink(player: player))
    }

    public func linkOpenerDidOpen(inAppLink linkOpener: NSObject) {
        MediaEventCenter.shared.sendEvent(.playerAdDidOpenInAppLink(player: player))
    }

    public func linkOpenerWillClose(inAppLink linkOpener: NSObject) {
        MediaEventCenter.shared.sendEvent(.playerAdWillCloseInAppLink(player: player))
    }

    public func linkOpenerDidClose(inAppLink linkOpener: NSObject) {
        MediaEventCenter.shared.sendEvent(.playerAdDidCloseInAppLink(player: player))
    }
}
