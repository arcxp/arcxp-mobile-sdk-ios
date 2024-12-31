//  Copyright © 2021 The Washington Post. All rights reserved.

@testable import ArcXP

import AVFoundation
import XCTest

class ArcPlayerTests: XCTestCase {
    
    var arcPlayer: ArcPlayer!

    func testAddingAndRemovingBoundaryTimeObserverOk() throws {
        let player = ArcPlayer()
        XCTAssertTrue(player.boundaryTimeObservers.isEmpty)

        let boundaryTimeObserver = player.fire(at: 3.0) { }
        XCTAssertEqual(player.boundaryTimeObservers.count, 1)

        player.removeTimeObserver(boundaryTimeObserver)
        XCTAssertTrue(player.boundaryTimeObservers.isEmpty)
    }

    func testAddingAndRemovingPeriodicTimeObserverOk() throws {
        let player = ArcPlayer()
        XCTAssertTrue(player.periodicTimeObservers.isEmpty)

        let boundaryTimeObserver = player.fire(every: 3.0) { _ in }
        XCTAssertEqual(player.periodicTimeObservers.count, 1)

        player.removeTimeObserver(boundaryTimeObserver)
        XCTAssertTrue(player.periodicTimeObservers.isEmpty)
    }

    func testRemovingUnrelatedPeriodicTimeObserverLogsError() throws {
        ArcXPLogger.level = .all
        let player = ArcPlayer()
        player.removeTimeObserver("Something that's not an observer")
    }

    override func setUp() {
        super.setUp()
        arcPlayer = ArcPlayer()
    }

    override func tearDown() {
        arcPlayer = nil
        super.tearDown()
    }

    // MARK: - Test addBoundaryTimeObserver

//    func testAddBoundaryTimeObserver() {
//        let expectation = self.expectation(description: "Boundary time observer callback")
//
//        let times: [NSValue] = [CMTime(value: 1, timescale: 1) as NSValue]
//        let observer = arcPlayer.addBoundaryTimeObserver(forTimes: times, queue: nil) {
//            expectation.fulfill()
//        }
//
//        XCTAssertNotNil(observer)
//
//        // Wait for the expectation to be fulfilled
//        waitForExpectations(timeout: 1.0, handler: nil)
//    }

    // MARK: - Test addPeriodicTimeObserver

//    func testAddPeriodicTimeObserver() {
//        let expectation = self.expectation(description: "Periodic time observer callback")
//
//        let interval = CMTime(value: 1, timescale: 1)
//        let observer = arcPlayer.addPeriodicTimeObserver(forInterval: interval, queue: nil) { _ in
//            expectation.fulfill()
//        }
//
//        XCTAssertNotNil(observer)
//
//        // Wait for the expectation to be fulfilled
//        waitForExpectations(timeout: 3.0, handler: nil)
//    }

    // MARK: - Test removeTimeObserver

//    func testRemoveTimeObserver() {
//        let times: [NSValue] = [CMTime(value: 1, timescale: 1) as NSValue]
//        let boundaryObserver = arcPlayer.addBoundaryTimeObserver(forTimes: times, queue: nil) {}
//        let periodicInterval = CMTime(value: 1, timescale: 1)
//        let periodicObserver = arcPlayer.addPeriodicTimeObserver(forInterval: periodicInterval, queue: nil) { _ in }
//
//        arcPlayer.removeTimeObserver(boundaryObserver)
//        arcPlayer.removeTimeObserver(periodicObserver)
//
//        XCTAssertFalse(arcPlayer.boundaryTimeObservers.contains { $0 == boundaryObserver as AnyObject})
//        XCTAssertFalse(arcPlayer.periodicTimeObservers.contains(periodicObserver as AnyObject))
//    }

    // MARK: - Test containsBoundaryTimeObserver

    func testContainsBoundaryTimeObserver() {
        let times: [NSValue] = [CMTime(value: 1, timescale: 1) as NSValue]
        let boundaryObserver = arcPlayer.addBoundaryTimeObserver(forTimes: times, queue: nil) {}

        XCTAssertTrue(arcPlayer.containsBoundaryTimeObserver(boundaryObserver))
    }

    func testDoesNotContainBoundaryTimeObserver() {
        let boundaryObserver = NSObject() // Mock observer that was never added
        XCTAssertFalse(arcPlayer.containsBoundaryTimeObserver(boundaryObserver))
    }

    // MARK: - Test containsPeriodicTimeObserver

    func testContainsPeriodicTimeObserver() {
        let interval = CMTime(value: 1, timescale: 1)
        let periodicObserver = arcPlayer.addPeriodicTimeObserver(forInterval: interval, queue: nil) { _ in }
        XCTAssertTrue(arcPlayer.containsPeriodicTimeObserver(periodicObserver))
    }

    func testDoesNotContainPeriodicTimeObserver() {
        let periodicObserver = NSObject() // Mock observer that was never added
        XCTAssertFalse(arcPlayer.containsPeriodicTimeObserver(periodicObserver))
    }

    // MARK: - Test containsTimeObserver

    func testContainsTimeObserver() {
        let times: [NSValue] = [CMTime(value: 1, timescale: 1) as NSValue]
        let boundaryObserver = arcPlayer.addBoundaryTimeObserver(forTimes: times, queue: nil) {}

        XCTAssertTrue(arcPlayer.containsTimeObserver(boundaryObserver))
    }

    func testDoesNotContainTimeObserver() {
        let observer = NSObject() // Mock observer that was never added
        XCTAssertFalse(arcPlayer.containsTimeObserver(observer))
    }
}
