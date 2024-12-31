//  Copyright © 2021 The Washington Post. All rights reserved.

import AVFoundation

/// An `AVPlayer` that keeps track of the boundary and periodic time observers
/// that have been added to it. Time observers are ridiculously fragile:
/// there's no way to find out whether an observer is still attached to a
/// particular player, so if an observer is removed more than once, or if you
/// attempt to remove it from an `AVPlayer` instance that it was never added to,
/// the app _crashes_ with very few details.
open class ArcPlayer: AVPlayer {

    /// Objects that were added by calling
    /// ``addBoundaryTimeObserver(forTimes:queue:using:)``.
    var boundaryTimeObservers: [AnyObject] = []

    /// Objects that were added by calling
    /// ``addPeriodicTimeObserver(forInterval:queue:using:)``.
    var periodicTimeObservers: [AnyObject] = []

    // MARK: - AVPlayer overrides

    /// Add a observer that fires at specific times during playback. The
    /// observer is added to the `boundaryTimeObservers` before it's returned
    /// to the caller.
    open override func addBoundaryTimeObserver(forTimes times: [NSValue],
                                               queue: DispatchQueue?,
                                               using block: @escaping () -> Void) -> Any {
        let observer = super.addBoundaryTimeObserver(forTimes: times, queue: queue, using: block)
        boundaryTimeObservers.append(observer as AnyObject)
        ArcXPLogger.log("Adding boundary time observer \(observer)")

        return observer
    }

    /// Add a observer that fires at regular intervals during playback. The
    /// observer is added to the `periodicTimeObservers` before it's returned
    /// to the caller.
    open override func addPeriodicTimeObserver(forInterval interval: CMTime,
                                               queue: DispatchQueue?,
                                               using block: @escaping (CMTime) -> Void) -> Any {
        let observer = super.addPeriodicTimeObserver(forInterval: interval, queue: queue, using: block)
        periodicTimeObservers.append(observer as AnyObject)
        ArcXPLogger.log("Adding periodic time observer \(observer)")

        return observer
    }

    /// Remove a time observer from the player. If it's already been removed,
    /// or it was never added to this player instance in the first place, a
    /// fatal error will be called.
    open override func removeTimeObserver(_ observer: Any) {
        let anyObserver = observer as AnyObject

        guard containsTimeObserver(observer) else {
            ArcXPLogger.log("Attempting to remove an observer that isn't observing this player instance!")

            return
        }

        ArcXPLogger.log("Periodic time observers: \(periodicTimeObservers)")
        ArcXPLogger.log("Boundary time observers: \(boundaryTimeObservers)")
        ArcXPLogger.log("Removing \(observer)")
        boundaryTimeObservers.removeAll(where: { $0 === anyObserver })
        periodicTimeObservers.removeAll(where: { $0 === anyObserver })

        super.removeTimeObserver(observer)
    }

    // MARK: - Other Functions

    /// `true` if the observer is observing time boundaries in this player.
    public func containsBoundaryTimeObserver(_ observer: Any) -> Bool {
        return boundaryTimeObservers.contains { $0 === (observer as AnyObject) }
    }

    /// `true` if the observer is firing at regular intervals on this player.
    public func containsPeriodicTimeObserver(_ observer: Any) -> Bool {
        return periodicTimeObservers.contains { $0 === (observer as AnyObject) }
    }

    /// `true` if the observer is either a boundary or a periodic time observer
    /// on this player.
    public func containsTimeObserver(_ observer: Any) -> Bool {
        return containsBoundaryTimeObserver(observer) || containsPeriodicTimeObserver(observer)
    }

}
