//  Copyright © 2021 The Washington Post. All rights reserved.

@testable import ArcXP

import AVFoundation
import XCTest

class MediaEventCenterTests: XCTestCase {

    class Subscriber: NSObject, MediaEventSubscriber {

        var receivedEvents = [MediaEvent]()

        func receiveEvent(_ event: MediaEvent) {
            receivedEvents.append(event)
        }

    }

    override func setUpWithError() throws {
        MediaEventCenter.shared.removeAllSubscribers()
    }

    func testAddAndRemoveSubscriber() {
        let eventCenter = MediaEventCenter.shared
        let subscriber1 = Subscriber()
        let subscriber2 = Subscriber()

        eventCenter.addSubscriber(subscriber1)
        eventCenter.addSubscriber(subscriber2)
        XCTAssertEqual(eventCenter.subscribers.count, 2)

        eventCenter.removeSubscriber(subscriber1)
        XCTAssertEqual(eventCenter.subscribers.count, 1)
    }

    func testRemoveSubscriberTwiceDoesNothing() {
        let eventCenter = MediaEventCenter.shared
        let subscriber1 = Subscriber()
        let subscriber2 = Subscriber()

        eventCenter.addSubscriber(subscriber1)
        eventCenter.addSubscriber(subscriber2)
        XCTAssertEqual(eventCenter.subscribers.count, 2)

        eventCenter.removeSubscriber(subscriber1)
        eventCenter.removeSubscriber(subscriber1)
        XCTAssertEqual(eventCenter.subscribers.count, 1)
    }

    func testaddSubscriberTwiceIgnoresDuplicates() {
        let eventCenter = MediaEventCenter.shared
        let subscriber = Subscriber()

        eventCenter.addSubscriber(subscriber)
        eventCenter.addSubscriber(subscriber)
        XCTAssertEqual(eventCenter.subscribers.count, 1)

        eventCenter.removeSubscriber(subscriber)
        XCTAssertEqual(eventCenter.subscribers.count, 0)
    }

    func testSendEventToMultiplesubscribers() {
        let eventCenter = MediaEventCenter.shared
        let subscriber1 = Subscriber()
        let subscriber2 = Subscriber()

        eventCenter.addSubscriber(subscriber1)
        eventCenter.addSubscriber(subscriber2)

        // Set up the event
        let player = AVPlayer()
        let event1 = MediaEvent.playerReady(player)
        let event2 = MediaEvent.playerMuted(player)
        eventCenter.sendEvent(event1)
        eventCenter.sendEvent(event2)

        XCTAssertEqual(subscriber1.receivedEvents.count, 2)
        XCTAssertEqual(subscriber2.receivedEvents.count, 2)
    }

}
