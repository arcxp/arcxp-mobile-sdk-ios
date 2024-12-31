//  Copyright © 2020 The Washington Post. All rights reserved.

import GoogleInteractiveMediaAds
import UIKit
// swiftlint:disable file_length
/// The view controller for the custom ``ArcMediaPlayerView``. It's more
/// customizable than the `AVKit.AVPlayerViewController`, and it supports
/// on-demand videos that have client-side (i.e. Video Text Track, or VTT)
/// captions instead of embedded captions.
///
/// **Important note:** All of the player's UI is in the
/// ``ArcMediaPlayerView``, which is the root view of this view controller. All
/// of the view's *actions*, however, are here in the view controller, except
/// for superficial ones like showing and hiding the control bar.
public class ArcMediaPlayerViewController: UIViewController, PlayerControllerContainer {

    // MARK: - Public Properties

    /// Whether to show Google IMA ads.
    public var adsEnabled: Bool = false

    private var didRequestAds = false

    /// A delegate that tracks player lifecycle and ad and video playback
    /// events.
    public weak var delegate: PlayerDelegate? {
        didSet {
            playerController?.delegate = delegate
        }
    }

    /// The number of seconds to jump backward in the video. The default is
    /// `15.0`. Note that if you change this, you should also change the icon
    /// in the player, since the default one says `15`.
    public var goBackwardInterval = CMTime(seconds: -15.0, preferredTimescale: 1)

    /// The number of seconds to jump forward in the video. The default is
    /// `30.0`. Note that if you change this, you should also change the icon
    /// in the player, since the default one says `30`.
    public var goForwardInterval = CMTime(seconds: 30.0, preferredTimescale: 1)

    /// Indicates whether video playback is currently in progress.
    public var isPlaying: Bool {
        return playerController?.isPlaying ?? false
    }

    /// `true` if the asset `hasEmbeddedCaptions` or `hasClientSideCaptions`.
    public var isClosedCaptioningAvailable: Bool {
        return player.currentItem?.hasClosedCaptions ?? false
    }

    /// The `AVPlayer` that displays and controls the video content. Boundary
    /// time and periodic time observers are added to it to update the player
    /// UI and make callbacks to the ``delegate``.
    public var player = ArcPlayer()

    /// The root view, force-cast to an ``ArcMediaPlayerView``. Generally
    /// speaking, pure UI functions (like animations) are in the player view,
    /// and actions, like skipping and playing, are functions of the view
    /// controller.
    public var playerView: ArcMediaPlayerView {
        // swiftlint:disable force_cast
        return view as! ArcMediaPlayerView
        // swiftlint:enable force_cast
    }

    // MARK: - PlayerControllerContainer Properties

    /// The ``PlayerController`` that's used to control playback, including
    /// play, pause, and skip, and to change the volume.
    public var playerController: PlayerController?

    // MARK: - Internal Properties

    /// A boundary time observer that displays client-side (VTT) captions.
    /// Setting this will remove the existing caption observer, if any, so
    /// **do not** try to remove the existing one manually, because that will
    /// crash the player!
    private var clientSideCaptionsObserver: Any? {
        didSet(oldObserver) {
            if let oldObserver = oldObserver {
                ArcXPLogger.log("""
ArcMediaPlayerViewController: Removing a periodic time observer \n
\(oldObserver) for client-side captions.
""")
                player.removeTimeObserver(oldObserver)
            }
        }
    }

    // MARK: - Initialization

    /// Load an instance of the view controller from its storyboard. This
    /// allows the caller not to deal with bundles and `UIStoryboard`s
    /// directly. If the storyboard can't be found, or if its initial view
    /// controller isn't an `ArcMediaPlayerViewController`, then this will
    /// cause a `fatalError()`.
    public static func loadFromStoryboard() -> ArcMediaPlayerViewController {
        let className = String(describing: self)
        let storyboard = UIStoryboard(name: className,
                                      bundle: ArcXPSDK.bundle)

        guard let viewController = storyboard.instantiateInitialViewController(),
              let playerViewController = viewController as? Self else {
                  fatalError("Failed to load the \(className) from the \(className) storyboard")
              }

        return playerViewController
    }

    /// Remove the view controller from the `NotificationCenter` and nullify
    /// the `clientSideCaptionsObserver`.
    deinit {
        // Remove observers
        NotificationCenter.default.removeObserver(self)
        clientSideCaptionsObserver = nil
    }

    // MARK: - UIViewController Functions

    /// Reset the ``playerView``, then set up Google IMA Ads.
    override public func viewDidLoad() {
        super.viewDidLoad()
        playerView.player = self.player
        playerController = PlayerController(player: player,
                                            playerView: playerView,
                                            containedInViewController: self)
        playerController?.adsEnabled = adsEnabled
        MediaEventCenter.shared.addSubscriber(self)

        #if os(tvOS)
        addTVRemoteGestureRecognizers(view: self.view)
        #endif
    }

