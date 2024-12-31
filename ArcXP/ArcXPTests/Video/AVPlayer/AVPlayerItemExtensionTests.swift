//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import AVFoundation
import XCTest

class AVPlayerItemExtensionTests: ArcMediaTestBase {

    func testPlayerStatusConversion() {
        XCTAssertEqual(AVPlayerItem.Status.unknown,
                       AVPlayerItem.Status.from(anyNumber: NSNumber(value: 0)))
        XCTAssertEqual(AVPlayerItem.Status.readyToPlay,
                       AVPlayerItem.Status.from(anyNumber: NSNumber(value: 1)))
        XCTAssertEqual(AVPlayerItem.Status.failed,
                       AVPlayerItem.Status.from(anyNumber: NSNumber(value: 2)))
        XCTAssertNil(AVPlayerItem.Status.from(anyNumber: nil))
        XCTAssertNil(AVPlayerItem.Status.from(anyNumber: "This is not an NSNumber"))
    }

    func testProgress() {
        let expectation = self.expectation(description: "AVPlayerItem.progress")

        let player = AVPlayer(url: fifteenSecondVideoUrl)

        player.play()
        player.fire(at: 5.0) {
            player.pause()
            // Check whether it's at 33%.
            XCTAssertEqual(player.currentItem!.progress!, 0.3333, accuracy: 0.02)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: TestConstant.standardTimeout)
    }
}
