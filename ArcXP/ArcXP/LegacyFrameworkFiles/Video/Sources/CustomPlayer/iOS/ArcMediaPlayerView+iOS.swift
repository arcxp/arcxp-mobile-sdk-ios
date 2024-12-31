//  Copyright © 2020 The Washington Post. All rights reserved.

import AVFoundation
import GoogleInteractiveMediaAds
import UIKit
import MediaPlayer

// swiftlint:disable file_length type_body_length

/// A customizable media player that plays ``ArcVideo``s. Instead of embedding
/// it directly in your app, embed its ``ArcMediaPlayerViewController`` and get
/// this view via the ``ArcMediaPlayerViewController/playerView`` property.
/// Most of its properties, controls, and subviews can be customized. See the
/// comments on each individual property, as well as the the sample app's
/// <doc:PlayerCustomization> documentation.
public final class ArcMediaPlayerView: ArcMediaPlayerBaseView {

    // MARK: - Public Outlets

    // Unless otherwise noted, most of these controls' actions are in the
    // ArcMediaPlayerViewController, NOT in this player view.

    /// The view that contains all the playback controls along the bottom of
    /// the video.
    @IBOutlet public weak var controlBar: UIView?

    /// The play button. (Why isn't it called `playButton`? Because there may
    /// also be a play button overlaid on the video content.)
    @IBOutlet public weak var controlBarPlayButton: UIButton?

    /// Toggle between full-screen and regular size. It fires
    /// `toggleFullscreen(sender:)`.
    @IBOutlet public weak var fullScreenButton: UIButton?

    /// Go to the beginning of the video. Tapping it calls
    /// `ArcMediaPlayerViewController.jumpToBeginning(sender:)`.
    @IBOutlet public weak var goBackwardButton: UIButton?

    /// Go to the end of the video. Tapping it calls
    /// `ArcMediaPlayerViewController.jumpToEnd(sender:)`.
    @IBOutlet public weak var goForwardButton: UIButton?

    /// Displays the playback progress. For livestreams, interactivity is
    /// disabled.
    @IBOutlet public weak var progressSlider: UISlider?

    /// Rewind the video by a certain number of seconds. Tapping it calls
    /// `ArcMediaPlayerViewController.skipBackward(sender:)`.
    ///
    /// **Note:** the default icon displays `15`. If you change this to an
    /// icon with a different value, you must _also_ set the
    /// ``ArcMediaPlayerViewController/goBackwardInterval`` to that same value.
    /// **Make sure you specify a *negative* number of seconds!**
    @IBOutlet public weak var skipBackwardButton: UIButton?

    /// Skip the video ahead by a certain number of seconds. Tapping it calls
    /// `ArcMediaPlayerViewController.skipForward(sender:)`.
    ///
    /// **Note:** the default icon displays `30`. If you change this to an
    /// icon with a different value, you must _also_ set the
    /// ``ArcMediaPlayerViewController/goForwardInterval`` to that same value.
    /// **Make sure you specify a *positive* number of seconds!**
    @IBOutlet public weak var skipForwardButton: UIButton?

    /// Shows the video's elapsed time.
    ///
    /// There are two formats that are used for the times: one with, and one
    /// without, the hours. (If ``alwaysShowHours`` is `true`, then the format
    /// with hours is always used.)
    @IBOutlet public weak var timeElapsedLabel: UILabel?

    /// Show the video's remaining time. If the video is a livestream, then
    /// the label will display "LIVE" instead of a time.
    ///
    /// There are two formats that are used for the times: one with, and one
    /// without, the hours. (If ``alwaysShowHours`` is `true`, then the format
    /// with hours is always used.)
    @IBOutlet public weak var timeRemainingLabel: UILabel?

    /// Pop up the ``volumeSlider`` when running on a device, or a message
    /// explaining that the slider isn't available in the simulator.
    @IBOutlet public weak var volumeButton: UIButton?

    /// A slider for changing the player volume. This appears only on a device,
    /// not the simulator.
    @IBOutlet public weak var volumeSlider: MPVolumeView?

    // MARK: - Private Outlets

    /// The button for selecting an AirPlay device.
    @IBOutlet private weak var airPlayView: AVRoutePickerView?

    /// If there's a long press on the volume button, this will show the
    /// volume slider.
    @IBOutlet private weak var longPressToShowVolumeSlider: UILongPressGestureRecognizer?

    /// The view that contains the ``volumeSlider``
    @IBOutlet private weak var volumeSliderContainer: UIView?

