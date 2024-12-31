//  Copyright © 2020 The Washington Post. All rights reserved.

import AVFoundation
import Foundation
// swiftlint: disable file_length
/// Observes `AVPlayer` and `AVPlayerItem` property changes and calls functions
/// when they change.
///
/// Property | Change Function
/// -- | --
/// `AVPlayerItem.status` | `playerItemStatusChanged(from:to:)`
/// `AVPlayer.currentItem` | `currentPlayerItemChanged(from:to:)`
/// `AVPlayer.error` | `errorChanged(to:)`
/// `AVPlayer.isMuted` | `playerMutedOrUnmuted(_:)`
/// `AVPlayer.status` | `playerStatusChanged(from:to:)`
/// `AVPlayer.timeControlStatus` | `playerTimeControlStatusChanged(from:to:)`
/// `AVPlayer.volume` | `player(volumeChangedFrom:)`
///
/// Most of these observation functions are empty, so subclasses should override
/// them as needed.
class PlayerObserver: NSObject {

    // MARK: - Open Properties

    /// The player being observed.
    private(set) var player: AVPlayer

    // MARK: - Internal Properties

    /// The time observer that's fired when an `AVPlayerItem` starts playing.
    private var startObserver: Any? {
        didSet {
            if let oldObserver = oldValue {
                ArcXPLogger.log("AVPlayer.removeTimeObserver(\(oldObserver)) for the player item starting")
                player.removeTimeObserver(oldObserver)
            }
        }
    }

    /// The paths of the properties that this observer is observing. They must
    /// all be un-observed when this observer is finished.
    private let observedPaths: [String]

    // MARK: - Initialization

    /// Construct an observer for an `AVPlayer`. It sets up observations for
    /// several of the player's properties. Note that it does **not** set up
    /// observations for any `AVPlayerItem`s yet; that happens when the
    /// player's `currentItem` property changes.
    init(player: AVPlayer) {
        self.player = player

        ArcXPLogger.log("Initializing a PlayerObserver for player \(player)")
        // The paths being observed. Note that AVPlayerItem.status isn't
        // listed here, because it's added and removed in
        // currentPlayerItemChanged().
        observedPaths = [
            #keyPath(AVPlayer.currentItem),
            #keyPath(AVPlayer.error),
            #keyPath(AVPlayer.isMuted),
            #keyPath(AVPlayer.timeControlStatus),
            #keyPath(AVPlayer.volume)
        ]

        super.init()

        observedPaths.forEach { (path) in
            self.player.addObserver(self,
                                    forKeyPath: path,
                                    options: [.old, .new],
                                    context: nil)
        }
    }

    /// Remove all observers for the `observedPaths`.
    func stop() {
        observedPaths.forEach { (path) in
            player.removeObserver(self, forKeyPath: path)
        }

        // There is no need to remove observers from the `NotificationCenter`
        // that were added with addObserver(_:selector:name:object:).
        // https://developer.apple.com/documentation/foundation/notificationcenter/1415360-addobserver
    }

    // MARK: - Playback Complete

