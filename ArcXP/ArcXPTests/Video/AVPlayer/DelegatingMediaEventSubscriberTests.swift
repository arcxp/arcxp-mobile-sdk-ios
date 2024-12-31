//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import AVFoundation
import XCTest

class DelegatingMediaEventSubscriberTests: ArcMediaTestBase {

    // swiftlint:disable weak_delegate
    var delegate: MockPlayerDelegate!
    // swiftlint:enable weak_delegate
    var avPlayer: AVPlayer!
    var observer: PlayerObserver!
    var eventSubscriber: DelegatingMediaEventSubscriber!

    override func setUp() {
        super.setUp()

        avPlayer = AVPlayer()
        observer = PlayerObserver(player: avPlayer)
        delegate = MockPlayerDelegate()
        eventSubscriber = DelegatingMediaEventSubscriber(delegate: delegate)
        MediaEventCenter.shared.addSubscriber(eventSubscriber)
    }

    override func tearDown() {
        super.tearDown()
        observer.stop()
        MediaEventCenter.shared.removeSubscriber(eventSubscriber)
        avPlayer.replaceCurrentItem(with: nil)
        delegate = nil
    }

    // MARK: - AVPlayer.isMuted

    func testMuteUnmute() {
        avPlayer.isMuted = true   // #1
        avPlayer.isMuted = false  // #2
        avPlayer.isMuted = true   // #3

        // Check it.
        XCTAssertTrue(
            delegate.wereExpectedCallsMade(
                [.playerMuted,
                 .playerUnmuted,
                 .playerMuted]
            )
        )
    }

    // MARK: - AVPlayer.status

    func testSettingPlayerItemToNilUpdatesPlayerStatus() {
        let playerItem = AVPlayerItem(url: fifteenSecondVideoUrl)
        avPlayer.replaceCurrentItem(with: playerItem)

        let expectation = self.expectation(description: "playback milestones") // self is required

        avPlayer.fire(at: 3.0) { [unowned self] in
            avPlayer.replaceCurrentItem(with: nil)
            XCTAssertTrue(
                delegate.wereExpectedCallsMade(
                    delegate.standardStartupCalls(for: playerItem)
                    + [.playerItemChanged(oldItem: playerItem, newItem: nil)]
                )
            )
            expectation.fulfill()
        }

        avPlayer.play()
        wait(for: [expectation], timeout: TestConstant.standardTimeout)
    }

    // MARK: - AVPlayer.volume

    func testVolumeChanges() {
        avPlayer.volume = 0.34
        avPlayer.volume = 1.0
        XCTAssertTrue(
            delegate.wereExpectedCallsMade(
                [.playerVolumeChanged,
                 .playerVolumeChanged]
            )
        )
    }

    // MARK: - Playback

    func testDefaultPlaybackMilestones() {
        // Set it up.
        let expectation = self.expectation(description: "playback milestones") // self is required

        let playerItem = AVPlayerItem(url: fifteenSecondVideoUrl)
        avPlayer.replaceCurrentItem(with: playerItem)

        avPlayer.fire(at: 8.0) {
            expectation.fulfill()
        }

        // Do it.
        avPlayer.play()
        wait(for: [expectation], timeout: TestConstant.standardTimeout)
        XCTAssertTrue(
            delegate.wereExpectedCallsMade(
                delegate.standardStartupCalls(for: playerItem)
                + [.playerPlayed25Percent,
                   .playerPlayed50Percent]
            )
        )
    }

    func testCustomPlaybackMilestones() {
        // Set it up.
        observer.playbackMilestones = [0.1, 0.3, 0.5, 0.7]

        let playerItem = AVPlayerItem(url: fifteenSecondVideoUrl)
        avPlayer.replaceCurrentItem(with: playerItem)

        let expectation = self.expectation(description: "playback milestones") // self is required
        avPlayer.fire(at: 13.0) {
            expectation.fulfill()
        }

        // Do it.
        avPlayer.play()
        wait(for: [expectation], timeout: TestConstant.longTimeout)
        XCTAssertTrue(
            delegate.wereExpectedCallsMade(
                delegate.standardStartupCalls(for: playerItem)
                + [.playerPlayedPercent(0.1),
                   .playerPlayedPercent(0.3),
                   .playerPlayed50Percent,
                   .playerPlayedPercent(0.7)]
            )
        )
    }
}
