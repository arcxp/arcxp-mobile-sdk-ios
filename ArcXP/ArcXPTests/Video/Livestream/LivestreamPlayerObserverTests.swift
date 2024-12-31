//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import AVFoundation
import XCTest

// swiftlint:disable weak_delegate force_cast
class LivestreamPlayerObserverTests: ArcMediaTestBase {

    var delegate: MockPlayerDelegate!

    var fifteenSecondVideo: ArcVideo!

    var observer: LivestreamPlayerObserver!

    var player: AVPlayer!

    var playerController: PlayerController!

    var playerView: UIView!

    var realAdBreaksUrl1: URL!

    var realAdBreaksUrl2: URL!

    override func setUp() {
        super.setUp()

        fifteenSecondVideo = ArcVideo(streamUrl: fifteenSecondVideoUrl)
        realAdBreaksUrl1 = testBundle.url(forResource: "real-avails", withExtension: "json")
        realAdBreaksUrl2 = testBundle.url(forResource: "real-avails-shorter", withExtension: "json")
        var livestreamAdSettings = LivestreamAdSettings()
        livestreamAdSettings.trackingUrl = realAdBreaksUrl1
        fifteenSecondVideo.adSettings = livestreamAdSettings

        let arcViewController = ArcMediaPlayerViewController.loadFromStoryboard()
        playerView = arcViewController.view // force viewDidLoad() to be called, which initializes the playerController
        playerController = arcViewController.playerController!
        observer = (playerController.playerObserver as! LivestreamPlayerObserver)
        delegate = MockPlayerDelegate()
        playerController.delegate = delegate
        player = playerController.player
        player.volume = 0.2 // start with something other than muted or 0.35
    }

    func testFetchSameAdBreakTwiceWithDifferentAdCounts() throws {
        player.replaceCurrentItem(with: AVPlayerItem(asset: fifteenSecondVideo))

        let firstAdBreakObservationExpection = expectation(description: "62 adBreak observer wrappers")

        player.fire(at: 4.0) { [unowned self] in
            XCTAssertEqual(observer.adBreaksTrackingUrl, realAdBreaksUrl1)
            XCTAssertNotNil(observer.adBreaksObserver)
            XCTAssertEqual(observer.allAdBreakObservers.count, 1)
            XCTAssertEqual(observer.allAdBreakObservers.values.first!.adObservers.count, 62)
            observer.adBreaksTrackingUrl = realAdBreaksUrl2 // set it up for next time
            firstAdBreakObservationExpection.fulfill()
        }

        let secondAdBreakObservationExpection = expectation(description: "26 adBreak observer wrappers")

        player.fire(at: 8.0) { [unowned self] in
            XCTAssertEqual(observer.adBreaksTrackingUrl, realAdBreaksUrl2)
            XCTAssertEqual(observer.allAdBreakObservers.count, 1)
            XCTAssertEqual(observer.allAdBreakObservers.values.first!.adObservers.count, 26   )
            secondAdBreakObservationExpection.fulfill()
        }

        player.play()

        wait(for: [firstAdBreakObservationExpection, secondAdBreakObservationExpection], timeout: TestConstant.standardTimeout)
    }

    func testLoadingSubsequentVideoUnloadsFirstVideosObservers() throws {
        player.replaceCurrentItem(with: AVPlayerItem(asset: fifteenSecondVideo))

        let firstVideoAdBreakExpectation = expectation(description: "first video's ad breaks")

        let firstVideoObserver = player.fire(at: 13.0) {
            firstVideoAdBreakExpectation.fulfill()
        }

        player.play()

        wait(for: [firstVideoAdBreakExpectation], timeout: TestConstant.longTimeout)
        player.pause()
        player.removeTimeObserver(firstVideoObserver)

        print("Loading second video")
        player.replaceCurrentItem(with: AVPlayerItem(asset: fifteenSecondVideo))

        let secondVideoAdBreakExpectation = expectation(description: "second video's ad breaks")

        player.fire(at: 13.0) {
            secondVideoAdBreakExpectation.fulfill()
        }

        player.play()
        wait(for: [secondVideoAdBreakExpectation], timeout: TestConstant.longTimeout)
    }

    func testFakeAdsSendExpectedEvents() {
        // Configure the video to pull avails data from a mock file.
        let fakeAdBreaksUrl = testBundle.url(forResource: "mock-avails", withExtension: "json")
        var livestreamAdSettings = LivestreamAdSettings()
        livestreamAdSettings.testOpenMeasurementCompliance = true // use the OM test script
        livestreamAdSettings.trackingUrl = fakeAdBreaksUrl
        fifteenSecondVideo.adSettings = livestreamAdSettings

        let exp = expectation(description: "nearly finished playing")

        // Pause and play during the first ad, which runs from 3.0 to 8.0 seconds.
        player.fire(at: 6.0) { [unowned self] in
            playerController.pause()
            playerController.play()
        }

        // Mute and unmute the first ad.
        player.fire(at: 7.0) { [unowned self] in
            playerController.mute()
        }

        player.fire(at: 7.5) { [unowned self] in
            playerController.unmute()
        }

        // Change the volume during the second ad, which runs from 8.0 to 13.0 seconds.
        player.fire(at: 9.0) { [unowned self] in
            player.volume = 0.35
        }

        // Just before the end of the video, fulfill the expectation.
        player.fire(at: 12.0) {
            exp.fulfill()
        }

        playerController.play(playerItem: AVPlayerItem(asset: fifteenSecondVideo))
        playerController.play()

        wait(for: [exp], timeout: TestConstant.longTimeout)
        // Ideally the calls must equal to 30,
        // but in bitrise, may be with the player performance issue
        // the calls come as 29, 30.
        XCTAssertTrue(delegate.calls.count >= 29)
    }
}
