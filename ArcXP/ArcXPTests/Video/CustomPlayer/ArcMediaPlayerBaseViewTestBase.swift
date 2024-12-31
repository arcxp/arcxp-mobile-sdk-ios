//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import AVFoundation
import XCTest

class ArcMediaPlayerBaseViewTestBase: ArcMediaTestBase {

    var player: AVPlayer {
        return playerView.player
    }

    var playerController: PlayerController! {
        return playerViewController.playerController!
    }

    var playerView: ArcMediaPlayerView {
        return playerViewController.playerView
    }

    var playerViewController: ArcMediaPlayerViewController!

    var sampleVideo: AVPlayerItem {
        return AVPlayerItem(asset: AVAsset(url: fifteenSecondVideoUrl))
    }

    override func setUp() {
        super.setUp()

        playerViewController = ArcMediaPlayerViewController.loadFromStoryboard()
        _ = playerViewController.view // force viewDidLoad() to be called

        // Turns ads off. This has to be done AFTER the view is loaded, because
        // the playerController isn't initialized until the view is loaded.
        playerController.adsEnabled = false
    }

}
