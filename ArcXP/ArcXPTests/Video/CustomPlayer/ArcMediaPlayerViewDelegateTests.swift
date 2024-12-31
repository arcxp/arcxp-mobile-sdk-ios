//  Copyright © 2021 The Washington Post. All rights reserved.

import XCTest
import AVFoundation
@testable import ArcXP

// Swift, unlike Objective-C, won't let you mark protocol functions as
// optional, so to make them *act* optional, you have to extend the protocol
// with empty implementations. And to *test* them, you need a stupid unit test
// like this one.
class ArcMediaPlayerViewDelegateTests: ArcMediaTestBase {

    private class EmptyDelegate: NSObject, ArcMediaPlayerViewDelegate {

    }

    func testDefaultCalls() {
        let delegate = EmptyDelegate()
        let playerView = ArcMediaPlayerView(frame: .zero)
        playerView.player = AVPlayer()
        delegate.playerViewControlBarWillAppear(playerView)
        delegate.playerViewControlBarDidAppear(playerView)
        delegate.playerViewControlBarWillDisappear(playerView)
        delegate.playerViewControlBarDidDisappear(playerView)
        delegate.playerAdWillOpenExternalApplication(player: playerView.player)
        delegate.playerAdWillOpenInAppLink(player: playerView.player)
        delegate.playerAdDidOpenInAppLink(player: playerView.player)
        delegate.playerAdWillCloseInAppLink(player: playerView.player)
        delegate.playerAdDidCloseInAppLink(player: playerView.player)
        XCTAssertNotNil(delegate)
        XCTAssertNotNil(playerView)
        XCTAssertNotNil(playerView.player)
    }
}
