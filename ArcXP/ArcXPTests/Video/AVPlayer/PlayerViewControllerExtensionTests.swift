//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import AVFoundation
import AVKit
import XCTest

class AVPlayerViewControllerExtensionTests: ArcMediaTestBase {

    func testPlayerControllerWithNoPlayerCreatesAPlayerAndReturnsNonNil() {
        let viewController = AVPlayerViewController()
        XCTAssertNil(viewController.player)
        XCTAssertNotNil(viewController.playerController)
        XCTAssertNotNil(viewController.player)
    }

    func testPlayerControllerWithPlayerReturnsNonNil() {
        let viewController = AVPlayerViewController()
        let player = AVPlayer()
        viewController.player = player
        let playerController = viewController.playerController
        XCTAssertNotNil(playerController)
        XCTAssertTrue(playerController!.player === player)
    }

}
