//  Copyright © 2020 The Washington Post. All rights reserved.

import AVFoundation

/// Convenience properties and functions for `AVPlayer`.
extension AVPlayer {

    // MARK: - Properties

    /// Return `true` if the `timeControlStatus` is `.playing`.
    var isPlaying: Bool {
        return status == .readyToPlay && timeControlStatus == .playing
    }

    // MARK: - Functions

    /// Shorthand for `addBoundaryTimeObserver` on the main (i.e. `nil`) queue.
    ///
    /// - parameter at: The time, relative to the start of the player's current
    ///   item, at which to fire the block.
    /// - parameter block: The code to execute when playback reaches the
    ///   the specified time. **Note: Always capture `self` weakly in the
    ///   block to avoid retain cycles.**
    @discardableResult
    func fire(at time: Double, block: @escaping () -> Void) -> Any {
        return fire(at: [time], block: block)
    }

    /// Shorthand for `addBoundaryTimeObserver` on the main (i.e. `nil`) queue.
    ///
    /// - parameter at: The time, relative to the start of the player's current
    ///   item, at which to fire the block.
    /// - parameter block: The code to execute when playback reaches the
    ///   the specified time. **Note: Always capture `self` weakly in the
    ///   block to avoid retain cycles.**
    @discardableResult
    func fire(at times: [Double], block: @escaping () -> Void) -> Any {
        let observer = self.addBoundaryTimeObserver(forTimes: times.map { NSNumber(value: $0) },
                                                    queue: nil,
                                                    using: block)

        if let firstTime = times.first {
            ArcXPLogger.log("Adding a boundary time observer \(observer) at \(firstTime) seconds")
        }

        return observer
    }

    /// Shorthand for `addPeriodicTimeObserver` on the main (i.e. `nil`) queue.
    ///
    /// - parameter at: The interval (in seconds) at which to fire the block.
    /// - parameter block: The code to execute at the specified intervals.
    ///   **Note: Always capture `self` weakly in the block to avoid retain
    ///   cycles.**
    @discardableResult
    func fire(every interval: Double, block: @escaping (CMTime) -> Void) -> Any {
        return fire(every: CMTime(seconds: interval, preferredTimescale: 1), block: block)
    }

    /// Shorthand for `addPeriodicTimeObserver` on the main (i.e. `nil`) queue.
    ///
    /// - parameter at: The interval at which to fire the block.
    /// - parameter block: The code to execute at the specified intervals.
    ///   **Note: Always capture `self` weakly in the block to avoid retain
    ///   cycles.**
    @discardableResult
    func fire(every interval: CMTime, block: @escaping (CMTime) -> Void) -> Any {
        let observer = self.addPeriodicTimeObserver(forInterval: interval,
                                                    queue: nil,
                                                    using: block)
        ArcXPLogger.log("KVO: Adding a periodic time observer \(observer) every \(interval.seconds) seconds")

        return observer
    }

    /// Skip right to the end of the video. If the video is live, then this
    /// will jump to the latest time that's been loaded.
    func jumpToEnd() {
        seek(to: 1.0)
    }

    /// Jump to a relative point in the current item.
    ///
    /// - parameter to: The playback percentage, from `0.0` (the beginning) to
    ///   `1.0` (the end).
    ///
    /// - returns: The playback time at the specified percentage, or `nil` if
    ///   the time couldn't be calculated.
    @discardableResult
    func seek(to percentage: Float) -> CMTime? {
        guard let startTime = currentItem?.startTime?.seconds,
            let endTime = currentItem?.endTime?.seconds else {
            return nil
        }

        let seekSeconds = (endTime - startTime) * Double(percentage)
        let newTime = CMTime(seconds: startTime + seekSeconds, preferredTimescale: 1)
        seek(to: newTime)

        return newTime
    }

}

extension AVPlayer.Status {

    /// Get the `int` value of the `AVPlayer.Status` from an `NSNumber`, which
    /// is what's returned by a key-value observation of the `AVPlayer.status`
    /// property.
    ///
    /// - parameter anyNumber: The `NSNumber` returned by a key-value change.
    ///   This is cast to an `NSNumber`, which is then used to get an `int`,
    ///   which in turn is used to get an `AVPlayer.Status`.
    static func from(anyNumber: Any?) -> AVPlayer.Status? {
        if let intValue = (anyNumber as? NSNumber)?.intValue {
            return AVPlayer.Status(rawValue: intValue)
        } else {
            return nil
        }
    }

}

extension AVPlayer.TimeControlStatus {

    /// Get the `int` value of the `AVPlayer.TimeControlStatus` from an
    /// `NSNumber`, which is what's returned by a key-value observation of the
    /// `AVPlayer.timeControlStatus` property.
    ///
    /// - parameter anyNumber: The `NSNumber` returned by a key-value change.
    ///   This is cast to an `NSNumber`, which is then used to get an `int`,
    ///   which in turn is used to get an `AVPlayer.TimeControlStatus`.
    static func from(anyNumber: Any?) -> AVPlayer.TimeControlStatus? {
        if let intValue = (anyNumber as? NSNumber)?.intValue {
            return AVPlayer.TimeControlStatus(rawValue: intValue)
        } else {
            return nil
        }
    }

}
