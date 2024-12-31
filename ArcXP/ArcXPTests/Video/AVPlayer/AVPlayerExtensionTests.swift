//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import AVFoundation
import XCTest

class AVPlayerExtensionTests: ArcMediaTestBase {

//     func testFireAtSpecificTime() throws {
//         let player = AVPlayer(url: fifteenSecondVideoUrl)
//         let expectation = self.expectation(description: "Boundary observer")
//
//         player.fire(at: 5.0) {
//             expectation.fulfill()
//         }
//
//         player.play()
//
//         wait(for: [expectation], timeout: TestConstant.standardTimeout)
//     }

//     func testFireAtIntervals() throws {
//         let player = AVPlayer(url: fifteenSecondVideoUrl)
//         let expectation = self.expectation(description: "Interval observer")
//         let interval = CMTime(seconds: 3.0, preferredTimescale: 1)
//         var numberOfTimesFired = 0
//
//         player.fire(every: interval) { _ in
//             numberOfTimesFired += 1
//
//             if numberOfTimesFired == 4 {
//                 expectation.fulfill()
//             }
//         }
//
//         player.play()
//
//         wait(for: [expectation], timeout: TestConstant.standardTimeout)
//     }

    func testPlayerStatusConversion() {
        XCTAssertEqual(AVPlayer.Status.unknown,
                       AVPlayer.Status.from(anyNumber: NSNumber(value: 0)))
        XCTAssertEqual(AVPlayer.Status.readyToPlay,
                       AVPlayer.Status.from(anyNumber: NSNumber(value: 1)))
        XCTAssertEqual(AVPlayer.Status.failed,
                       AVPlayer.Status.from(anyNumber: NSNumber(value: 2)))
        XCTAssertNil(AVPlayer.Status.from(anyNumber: nil))
        XCTAssertNil(AVPlayer.Status.from(anyNumber: "This is not an NSNumber"))
    }

    func testPlayerTimeControlStatusConversion() {
        XCTAssertEqual(AVPlayer.TimeControlStatus.paused,
                       AVPlayer.TimeControlStatus.from(anyNumber: NSNumber(value: 0)))
        XCTAssertEqual(AVPlayer.TimeControlStatus.waitingToPlayAtSpecifiedRate,
                       AVPlayer.TimeControlStatus.from(anyNumber: NSNumber(value: 1)))
        XCTAssertEqual(AVPlayer.TimeControlStatus.playing,
                       AVPlayer.TimeControlStatus.from(anyNumber: NSNumber(value: 2)))
        XCTAssertNil(AVPlayer.TimeControlStatus.from(anyNumber: nil))
        XCTAssertNil(AVPlayer.TimeControlStatus.from(anyNumber: "This is not an NSNumber"))
    }

}
