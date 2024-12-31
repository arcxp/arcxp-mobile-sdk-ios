//  Copyright © 2021 The Washington Post. All rights reserved.

import Foundation
import UIKit

/// Sends ``MediaEvent``s to all `MediaEventSubscriber`s that have been added
/// to the event center. Events are always sent on the main thread.
public class MediaEventCenter: NSObject {

    /// A simple wrapper for holding ``MediaEventSubscriber``s weakly in a
    /// collection. This approach was taken from
    /// https://stackoverflow.com/a/24128121/665456.
    struct WeakSubscriber {

        weak var subscriber: MediaEventSubscriber?

    }

    // MARK: - Public Properties

    /// The singleton event center. All events should go through this instance.
    public static var shared = MediaEventCenter()

    // MARK: - Non-Public Properties

    /// The objects that receive events as they're sent. They're held weakly to
    /// prevent memory leaks when they would otherwise go out of scope.
    var subscribers = [WeakSubscriber]()

    // MARK: - Initialization

    /// Prevent other instances from being created.
    override private init() {
        super.init()
    }

    // MARK: - Subscribers

    /// Add an event subscriber. Duplicates are allowed.
    public func addSubscriber(_ subscriber: MediaEventSubscriber) {
        guard !subscribers.contains(where: { $0.subscriber === subscriber }) else {
            return
        }

        ArcXPLogger.log("Adding subscriber \(subscriber)")
        subscribers.append(WeakSubscriber(subscriber: subscriber))
    }

    /// Clear the subscriber list. Don't unsubscribe them; no new events will be
    /// sent to them.
    public func removeAllSubscribers() {
        subscribers.removeAll()
    }

    /// Remove a subscriber.
    public func removeSubscriber(_ subscriber: MediaEventSubscriber) {
        subscribers.removeAll {
            $0.subscriber === subscriber
        }
    }

    /// Remove all subscribers.
    public func reset() {
        removeAllSubscribers()
    }

    // MARK: - Event Stream

    /// Send a ``MediaEvent`` to all registered ``MediaEventSubscriber``s
    /// asynchronously on the main queue.
    public func sendEvent(_ event: MediaEvent) {
        ArcXPLogger.log("Sending event \(event) to \(subscribers.count) subscribers")
        subscribers.forEach { $0.subscriber?.receiveEvent(event) }
    }

}