    /// As per the latest IMA framework updates, ads must be requested only in `ViewDidAppear`
    /// to avoid view hierarchy error for playing the ads
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Make the request only once the view has been instantiated.
        guard !didRequestAds,
              playerController?.adsEnabled ?? false else {
            // Resume the ad when the user closes the browser after visiting the ad webpage
            if let adController =  playerController?.adController,
               adController.isAdVisible,
               !adController.isAdPlaying {
                playerController?.adController?.resumeAd()
            }
            return
        }
        didRequestAds = true
        playerController?.requestAds()
    }

    /// Fire ``MediaEvent/playerAppeared(_:)``.
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MediaEventCenter.shared.sendEvent(.playerAppeared(player))
    }

    /// Pause the player when the view controller is no longer visible.
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.pause()
    }

    /// Update the dimensions of the player view when switching to full-screen
    /// mode.
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        #if os(iOS)
        // Update playerview if in full screen mode
        if playerView.isFullScreen {
            playerView.superview?.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            playerView.frame = playerView.superview!.frame
        }
        #endif
    }

    // MARK: - Actions

    /// Set the playback point to the beginning of the current video. The UI
    /// isn't updated here, but in the ``ArcMediaPlayerView``, when the view
    /// observes a change in the playback time.
    @IBAction func jumpToBeginning(sender: Any?) {
        playerController?.jumpToBeginning()
    }

    /// Set the playback point to the very end of the current video. The UI
    /// isn't updated here, but in the ``ArcMediaPlayerView``, when the view
    /// observes a change in the playback time.
    @IBAction func jumpToEnd(sender: Any?) {
        playerController?.jumpToEnd()
    }

    /// Toggle muting and unmuting the player, depending on the `player`'s
    /// current `isMuted` value. The mute button's UI state isn't updated here;
    /// instead, the ``ArcMediaPlayerView`` updates its state depending on
    /// whether ``MediaEvent/playerMuted(_:)`` or
    /// ``MediaEvent/playerUnmuted(_:)`` is received.
    @IBAction func mute(sender: UIButton) {
        if player.isMuted {
            playerController?.unmute()
        } else {
            playerController?.mute()
        }
    }

    /// Play or pause the current item in the queue. The UI isn't updated here,
    /// but in the ``ArcMediaPlayerView``, when the view observes a change in
    /// the `AVPlayerItem.status`.
    ///
    /// - parameter sender: The object that fired this action. This is currently
    ///   ignored.
    @IBAction func play(sender: Any?) {
        playerController?.togglePlayAndPause()

        // Set the focus to the player view. This is required for the player
        // to receive TV remote-control events.
        setNeedsFocusUpdate()
    }

    #if os(iOS)
    /// Jump to the playback point where the scrubber's thumb image is
    /// positioned.
    ///
    /// - parameter scrubber: The `UISlider` whose position is translated into
    ///   the number of seconds to which the playback will jump.
    @IBAction func seek(scrubber: UISlider) {
        playerController?.seek(to: scrubber.value)
    }
    #endif

    /// Jump back ``goBackwardInterval`` seconds in the current video, or back
    /// to the beginning if the elapsed time is less than the interval.
    ///
    /// - parameter sender: The object that fired this action. This is currently
    ///   ignored.
    @IBAction func skipBackward(sender: Any?) {
        playerController?.seek(to: player.currentTime() + goBackwardInterval)
    }

    /// Jump forward ``goForwardInterval`` seconds in the current video, or
    /// directly to the end, if the remaining time is less than the interval.
    ///
    /// - parameter sender: The object that fired this action. This is currently
    ///   ignored.
    @IBAction func skipForward(sender: Any?) {
        playerController?.seek(to: player.currentTime() + goForwardInterval)
    }

    // MARK: - Captioning

    /// Toggle captions on and off.
    @IBAction public func toggleClosedCaptions(sender: UIButton? = nil) {
        if playerView.isDisplayingClosedCaptions {
            hideClosedCaptions()
        } else {
            showClosedCaptions()
        }
    }

    /// Turn off closed captions, whether they're embedded or client-side
    /// (VTT). This will also call
    /// ``PlayerDelegate/playerCaptionsOff(_:)-m194``, even if they already
    /// _were_ off. It also saves a flag to `UserDefaults.standard` to that the
    /// captioning state is preserved between videos or between app launches.
    public func hideClosedCaptions() {
        guard let playerItem = player.currentItem else {
            return
        }

        // Embedded and client-side captions are handled differently.
        if playerItem.hasClientSideCaptions {
            playerView.showClientSideCaptions = false
        } else if playerItem.hasEmbeddedCaptions() {
            playerItem.hideEmbeddedCaptions()
        }

        playerView.isDisplayingClosedCaptions = false

        // Save the state so that it can be preserved for the next video.
        Settings.showClosedCaptions.set(false)
        MediaEventCenter.shared.sendEvent(.playerCaptionsOff(player))
    }

    /// Turn on closed captions, either embedded or client-side (VTT), if
    /// available. This will also call
    /// ``PlayerDelegate/player(_:captionsOn:)-9f9bz``, even if they already
    /// _were_ on. It also saves a flag to `UserDefaults.standard` to that the
    /// captioning state is preserved between videos or between app launches.
    public func showClosedCaptions() {
        // If client-side captions are available, they take precedence.
        guard let playerItem = player.currentItem else {
            return
        }

        var captionType: AVPlayerItem.CaptionType?

        if playerItem.hasClientSideCaptions {
            playerView.showClientSideCaptions = true
            captionType = .clientSide
        } else if playerItem.hasEmbeddedCaptions() {
            playerItem.showEmbeddedCaptions()
            captionType = .embedded(locale: AVPlayerItem.defaultLocale)
        }

        if let captionType = captionType {
            MediaEventCenter.shared.sendEvent(.playerCaptionsOn(player, captionType: captionType))
            playerView.isDisplayingClosedCaptions = true

            // Save the state so that it can be preserved for the next video.
            Settings.showClosedCaptions.set(true)
        } else {
            playerView.isDisplayingClosedCaptions = false
            // Don't set the Settings.showClosedCaptions to false, because the
            // next playerItem might have captions.
        }
    }

    /// Download the VTT client-side caption URL, if any.
    func downloadClientSideCaptionsIfAny(playerItem: AVPlayerItem) {
        guard let captionUrl = playerItem.clientSideCaptionsUrl else { return }

        URLRequest(endpoint: captionUrl, httpMethod: "GET").callAndExpectString { (result) in
            switch result {
            case .success(let captionResponse):
                self.parseVttCaptionsResponse(captionResponse: captionResponse)
            case .failure(let error):
                ArcXPLogger.log("Failed to get captions from \(captionUrl.absoluteString)",
                           error: error)
            }
        }
    }

    /// Parse the client-side VTT captions file and add boundary time
    /// observers to show each one in the player view.
    private func parseVttCaptionsResponse(captionResponse: String?) {
        guard let captionResponse = captionResponse else { return }
        let vttCues = VttParser.parse(vttPayload: captionResponse)

        if vttCues.count > 0 {
            let captionStartTimes = vttCues.map { $0.startTime }
            if !captionStartTimes.isEmpty {
                clientSideCaptionsObserver = player.fire(at: captionStartTimes) { [weak self] in
                    ArcXPLogger.logIfNil(self)
                    self?.selectClientSideCaption(from: vttCues)
                }
            }
        }
    }

    /// Update the client-side caption for the player's current time. Note that
    /// this is extremely time-sensitive, because if the player's current time
    /// doesn't exactly match one of the values in the `cues`, then nothing
    /// will happen.
    ///
    /// - parameters cues: The list of caption strings and their time cues.
    private func selectClientSideCaption(from cues: [Cue]) {
        let startTimeCues = cues.filter { String(format: "%.2f", $0.startTime) ==
            String(format: "%.2f", player.currentTime().seconds) }

        if let text = startTimeCues.first?.text {
            playerView.showClientSideCaption(text)
        }
    }

    // MARK: - TV Support (which should be moved to a subclass someday)

    /// When a video is playing, transfer focus to the ``playerView``.
    public override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if isPlaying {
            return [playerView]
        } else {
            return super.preferredFocusEnvironments
        }
    }

    /// Handle TV remote-control play and pause button clicks.
    ///
    /// - parameter view: Topmost view of the controller
    public func addTVRemoteGestureRecognizers(view: UIView) {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTvPlay))
        tapRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
        view.addGestureRecognizer(tapRecognizer)
    }