    /// A simulator-only view that appears where & when the volume slider would
    /// appear on a device.
    @IBOutlet private weak var volumeSliderMessage: UILabel? {
        didSet {
            #if !targetEnvironment(simulator)
            volumeSliderMessage?.removeFromSuperview()
            #endif
        }
    }

    // MARK: - Public Properties

    /// `true` if the time-elapsed/time-remaining label should always show the
    /// hours field. The default is `false`.
    public var alwaysShowHours = false

    /// The format string for the time-elapsed/time-remaining label when the
    /// time is less than one hour. The default is `mm:ss`. Examples are
    /// `-31:20` or `04:32`.
    public var durationFormat = "mm:ss" {
        didSet {
            durationFormatter.dateFormat = durationFormat
        }
    }

    /// The format string for the time-elapsed/time-remaining label when the
    /// time one hour or greater. The default is `H:mm:ss`. Examples are
    /// `-1:31:20` or `2:04:32`.
    public var durationFormatWithHours = "H:mm:ss" {
        didSet {
            durationFormatterWithHours.dateFormat = durationFormatWithHours
        }
    }

    /// Update the ``fullScreenButton``'s state to reflect this setting.
    public var isFullScreen: Bool = false {
        didSet {
            fullScreenButton?.isSelected = isFullScreen
        }
    }

    /// How often to update the playback progress bar. The default is 0.25
    /// seconds. Each update will be animated, so intervals less than 1 second
    /// will look best.
    public var progressUpdateInterval = CMTime(seconds: 1.0,
                                               preferredTimescale: 4)

    /// The number of seconds that the control bar is visible after playback
    /// starts. If this is `nil`, then the control bar **will not** be
    /// hidden automatically. Instead, you must call ``hideControlBar(sender:)``
    /// explicitly.
    public var secondsBeforeControlBarHides: Double? = 3.0

    /// Whether the ``skipBackwardButton`` will be displayed, even if the current
    /// video allows skipping.
    public var useSkipBackwardButton = true {
        didSet {
            skipBackwardButton?.isHidden.toggle()
        }
    }

    /// Whether the ``skipForwardButton`` will be displayed, even if the current
    /// video allows skipping.
    public var useSkipForwardButton = true {
        didSet {
            skipForwardButton?.isHidden.toggle()
        }
    }

    // MARK: - Internal Properties

    /// The shared system audio session, which the view observes for volume
    /// changes on.
    private let audioSession = AVAudioSession.sharedInstance()

    /// A timer that hides the control bar a few seconds after playing begins.
    private var controlBarTimer: Timer?

    /// Formats the time-elapsed/time-remaining label when the duration is
    /// under an hour.
    private lazy var durationFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = durationFormat

