//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import AVFoundation
import XCTest

class ArcMediaPlayerViewControllerTests: ArcMediaTestBase {

    var viewController: ArcMediaPlayerViewController!

    override func setUp() {
        super.setUp()
        viewController = ArcMediaPlayerViewController.loadFromStoryboard()
        _ = viewController.view // force viewDidLoad() to be called
    }

    func testLoadFromStoryboard() {
        XCTAssertTrue(viewController.view is ArcMediaPlayerView)
    }

    func testLoadSampleVideo() throws {
        let client = ArcMediaSampleClient()
        let exp = expectation(description: "the sample video should have been loaded")
        let adParams = LivestreamAdParams(adsParams: ["device": UIDevice.current.model])
        var adSettings = LivestreamAdSettings()
        adSettings.adParams = adParams

        client.video(mediaID: "id",
                     adSettings: adSettings,
                     accessToken: "token") { [unowned self] (videoResult) in
                        switch videoResult {
                        case .success(let video):
                            let videoItem = AVPlayerItem(asset: video)
                            viewController.playerController?.load(playerItem: videoItem)
                            let videoPlayer = viewController.playerView
                            XCTAssertFalse(videoPlayer.player.isPlaying)
                            exp.fulfill()
                        case .failure:
                            XCTFail("the sample video should have been loaded")
                        }
        }

        wait(for: [exp], timeout: TestConstant.standardTimeout)
    }

#if os(iOS)
    func testTogglePlayAndPauseWhenTappingPlayButton() {
        let player = viewController.player
        let playerItem = AVPlayerItem(url: fifteenSecondVideoUrl)
        viewController.player.replaceCurrentItem(with: playerItem)
        let playerView = viewController.playerView

        let firstPausedExpectation = expectation(description: "First pause")
        player.fire(at: 5.0) { [unowned self] in
            XCTAssertTrue(viewController.isPlaying)
            viewController.play(sender: playerView.controlBarPlayButton)
            firstPausedExpectation.fulfill()
        }

        player.rate = 1.0
        wait(for: [firstPausedExpectation], timeout: TestConstant.standardTimeout)
        XCTAssertFalse(viewController.isPlaying)

        // Resume playing.
        viewController.play(sender: playerView.controlBarPlayButton)

        let secondPausedExpectation = expectation(description: "Second pause")
        player.fire(at: player.currentTime().seconds + 5.0) { [unowned self] in
            XCTAssertTrue(viewController.isPlaying)
            viewController.play(sender: playerView.controlBarPlayButton)
            secondPausedExpectation.fulfill()
        }

        wait(for: [secondPausedExpectation], timeout: TestConstant.standardTimeout)
        XCTAssertFalse(viewController.isPlaying)
    }

    func testToggleMute() {
        let player = viewController.player
        let playerItem = AVPlayerItem(url: fifteenSecondVideoUrl)
        viewController.player.replaceCurrentItem(with: playerItem)
        let playerView = viewController.playerView

        let mutedExpectation = expectation(description: "Muted")
        player.fire(at: 3.0) { [unowned self] in
            viewController.mute(sender: playerView.volumeButton!)
            mutedExpectation.fulfill()
        }

        let unmutedExpectation = expectation(description: "Unmuted")
        player.fire(at: 8.0) { [unowned self] in
            viewController.mute(sender: playerView.volumeButton!)
            unmutedExpectation.fulfill()
        }

        player.play()
        player.isMuted = false

        wait(for: [mutedExpectation], timeout: TestConstant.standardTimeout)
        XCTAssertTrue(player.isMuted)

        wait(for: [unmutedExpectation], timeout: TestConstant.standardTimeout)
        XCTAssertFalse(player.isMuted)
    }
#endif

    // MARK: - Captions

    lazy var videoWithCaptions: ArcVideo = {
        let captionsUrl = testBundle.url(forResource: "VttSampleFile", withExtension: "vtt")

        return ArcVideo(streamUrl: fifteenSecondVideoUrl,
                        clientSideCaptionsUrl: captionsUrl)
    }()

    func testVideoHasClientSideCaptions() {
        let playerItem = AVPlayerItem(asset: videoWithCaptions)
        XCTAssertTrue(playerItem.hasClosedCaptions)
        XCTAssertTrue(playerItem.hasClientSideCaptions)
        XCTAssertFalse(playerItem.hasEmbeddedCaptions())
    }

    func testShowAndHideClosedCaptions() {
        let playerView = viewController.playerView

        Settings.showClosedCaptions.set(false)
        XCTAssertFalse(viewController.isClosedCaptioningAvailable)

        #if os(iOS)
        XCTAssertFalse(playerView.closedCaptionsButton!.isEnabled)
        #endif

        let playerItem = AVPlayerItem(asset: videoWithCaptions)
        viewController.player.replaceCurrentItem(with: playerItem)
        XCTAssertTrue(viewController.isClosedCaptioningAvailable)

        // tvOS turns on captions by default when a new player item is
        // loaded, so we have to manually turn them off before we can test
        // whether the toggle works.
        #if os(tvOS)
        viewController.hideClosedCaptions()
        #endif

        // Show captions
        viewController.toggleClosedCaptions()
        XCTAssertTrue(Settings.showClosedCaptions.get)
        XCTAssertTrue(playerView.isDisplayingClosedCaptions)

        #if os(iOS)
        XCTAssertTrue(playerView.closedCaptionsButton!.isEnabled)
        #endif

        // Hide captions
        viewController.toggleClosedCaptions()
        XCTAssertFalse(Settings.showClosedCaptions.get)
        XCTAssertFalse(playerView.isDisplayingClosedCaptions)

        #if os(iOS)
        XCTAssertTrue(playerView.closedCaptionsButton!.isEnabled)
        #endif
    }

    func testClientSideCaptions() {
        Settings.showClosedCaptions.set(true)

        let playerView = viewController.playerView
        let player = viewController.player
        let playerItem = AVPlayerItem(asset: videoWithCaptions)
        player.replaceCurrentItem(with: playerItem)

        let firstCaptionExpectation = expectation(description: "First caption")
        player.fire(at: 6.0) {
            XCTAssertNotNil(playerView.captionsLabel)
            firstCaptionExpectation.fulfill()
        }

        let secondCaptionExpectation = expectation(description: "Second caption")
        player.fire(at: 12.0) {
            XCTAssertNotNil(playerView.captionsLabel)
            secondCaptionExpectation.fulfill()
        }

        player.play()
        wait(for: [firstCaptionExpectation, secondCaptionExpectation], timeout: TestConstant.longTimeout)
    }

    func testClientSideCaptionsFromViewController() {
        viewController.showClosedCaptions()
    }
}