// swiftlint: disable void_function_in_ternary
    /// Toggle play and pause presses from the remote control. If an ad is
    /// playing, play or pause the ad.
    @objc private func handleTvPlay() {
        if let adController = playerController?.adController, adController.isAdVisible {
            adController.isAdPlaying ? adController.pauseAd() : adController.resumeAd()
        } else {
            play(sender: nil)
        }
    }
// swiftlint: enable void_function_in_ternary

    // MARK: - Private Functions

    /// Remove the `clientSideCaptionsObserver`.
    func resetObservers() {
        clientSideCaptionsObserver = nil
    }

}

extension ArcMediaPlayerViewController: MediaEventSubscriber {

    /// When the player item changes, download client-side captions (if any),
    /// and show or hide them.
    public func receiveEvent(_ event: MediaEvent) {
        switch event {
        case .playerCurrentItemChanged(let player, _):
            resetObservers()

            if let playerItem = player.currentItem {
                downloadClientSideCaptionsIfAny(playerItem: playerItem)

                // Preserve the captioning state between videos for iOS.
                //
                // For tvOS, as we don't have control bar, show cc by default
                // and let the client handle the behavior to show/hide by
                // calling the corresponding functions directly.
                #if os(iOS)
                if Settings.showClosedCaptions.get {
                    showClosedCaptions()
                } else {
                    hideClosedCaptions()
                }
                #else
                showClosedCaptions()
                #endif
            }
        default:
            return
        }
    }
}
// swiftlint:enable file_length