        return dateFormatter
    }()

    /// Formats the time-elapsed/time-remaining label when the duration is
    /// an hour or more.
    private lazy var durationFormatterWithHours: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = durationFormatWithHours

        return dateFormatter
    }()

    /// The periodic time observer that updates the elapsed and remaining time
    /// labels. Setting a new one will remove the old one from the player.
    private var elapsedTimePlaybackObserver: Any? {
        didSet(oldObserver) {
            if let oldObserver = oldObserver {
                ArcXPLogger.log("AVPlayer.removeTimeObserver(\(oldObserver)) for the elapsed time")
                player.removeTimeObserver(oldObserver)
            }
        }
    }

    /// Returned by calls to `AVPlayer.addPeriodicTimeObserver()`.
    /// It can be used to cancel observation when the videos are finished, or
    /// the video queue has been cleared.
    private var progressPlaybackObserver: Any? {
        didSet(oldObserver) {
            if let oldObserver = oldObserver {
                ArcXPLogger.log("AVPlayer.removeTimeObserver(\(oldObserver)) for the progress bar")
                player.removeTimeObserver(oldObserver)
            }
        }
    }

    /// Before the player view is in full-screen mode, this must be set to the
    /// view's superview. When returning to regular-size mode, the player view
    /// will be re-added to this view, and then this property will be reset to
    /// `nil`.
    private weak var superviewBeforeFullscreenMode: UIView?

    // MARK: - Initialization

    /// Set up the UI by setting the ``friendlyAdObstructions`` and subscribing
    /// to ``MediaEvent``s.
    override func initializeUI() {
        super.initializeUI()

        /// The text color for the client-side caption overlay text. The default
        /// value is `UIColor.white`. The color should contrast with the
        /// ``clientSideCaptionTextShadowColor`` so that it will show up clearly,
        /// no matter what the underlying video content looks like.
        clientSideCaptionTextColor = UIColor.white

        /// The text color for the client-side caption overlay text shadow. The
        /// default value is `UIColor.darkText`. It should contrast with the
        /// ``clientSideCaptionTextColor`` so that it will show up clearly, no
        /// matter what the underlying video content looks like.
        clientSideCaptionTextShadowColor = UIColor.darkText

        if let controlBar = controlBar {
            friendlyAdObstructions.append(
                FriendlyAdObstruction(view: controlBar, purpose: .mediaControls)
            )
        }

        if let playErrorMessageLabel = playErrorMessageLabel {
            friendlyAdObstructions.append(
                FriendlyAdObstruction(view: playErrorMessageLabel,
                                      purpose: .other(description: "Error message label"))
            )
        }

        if let captionsLabel = captionsLabel {
            friendlyAdObstructions.append(
                FriendlyAdObstruction(view: captionsLabel,
                                      purpose: .other(description: "Closed captions label"))
            )
        }
    }

    /// Invalidate observations.
    deinit {
        audioChangeObservation?.invalidate()
    }

    // MARK: - Actions

    /// Hide the control bar. Because the `sender` can be `nil`, this can be
    /// called either as an `IBAction`, or directly. The delegate's
    /// `playerViewControlBarWillDisppear()` and
    /// `playerViewControlBarDidDisappear`() are called before and after
    /// showing it, respectively.
    ///
    /// - parameter sender: The action's sender. It is ignored, and defaults to
    ///   `nil`.
    @IBAction public func hideControlBar(sender: Any? = nil) {
        guard let controlBar = controlBar else {
            return
        }

        delegate?.playerViewControlBarWillDisappear(self)

        UIView.animate(withDuration: 1.0,
                       delay: 0.0,
                       options: .curveEaseIn,
                       animations: { [weak self] in
                        controlBar.isHidden = true
                        ArcXPLogger.logIfNil(self)
                        self?.volumeSlider?.isHidden = true
            }, completion: { [weak self] _ in
                ArcXPLogger.logIfNil(self)

                if let strongSelf = self {
                    strongSelf.delegate?.playerViewControlBarDidDisappear(strongSelf)
                }
        })
    }

    /// Show the control bar. Because the `sender` can be `nil`, this can be
    /// called either as an `IBAction`, or directly. The delegate's
    /// `playerViewControlBarWillAppear()` and
    /// `playerViewControlBarDidAppear`() are called before and after showing
    /// it, respectively.
    ///
    /// - parameter sender: The action's sender. It is ignored, and defaults to
    ///   `nil`.
    @IBAction public func showControlBar(sender: Any? = nil) {
        guard let controlBar = controlBar else {
            return
        }

        delegate?.playerViewControlBarWillAppear(self)

        UIView.animate(withDuration: 1.0,
                       delay: 0.0,
                       options: .curveEaseIn,
                       animations: {
                        controlBar.isHidden = false
        }, completion: { [weak self] _ in
            ArcXPLogger.logIfNil(self)
            if let strongSelf = self {
                strongSelf.delegate?.playerViewControlBarDidAppear(strongSelf)
            }
        })
    }

    /// Toggle the volume slider.
    @IBAction private func showVolumeSlider(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            volumeSliderContainer?.isHidden = false

            #if targetEnvironment(simulator)
            volumeSliderMessage?.isHidden.toggle()
            #else
            volumeSlider?.isHidden.toggle()
            #endif
        }
    }

    /// If ``isFullScreen`` is `false`, expand the player view to fill the
    /// screen's frame. If it's `true`, return the player view to its original
    /// size and location. If the player view hasn't yet been added to the view
    /// hierarchy, do nothing.
    ///
    /// This also fires the relevant events.
    @IBAction func toggleFullscreen(sender: Any?) {
        guard let window = window else {
            return
        }

        if !isFullScreen {
            superviewBeforeFullscreenMode = superview

            let fullScreenView = UIView(frame: window.bounds)
            window.addSubview(fullScreenView)
            window.bringSubviewToFront(fullScreenView)

            fullScreenView.addSubview(self)
            self.constrainToFill(fullScreenView)

            MediaEventCenter.shared.sendEvent(
                .playerBeganFullScreenPresentation(player, item: player.currentItem)
            )
        } else {
            let fullScreenView = self.superview

            // Move ourselves from the fullScreenView back to the original
            // superview.
            if let originalSuperview = superviewBeforeFullscreenMode {
                originalSuperview.addSubview(self)
                self.constrainToFill(originalSuperview)
            }

            fullScreenView?.removeFromSuperview()

            MediaEventCenter.shared.sendEvent(
                .playerEndedFullScreenPresentation(player, item: player.currentItem)
            )
        }

        isFullScreen.toggle()
    }

    // MARK: - Captioning

    /// Toggles closed-captioning (if available) on and off. If captions
    /// (either client-side [VTT] or server-side [embedded]) aren't available,
    /// then this will be disabled. If they _are_ available, and activated, the
    /// button will be enabled; if not activated, the icon's alpha value will
    /// be 50%.
    ///
    /// It's connected to
    /// `ArcMediaPlayerViewController().showClosedCaptions()`.
    @IBOutlet public weak var closedCaptionsButton: UIButton? {
        didSet {
            closedCaptionsButton?.isEnabled = false
        }
    }

    /// Whether closed captions are being shown. Setting this changes the
    /// alpha of the ``closedCaptionsButton`` to `1.0`, if `true`, or `0.5`, if
    /// false.
    override public var isDisplayingClosedCaptions: Bool {
        didSet {
            // Adjust alpha for reflecting the states -- ON(1.0)/OFF(0.5)
            closedCaptionsButton?.alpha = isDisplayingClosedCaptions ? 1.0 : 0.5
        }
    }

    // MARK: - Private Functions

    /// Get a `time`'s string, with or without the hour value, depending on the
    /// value of ``alwaysShowHours``.
    ///
    /// - Parameters:
    ///   - time: The time to display.
    ///   - date: The current date.
    private func durationString(for time: CMTime,
                                onDate date: Date) -> String {
        if alwaysShowHours || time.seconds > 60.0 * 60.0 /* = 1 hour */ {
            return durationFormatterWithHours.string(from: date)
        } else {
            return durationFormatter.string(from: date)
        }
    }

    /// Called by the `playbackTimeObserver` at rapid intervals to update the
    /// progress bar. This function signature must match the signature of the
    /// `AVPlayer.addPeriodicTimeObserver`'s `using` block.
    ///
    /// - parameter progressTime: The current playback time.
    private func updateProgress(_ progressTime: CMTime) {
        guard let endTime = player.currentItem?.endTime else {
            return
        }

        let progress =  Float(progressTime.seconds / endTime.seconds)
        DispatchQueue.main.async { [weak self] in
            ArcXPLogger.logIfNil(self)
            self?.progressSlider?.setValue(progress, animated: true)
        }
    }

    /// Update the text of the ``timeElapsedLabel`` and ``timeRemainingLabel``
    /// with the current playback time.
    private func updateTimeLabels(_ progressTime: CMTime) {
        guard let duration = player.currentItem?.duration else {
            timeElapsedLabel?.text = "-:--"

            return
        }

        let midnightThisMorning = Calendar.current.startOfDay(for: Date())
        let elapsedDate = midnightThisMorning.addingTimeInterval(progressTime.seconds)
        let elapsedString = durationString(for: progressTime, onDate: elapsedDate)
        timeElapsedLabel?.text = elapsedString

        if duration.isIndefinite {
            timeRemainingLabel?.text = "LIVE"
        } else {
            let remainingTime = duration - progressTime
            let remainingDate = midnightThisMorning.addingTimeInterval(remainingTime.seconds)
            let remainingString = durationString(for: remainingTime, onDate: remainingDate)
            timeRemainingLabel?.text = "-\(remainingString)"
        }
    }

    /// Update the icon of the ``volumeButton`` to one of four states, based
    /// on the volume level.
    private func updateVolumeIcon() {
        let imageName: String

        switch audioSession.outputVolume {
        case 0.0:
            imageName = "volume-mute"
        case 0.0..<0.25:
            imageName = "volume-low"
        case 0.25..<0.75:
            imageName = "volume-medium"
        case 0.75...1.0:
            imageName = "volume-high"
        default:
            imageName = "volume-medium"
        }

        if let image = UIImage(named: imageName,
                               in: ArcXPSDK.bundle,
                               compatibleWith: nil) {
            volumeButton?.setImage(image, for: .normal)
        }
    }

    // MARK: - Key-Value Observing

    /// The observation for `audioSession` volume changes. When a new one is
    /// assigned, the old one is `invalidate()`d.
    private var audioChangeObservation: NSKeyValueObservation? {
        didSet {
            oldValue?.invalidate()
        }
    }

    /// Add a property observer for any audio session volume changes.
    private func startObservingVolumeChanges() {
        updateVolumeIcon()

        audioChangeObservation = audioSession.observe(\.outputVolume) { [weak self] (_, _) in
            ArcXPLogger.logIfNil(self)
            self?.updateVolumeIcon()
        }
    }

    // swiftlint:disable function_body_length

    /// Update the UI to reflect the current state of the player and player
    /// item. This includes the captions, progress bar, volume control, and
    /// playback button.
    private func updateUI() {
        captionsLabel?.backgroundColor = UIColor(white: 0, alpha: 0.5)
        progressSlider?.setValue(0.0, animated: false)
        volumeSlider?.isHidden = true

        if #available(iOS 13.0, *) {
            airPlayView?.tintColor = .label
            airPlayView?.activeTintColor = .systemBlue
        } else {
            airPlayView?.tintColor = .black
            airPlayView?.activeTintColor = .blue
        }

        do {
            try audioSession.setActive(true)
            startObservingVolumeChanges()
        } catch {
            ArcXPLogger.log("Failed to activate audio session", error: error)
        }

        goBackwardButton?.isHidden = true
        goForwardButton?.isHidden = true

        if let playerItem = player.currentItem {
            elapsedTimePlaybackObserver
                = player.fire(every: 1.0) { [weak self] (time) in
                    ArcXPLogger.logIfNil(self)
                    self?.updateTimeLabels(time)
                }
            ArcXPLogger.log("""
AVPlayer: Adding a periodic time observer \n
\(String(describing: elapsedTimePlaybackObserver)) every 1 second for the \n
elapsed time.
""")

            if playerItem.isLive {
                progressSlider?.value = 1.0

                if let observer = progressPlaybackObserver {
                    ArcXPLogger.log("""
AVPlayer: Removing a periodic time observer \(observer) for progress playback.
""")
                    player.removeTimeObserver(observer)
                    progressPlaybackObserver = nil
                }
            } else {
                progressPlaybackObserver
                    = player.fire(every: progressUpdateInterval) { [weak self] (time) in
                        ArcXPLogger.logIfNil(self)
                        self?.updateProgress(time)
                    }
                ArcXPLogger.log("""
AVPlayer: Adding a periodic time observer \(progressPlaybackObserver!) every \n
\(String(describing: time)) seconds for progress playback.
""")
            }

            closedCaptionsButton?.isEnabled = playerItem.hasClosedCaptions
            controlBarPlayButton?.isEnabled = true

            if playerItem.isLive {
                skipBackwardButton?.isHidden = true
                skipForwardButton?.isHidden = true
            } else {
                skipForwardButton?.isHidden.toggle()
                skipBackwardButton?.isHidden.toggle()
            }

            progressSlider?.isEnabled = !playerItem.isLive

            // Time labels shouldn't be updated here because the media may
            // not be ready yet. Instead, they're updated when key-value
            // observation indicates that the media is ready.
        } else {
            elapsedTimePlaybackObserver = nil
            progressPlaybackObserver = nil
            timeElapsedLabel?.text = "-:--"
            timeRemainingLabel?.text = "-:--"
            closedCaptionsButton?.isEnabled = false
            controlBarPlayButton?.isEnabled = false
        }
    }

    // swiftlint:enable function_body_length

    /// Respond to item-changed, muted, unmuted, paused, and unpaused events.
    override public func receiveEvent(_ event: MediaEvent) {
        super.receiveEvent(event)

        switch event {
        case .playerCurrentItemChanged:
            updateUI()
        case .playerMuted:
            volumeSliderContainer?.isHidden = true
            volumeButton?.isSelected = true
        case .playerUnmuted:
            volumeSliderContainer?.isHidden = true
            volumeButton?.isSelected = false
        case .playerPaused:
            controlBarPlayButton?.isSelected = false
            showControlBar(sender: self)
        case .playerPlaying:
            controlBarPlayButton?.isSelected = true
            controlBarTimer?.invalidate()

            if let controlBar = controlBar,
               !controlBar.isHidden,
               let secondsBeforeControlBarHides = secondsBeforeControlBarHides {
                // Setting `secondsBeforeControlBarHides` to `nil` causes no
                // timer to be set.
                let timeInterval = TimeInterval(secondsBeforeControlBarHides)
                controlBarTimer = Timer.scheduledTimer(timeInterval: timeInterval,
                                                       target: self,
                                                       selector: #selector(hideControlBar(sender:)),
                                                       userInfo: nil,
                                                       repeats: false)
            }
        default:
            return
        }
    }

}

extension UIView {

    /// Add constraints between this view and `otherView` so that all four edges
    /// are always equal. Why isn't this part of UIKit already?
    func constrainToFill(_ otherView: UIView) {
        self.leadingAnchor.constraint(equalTo: otherView.leadingAnchor).isActive = true
        self.topAnchor.constraint(equalTo: otherView.topAnchor).isActive = true
        self.trailingAnchor.constraint(equalTo: otherView.trailingAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: otherView.bottomAnchor).isActive = true
    }

}
// swiftlint:enable file_length type_body_length
