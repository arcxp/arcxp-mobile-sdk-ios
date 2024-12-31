//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import AVFoundation
import AVKit
import XCTest

class PlayerControllerTests: ArcMediaTestBase {

    // swiftlint:disable weak_delegate
    /// The delegate for receiving player events. It has to be a strong object
    /// property so that it doesn't go out of scope when `setUp()` is finished.
    var delegate: MockPlayerDelegate!
    // swiftlint:enable weak_delegate

    var player: AVPlayer!

    var playerController: PlayerController!

    var viewController: AVPlayerViewController!

    override func setUp() {
        super.setUp()

        player = AVPlayer()
        viewController = AVPlayerViewController()
        viewController.player = player
        playerController = viewController.playerController
        delegate = MockPlayerDelegate()
        playerController.delegate = delegate
    }

    override func tearDown() {
        super.tearDown()
        player.replaceCurrentItem(with: nil)
        delegate = nil
    }

    func testInitializer() {
        XCTAssertEqual(playerController.player, player)
        XCTAssertNotNil(playerController.delegate)
        XCTAssertFalse(playerController.adsEnabled)

        // Check the ads setup
        XCTAssertNotNil(playerController.adController)
    }

    // MARK: - Load & Play

    func testLoadCallsDelegate() {
        let playerItem = AVPlayerItem(url: fifteenSecondVideoUrl)
        playerController.load(playerItem: playerItem)
        XCTAssertEqual(playerItem, playerController.player.currentItem)
    }

    func testPlayPause() {
        playerController.adsEnabled = false

        let pauseExpectation = expectation(description: "pause and play")

        player.fire(at: 2.0) { [unowned self] in
            playerController.pause()
            pauseExpectation.fulfill()
        }

        let playerItem = AVPlayerItem(url: fiveSecondVideoUrl)
        playerController.play(playerItem: playerItem)

        wait(for: [pauseExpectation], timeout: TestConstant.standardTimeout)
        XCTAssertTrue(
            delegate.wereExpectedCallsMade(
                delegate.standardStartupCalls(for: playerItem)
                + [.playerPlayed25Percent,
                   .playerPaused]
            )
        )
    }

    // MARK: - Seek

    /// Test `PlayerController.seek(to: Float)`.
    func testSeekToVariousPercentages() {
        playerController.adsEnabled = false

        let seekTo50PercentExpectation = expectation(description: "Seek to 50%")
        let timeAt50Percent = CMTime(seconds: 7.5, preferredTimescale: 1)

        player.fire(at: 3.0 /* seconds */) { [unowned self] in
            playerController.seek(to: 0.5 /* percent */)
            seekTo50PercentExpectation.fulfill()
        }

        let seekTo90PercentExpectation = expectation(description: "Seek to 90%")
        let timeAt90Percent = CMTime(seconds: 13.5, preferredTimescale: 1)

        player.fire(at: 10.0 /* seconds */) { [unowned self] in
            playerController.seek(to: 0.9)
            seekTo90PercentExpectation.fulfill()
        }

        let playerItem = AVPlayerItem(url: fifteenSecondVideoUrl)
        playerController.play(playerItem: playerItem)

        wait(for: [seekTo50PercentExpectation, seekTo90PercentExpectation], timeout: TestConstant.standardTimeout)
        XCTAssertTrue(
            delegate.wereExpectedCallsMade(
                delegate
                    .standardStartupCalls(for: playerItem) +
                [.playerSkippedTo(ImpreciseCMTime(timeAt50Percent)),
                 .playerPlayed50Percent,
                 .playerSkippedTo(ImpreciseCMTime(timeAt90Percent))]
            )
        )
    }

    /// Test `PlayerController.seek(to: CMTime)`.
    func testSeekToVariousTimes() {
        playerController.adsEnabled = false

        let seekTo40PercentExpectation = expectation(description: "Seek to 50%")
        let timeAt40Percent = CMTime(seconds: (15.0 * 0.4), preferredTimescale: 1)

        player.fire(at: 3.0 /* seconds */) { [unowned self] in
            playerController.seek(to: timeAt40Percent)
            seekTo40PercentExpectation.fulfill()
        }

        let seekTo90PercentExpectation = expectation(description: "Seek to 90%")
        let timeAt90Percent = CMTime(seconds: 13.5, preferredTimescale: 1)

        player.fire(at: 10.0 /* seconds */) { [unowned self] in
            playerController.seek(to: timeAt90Percent)
            seekTo90PercentExpectation.fulfill()
        }

        let playerItem = AVPlayerItem(url: fifteenSecondVideoUrl)
        playerController.play(playerItem: playerItem)

        wait(for: [seekTo40PercentExpectation, seekTo90PercentExpectation], timeout: TestConstant.standardTimeout)
        XCTAssertTrue(
            delegate.wereExpectedCallsMade(
                delegate
                    .standardStartupCalls(for: playerItem) +
                [.playerSkippedTo(ImpreciseCMTime(timeAt40Percent)),
                 .playerPlayed50Percent,
                 .playerSkippedTo(ImpreciseCMTime(timeAt90Percent))]
            )
        )
    }

    func testJumpToEnd() {
        playerController.adsEnabled = false

        let skipExpectation = expectation(description: "skip to end")
        let endTime = CMTime(seconds: 15.0, preferredTimescale: 1)

        player.fire(at: 8.0) { [unowned self] in
            playerController.jumpToEnd()
            skipExpectation.fulfill()
        }

        let playerItem = AVPlayerItem(url: fifteenSecondVideoUrl)
        playerController.play(playerItem: playerItem)

        wait(for: [skipExpectation], timeout: TestConstant.standardTimeout)
        XCTAssertTrue(
            delegate.wereExpectedCallsMade(
                delegate.standardStartupCalls(for: playerItem)
                + [.playerPlayed25Percent,
                   .playerPlayed50Percent,
                   .playerSkippedTo(ImpreciseCMTime(endTime))]
            )
        )
    }

    // MARK: - Mute & Unmute

    func testMuteAndUnmute() {
        playerController.adsEnabled = false

        let muteExpectation = self.expectation(description: "player muted")

        player.fire(at: 2.0) { [unowned self] in
            playerController.mute()
            XCTAssertTrue(player.isMuted)
            muteExpectation.fulfill()
        }

        let unmuteExpectation = self.expectation(description: "player unmuted")

        player.fire(at: 4.0) { [unowned self] in
            playerController.unmute()
            XCTAssertFalse(player.isMuted)
            unmuteExpectation.fulfill()
        }

        let playerItem = AVPlayerItem(url: fiveSecondVideoUrl)
        playerController.play(playerItem: playerItem)

        wait(for: [muteExpectation, unmuteExpectation], timeout: TestConstant.standardTimeout)
        XCTAssertTrue(
            delegate.wereExpectedCallsMade(
                delegate.standardStartupCalls(for: playerItem)
                + [.playerPlayed25Percent,
                   .playerMuted,
                   .playerPlayed50Percent,
                   .playerPlayed75Percent,
                   .playerUnmuted]
            )
        )
    }
}