    /// Handle a notification that a non-livestream video has played to
    /// completion by calling `playbackEnded(item:)`.
    @objc func contentFinishedPlaying(notification: NSNotification) {
        playbackEnded(item: notification.object as? AVPlayerItem)

        // Remove the notification observer that sent this.
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                  object: player.currentItem)
    }

    // MARK: - NSObject Overrides

    // swiftlint:disable block_based_kvo
    /// Observe changes to one of the `AVPlayer` or `AVPlayerItem` key paths.
    /// Each key path has a corresponding handler function that's called with
    /// the old and new values.
    /// Swiftlint warns that the new, block-style keypath observations should
    /// be used instead, but those don't work consistently across all
    /// supported iOS versions, and sometimes crash.
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        let newValue = change?[.newKey]
        let oldValue = change?[.oldKey]

        switch keyPath {
        case #keyPath(AVPlayerItem.status):
            playerItemStatusChanged(from: oldValue, to: newValue)
        case #keyPath(AVPlayer.currentItem):
            currentPlayerItemChanged(from: oldValue as? AVPlayerItem,
                                     to: newValue as? AVPlayerItem)
        case #keyPath(AVPlayer.error):
            errorChanged(to: newValue as? Error)
        case #keyPath(AVPlayer.isMuted):
            playerMutedOrUnmuted(player)
        case #keyPath(AVPlayer.status):
            playerStatusChanged(from: oldValue, to: newValue)
        case #keyPath(AVPlayer.timeControlStatus):
            playerTimeControlStatusChanged(from: oldValue, to: newValue)
        case #keyPath(AVPlayer.volume):
            player(volumeChangedFrom: oldValue as? Float)
        default:
            // This will crash with a warning that there's an unhandled
            // observation.
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
        }
    }
    // swiftlint:enable block_based_kvo

    // MARK: - AVPlayer.currentItem

    /// Called when the `AVPlayer`'s `currentItem` changes. It removes any
    /// existing observer for the old item's `status` and adds an observer for
    /// the new one's.
    func currentPlayerItemChanged(from oldPlayerItem: AVPlayerItem?,
                                  to newPlayerItem: AVPlayerItem?) {
        // Clear out everything that observes the oldPlayerItem
        oldPlayerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        startObserver = nil
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: oldPlayerItem)

        // Set up an observer for when the item is ready to play.
        newPlayerItem?.addObserver(self,
                                   forKeyPath: #keyPath(AVPlayerItem.status),
                                   options: [.old, .new],
                                   context: nil)

        // Track the start of the video...
        startObserver = player.fire(at: 1.0) { [weak self] in
            ArcXPLogger.logIfNil(self)
            self?.playbackStarted(item: newPlayerItem)
        }

        // ...and the end.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentFinishedPlaying(notification:)),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: player.currentItem)

        // Notify the event center that the item changed.
        MediaEventCenter.shared.sendEvent(.playerCurrentItemChanged(player, fromOldItem: oldPlayerItem))
    }

    // MARK: - AVPlayer.error

    /// Send a ``MediaEvent/playerError(_:error:)``  event when the `AVPlayer`'s
    /// `error` value changes.
    func errorChanged(to error: Error?) {
        MediaEventCenter.shared.sendEvent(.playerError(player, error: error))
    }

    // MARK: - AVPlayer.isMuted & .volume

    /// Send a ``MediaEvent/playerMuted(_:)`` or
    /// ``MediaEvent/playerUnmuted(_:)`` event when the player is muted or
    /// unmuted.
    func playerMutedOrUnmuted(_ player: AVPlayer) {
        if player.isMuted {
            MediaEventCenter.shared.sendEvent(.playerMuted(player))
        } else {
            MediaEventCenter.shared.sendEvent(.playerUnmuted(player))
        }
    }

    /// Send a ``MediaEvent/playerVolumedChanged(_:previousVolume:)`` event when
    /// the player's volume changes.
    ///
    /// - parameter previousVolume: The volume of the player before it was
    ///   changed. The current volume can be checked by getting `player.volume`.
    func player(volumeChangedFrom previousVolume: Float?) {
        MediaEventCenter.shared.sendEvent(.playerVolumedChanged(player, previousVolume: previousVolume))
    }

    // MARK: - AVPlayer.timeControlStatus (i.e. play/pause)

    /// Converts raw `Any?` values from the key-value observer into
    /// `AVPlayer.TimeControlStatus` values, then calls the other
    /// `playerTimeControlStatusChanged(from:to:)`.
    private func playerTimeControlStatusChanged(from oldValue: Any?,
                                                to newValue: Any?) {
        let oldStatus = AVPlayer.TimeControlStatus.from(anyNumber: oldValue)
        let newStatus = AVPlayer.TimeControlStatus.from(anyNumber: newValue)
        playerTimeControlStatusChanged(from: oldStatus, to: newStatus)
    }

    /// Call `playerPaused()`, `playerPlaying()`, or `playerWaiting()` when the
    /// `AVPlayer.timeControlStatus` changes.
    ///
    /// - parameter oldStatus: The previous status, if any.
    /// - parameter newStatus: The current status, if any.
    private func playerTimeControlStatusChanged(from oldStatus: AVPlayer.TimeControlStatus?,
                                                to newStatus: AVPlayer.TimeControlStatus?) {
        // Is this necessary? Can we just call guard newStatus != oldStatus?
        guard oldStatus != newStatus,
            let newStatus = newStatus else {
                return
        }

        switch newStatus {
        case .paused:
            playerPaused()
        case .playing:
            playerPlaying()
        case .waitingToPlayAtSpecifiedRate:
            playerWaiting()
        default:  // for future values
            return
        }
    }

    /// Send a ``MediaEvent/playerPaused(_:item:)`` event when the
    /// `AVPlayer.timeControlStatus` changes to `.paused`.
    func playerPaused() {
        MediaEventCenter.shared.sendEvent(.playerPaused(player, item: player.currentItem))
    }

    /// Send a ``MediaEvent/playerPlaying(_:item:)`` event when the
    /// `AVPlayer.timeControlStatus` changes to `.playing`.
    func playerPlaying() {
        MediaEventCenter.shared.sendEvent(.playerPlaying(player, item: player.currentItem))
    }

    /// Send a ``MediaEvent/playerWaiting(_:item:)`` event when the
    /// `AVPlayer.timeControlStatus` changes to `.waiting`.
    func playerWaiting() {
        MediaEventCenter.shared.sendEvent(.playerWaiting(player, item: player.currentItem))
    }

    /// Send a ``MediaEvent/playerTapped(_:item:)`` event when the player is
    /// tapped. Unlike other calls in this class, it's not tied to any key-value
    /// observation change, and should probably live elsewhere.
    func playerTapped() {
        MediaEventCenter.shared.sendEvent(.playerTapped(player, item: player.currentItem))
    }

    // MARK: - AVPlayer.status (NOT AVPlayerItem.status, which is below)

    /// Convert raw `Any?` values from the key-value observer into
    /// `AVPlayer.Status` values, then calls the other
    /// `playerStatusChanged(from:to:)`.
    private func playerStatusChanged(from oldValue: Any?,
                                     to newValue: Any?) {
        let oldStatus = AVPlayer.Status.from(anyNumber: oldValue)
        let newStatus = AVPlayer.Status.from(anyNumber: newValue)
        playerStatusChanged(from: oldStatus, to: newStatus)
    }

    /// Call `playerReadyToPlay()`, `playerFailed(error:)`, or
    /// `playerStatusUnknown()` when the `AVPlayer.Status` changes.
    private func playerStatusChanged(from oldStatus: AVPlayer.Status?,
                                     to newStatus: AVPlayer.Status?) {
        // Is this necessary? Can we just call guard newStatus != oldStatus?
        guard oldStatus != newStatus,
            let newStatus = newStatus else {
                return
        }

        switch newStatus {
        case .readyToPlay:
            playerReadyToPlay()
        case .failed:
            playerFailed(error: player.error)
        case .unknown:
            playerStatusUnknown()
        default:
            return
        }
    }

    /// Send a ``MediaEvent/playerError(_:error:)`` event when `AVPlayer.status`
    /// changes to `.failed`.
    func playerFailed(error: Error?) {
        MediaEventCenter.shared.sendEvent(.playerError(player, error: error))
    }

    /// Send a ``MediaEvent/playerReady(_:)`` event when `AVPlayer.status`
    /// changes to `.readyToPlay`.
    func playerReadyToPlay() {
        MediaEventCenter.shared.sendEvent(.playerReady(player))
    }

    /// Send a ``MediaEvent/playerStatusUnknown(_:)`` event when
    /// `AVPlayer.status` changes to `.unknown`. It's not very helpful, but
    /// it's here for the sake of completeness.
    func playerStatusUnknown() {
        MediaEventCenter.shared.sendEvent(.playerStatusUnknown(player))
    }

    // MARK: - AVPlayerItem.status (NOT AVPlayer.status, which is above)

    /// Converts raw `Any?` values from the key-value observer into
    /// `AVPlayerItem.Status` values, then calls the other
    /// `playerItemStatusChanged(from:to:)`.
    private func playerItemStatusChanged(from oldStatus: Any?,
                                         to newStatus: Any?) {
        let oldStatus = AVPlayerItem.Status.from(anyNumber: oldStatus)
        let newStatus = AVPlayerItem.Status.from(anyNumber: newStatus)
        playerItemStatusChanged(from: oldStatus, to: newStatus)
    }

    /// Call `playerItemReadyToPlay()`, `playerItemFailed(_:)`, or
    /// `.playerItemStatusUnknown()` when the `player.currentItem`'s status
    /// changes.
    private func playerItemStatusChanged(from oldStatus: AVPlayerItem.Status?,
                                         to newStatus: AVPlayerItem.Status?) {
        // Is this necessary? Can we just call guard newStatus != oldStatus?
        guard oldStatus != newStatus,
            let newStatus = newStatus else {
                return
        }

        switch newStatus {
        case .readyToPlay:
            playerItemReadyToPlay()
        case .failed:
            playerItemFailed(player.currentItem?.error)
        case .unknown:
            playerItemStatusUnknown()
        default:
            return
        }
    }

    /// Send a ``MediaEvent/playerItemError(_:item:error:)`` event when
    /// `AVPlayerItem.status` changes to `.failed`.
    func playerItemFailed(_ error: Error?) {
        MediaEventCenter.shared.sendEvent(.playerItemError(player, item: player.currentItem, error: error))
    }

    /// Send a ``MediaEvent/playerItemReady(_:item:)`` event when
    /// `AVPlayerItem.status` changes to `.readyToPlay`. Also call
    /// `addPlaybackMilestoneObservers()`.
    func playerItemReadyToPlay() {
        MediaEventCenter.shared.sendEvent(.playerItemReady(player, item: player.currentItem))
        addPlaybackMilestoneObservers()
    }

    /// Send a ``MediaEvent/playerItemStatusUnknown(_:item:)`` event when
    /// `AVPlayerItem.status` changes to `.unknown`.
    func playerItemStatusUnknown() {
        MediaEventCenter.shared.sendEvent(.playerItemStatusUnknown(player, item: player.currentItem))
    }

    // MARK: - Playback

    /// Send a ``MediaEvent/playerItemStarted(_:item:)`` when the current item
    /// starts to play.
    func playbackStarted(item: AVPlayerItem?) {
        MediaEventCenter.shared.sendEvent(.playerItemStarted(player, item: item))
    }

    /// Send a ``MediaEvent/playerItemCompleted(_:item:)`` when the current item
    /// has finished playing. **This is never called for livestreams, for
    /// obvious reasons.**
    func playbackEnded(item: AVPlayerItem?) {
        MediaEventCenter.shared.sendEvent(.playerItemCompleted(player, item: item))
    }

    /// The playback percentages when `reportProgress()` will be called. By
    /// default, these are 25%, 50%, and 75%. If this changes, all previous
    /// milestone observers will be removed before the new ones are added.
    var playbackMilestones: [Double] = [0.25, 0.5, 0.75] {
        didSet {
            addPlaybackMilestoneObservers()
        }
    }

    /// The observers for custom `playbackMilestones`. Whenever the milestones
    /// change, these observers are removed and new ones are added.
    private var playbackMilestoneObservers: [Any] = []

    /// Add a boundary time observer to the player at each of the
    /// `playbackMilestones`. Each observer will call `reportProgress(_:)`.
    /// Any existing milestone observers are removed before new ones are added.
    private func addPlaybackMilestoneObservers() {
        for observer in playbackMilestoneObservers {
            ArcXPLogger.log("AVPlayer.removeTimeObserver(\(observer)) for playback milestones")
            player.removeTimeObserver(observer)
        }

        playbackMilestoneObservers.removeAll()  // empty the array

        guard let currentItem = player.currentItem, !currentItem.isLive else {
            return
        }

        let duration = currentItem.duration

        playbackMilestones.forEach { [weak self] (progress) in
            ArcXPLogger.logIfNil(self)
            let time = duration.seconds * progress
            self?.player.fire(at: time) {
                self?.reportProgress(progress)
            }
        }
    }

    /// Send a ``MediaEvent/playerItemPlayedPercent(_:item:percent:)`` event to
    /// indicate that playback reached the specified percentage.
    ///
    /// - parameter percentage: The playback percentage that's been reached.
    func reportProgress(_ percentage: Double) {
        MediaEventCenter.shared.sendEvent(.playerItemPlayedPercent(player,
                                                                   item: player.currentItem,
                                                                   percent: percentage))
    }
}
// swiftlint: enable file_length
