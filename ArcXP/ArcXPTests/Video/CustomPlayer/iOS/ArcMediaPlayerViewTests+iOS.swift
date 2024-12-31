//  Copyright © 2021 The Washington Post. All rights reserved.

@testable import ArcXP
import XCTest

class ArcMediaPlayerViewTests: ArcMediaPlayerBaseViewTestBase {

    // MARK: - UIView Properties

#if os(iOS)
    func testUseSkipForwardButtonTogglesButtonVisibility() {
        playerView.skipForwardButton?.isHidden = true

        playerView.useSkipForwardButton = true
        XCTAssertFalse(playerView.skipForwardButton!.isHidden)

        playerView.useSkipForwardButton = false
        XCTAssertTrue(playerView.skipForwardButton!.isHidden)
    }

    func testUseSkipBackwardButtonTogglesButtonVisibility() {
        playerView.skipBackwardButton?.isHidden = true

        playerView.useSkipBackwardButton = true
        XCTAssertFalse(playerView.skipBackwardButton!.isHidden)

        playerView.useSkipBackwardButton = false
        XCTAssertTrue(playerView.skipBackwardButton!.isHidden)
    }
#endif

    func testFriendlyAdObstructions() {
#if os(iOS)
        XCTAssertEqual(playerView.friendlyAdObstructions.count, 3)
#elseif os(tvOS)
        XCTAssertEqual(playerView.friendlyAdObstructions.count, 2)
#endif
    }

    // MARK: - showControlBar() & hideControlBar()

    func testManualShowAndHideControlBar() throws {
        playerView.secondsBeforeControlBarHides = nil  // disable the timer

        let expectation = self.expectation(description: "Manually show and hide the control bar")

        player.fire(at: 3.0) { [unowned self] in
            let controlBar = playerView.controlBar!
            XCTAssertFalse(controlBar.isHidden)

            playerView.hideControlBar()
            XCTAssertTrue(controlBar.isHidden)

            playerView.showControlBar()
            XCTAssertFalse(controlBar.isHidden)
            expectation.fulfill()
        }

        playerController.play(playerItem: sampleVideo)
        wait(for: [expectation], timeout: TestConstant.standardTimeout)
    }

    func testHideControlBarWithTimer() {
        playerView.secondsBeforeControlBarHides = 2

        let controlBar = playerView.controlBar!
        XCTAssertFalse(controlBar.isHidden)

        let expectation = self.expectation(description: "Hide the control bar with timer")

        player.fire(at: 5.0) {
            XCTAssertTrue(controlBar.isHidden)
            expectation.fulfill()
        }

        playerController.play(playerItem: sampleVideo)
        wait(for: [expectation], timeout: TestConstant.standardTimeout)
    }

    func testSettingsSecondsBeforeControlBarHidesToNilDoesNotHideControlBarUntilPaused() {
        // Don't use the controlBar auto-hiding timer.
        playerView.secondsBeforeControlBarHides = nil

        let expectation = self.expectation(description: "Setting seconds to nil won't hide the control bar")
        player.fire(at: 5.0) { [unowned self] in
            let controlBar = playerView.controlBar!
            playerView.hideControlBar()
            XCTAssertTrue(controlBar.isHidden)

            playerController.pause()
            XCTAssertFalse(controlBar.isHidden)
            expectation.fulfill()
        }

        playerController.play(playerItem: sampleVideo)
        wait(for: [expectation], timeout: TestConstant.standardTimeout)
    }

    func testShowHideSidecarCaptions() {
        let text = "This is some captioning text."
        let captionsLabel = playerView.captionsLabel!
        playerView.showClientSideCaptions = true
        playerView.showClientSideCaption(text)

        XCTAssertFalse(captionsLabel.isHidden)
        XCTAssertEqual(captionsLabel.attributedText?.string, text)

        playerView.showClientSideCaptions = false
        XCTAssertNil(captionsLabel.attributedText)
    }

    func testShowFullScreen() {
        let expectation = self.expectation(description: "Show Full screen")
        // attach them to a real window
        let window = UIWindow()
        window.rootViewController = playerViewController
        window.makeKeyAndVisible()
        
        playerView.isFullScreen = false
        player.fire(at: 3.0) { [unowned self] in
            playerView.toggleFullscreen(sender: nil)
            XCTAssertTrue(playerView.isFullScreen)
            expectation.fulfill()
        }

        playerController.play(playerItem: sampleVideo)
        wait(for: [expectation], timeout: TestConstant.standardTimeout)
    }

    func testHideFullScreen() {
        let expectation = self.expectation(description: "Hide Full screen")
        // attach them to a real window
        let window = UIWindow()
        window.rootViewController = playerViewController
        window.makeKeyAndVisible()
        
        playerView.isFullScreen = true
        player.fire(at: 3.0) { [unowned self] in
            playerView.toggleFullscreen(sender: nil)
            XCTAssertFalse(playerView.isFullScreen)
            expectation.fulfill()
        }

        playerController.play(playerItem: sampleVideo)
        wait(for: [expectation], timeout: TestConstant.standardTimeout)
    }

}
