//  Copyright © 2021 The Washington Post. All rights reserved.

@testable import ArcXP

import AVFoundation
import XCTest

// swiftlint:disable type_body_length

class MediaEventTests: ArcMediaTestBase {

    var video1: AVPlayerItem!
    var video2: AVPlayerItem!
    var player1: AVPlayer!
    var player2: AVPlayer!
    var ad1: LivestreamAd!
    var ad2: LivestreamAd!

    override func setUp() {
        super.setUp()
        video1 = AVPlayerItem(url: fiveSecondVideoUrl)
        video2 = AVPlayerItem(url: fifteenSecondVideoUrl)
        player1 = AVPlayer()
        player2 = AVPlayer()
        ad1 = LivestreamAd(adId: "12345")
        ad2 = LivestreamAd(adId: "67890")
    }

    // MARK: - Captions

    func testPlayerCaptionsOn() {
        checkEqualAndNotEqual(
            .playerCaptionsOn(player1, captionType: .clientSide),
            .playerCaptionsOn(player1, captionType: .embedded(locale: .current))
        )
        checkEqualAndNotEqual(
            .playerCaptionsOn(player1, captionType: .clientSide),
            .playerCaptionsOn(player2, captionType: .clientSide)
        )
        checkEqualAndNotEqual(
            .playerCaptionsOn(player1, captionType: .embedded(locale: Locale(identifier: "en-US"))),
            .playerCaptionsOn(player1, captionType: .embedded(locale: Locale(identifier: "de")))
        )
    }

    func testPlayerCaptionsOff() {
        checkEqualAndNotEqual(
            .playerCaptionsOff(player1),
            .playerCaptionsOff(player2)
        )
    }

    // MARK: - Player Lifecycle

    func testPlayerCurrentItemChanged() {
        checkEqualAndNotEqual(
            .playerCurrentItemChanged(player1, fromOldItem: video1),
            .playerCurrentItemChanged(player1, fromOldItem: video2)
        )
        checkEqualAndNotEqual(
            .playerCurrentItemChanged(player1, fromOldItem: video1),
            .playerCurrentItemChanged(player2, fromOldItem: video1)
        )
    }

    func testPlayerAppeared() {
        checkEqualAndNotEqual(
            .playerAppeared(player1),
            .playerAppeared(player2)
        )
    }

    func testPlayerReady() {
        checkEqualAndNotEqual(
            .playerReady(player1),
            .playerReady(player2)
        )
    }

    func testPlayerStatusUnknown() {
        checkEqualAndNotEqual(
            .playerStatusUnknown(player1),
            .playerStatusUnknown(player2)
        )
    }

    // AVPlayerItem Lifecycle

    func testPlayerItemReady() {
        checkEqualAndNotEqual(
            .playerItemReady(player1, item: video1),
            .playerItemReady(player1, item: video2)
        )
        checkEqualAndNotEqual(
            .playerItemReady(player1, item: video1),
            .playerItemReady(player2, item: video1)
        )
    }

    func testPlayerItemStatusUnknown() {
        checkEqualAndNotEqual(
            .playerItemStatusUnknown(player1, item: video1),
            .playerItemStatusUnknown(player1, item: video2)
        )
        checkEqualAndNotEqual(
            .playerItemStatusUnknown(player1, item: video1),
            .playerItemStatusUnknown(player2, item: video1)
        )
    }

    // Playback

    func testPlayerItemCompleted() {
        checkEqualAndNotEqual(
            .playerItemCompleted(player1, item: video1),
            .playerItemCompleted(player1, item: video2)
        )
        checkEqualAndNotEqual(
            .playerItemCompleted(player1, item: video1),
            .playerItemCompleted(player2, item: video1)
        )
    }

    func testPlayerItemPlayed25Percent() {
        checkEqualAndNotEqual(
            .playerItemPlayed25Percent(player1, item: video1),
            .playerItemPlayed25Percent(player1, item: video2)
        )
        checkEqualAndNotEqual(
            .playerItemPlayed25Percent(player1, item: video1),
            .playerItemPlayed25Percent(player2, item: video1)
        )
    }

    func testPlayerItemPlayed50Percent() {
        checkEqualAndNotEqual(
            .playerItemPlayed50Percent(player1, item: video1),
            .playerItemPlayed50Percent(player1, item: video2)
        )
        checkEqualAndNotEqual(
            .playerItemPlayed50Percent(player1, item: video1),
            .playerItemPlayed50Percent(player2, item: video1)
        )
    }

    func testsPlayerItemPlayed75Percent() {
        checkEqualAndNotEqual(
            .playerItemPlayed75Percent(player1, item: video1),
            .playerItemPlayed75Percent(player1, item: video2)
        )
        checkEqualAndNotEqual(
            .playerItemPlayed75Percent(player1, item: video1),
            .playerItemPlayed75Percent(player2, item: video1)
        )
    }

    func testPlayerItemPlayedPercent() {
        // Different videos
        checkEqualAndNotEqual(
            .playerItemPlayedPercent(player1, item: video1, percent: 0.4),
            .playerItemPlayedPercent(player1, item: video2, percent: 0.4)
        )
        // Different players
        checkEqualAndNotEqual(
            .playerItemPlayedPercent(player1, item: video1, percent: 0.4),
            .playerItemPlayedPercent(player2, item: video1, percent: 0.4)
        )
        // Different percentages
        checkEqualAndNotEqual(
            .playerItemPlayedPercent(player1, item: video1, percent: 0.3),
            .playerItemPlayedPercent(player1, item: video1, percent: 0.8)
        )
    }

    // AVPlayer.isMuted & .volume

    func testPlayerMuted() {
        checkEqualAndNotEqual(
            .playerMuted(player1),
            .playerMuted(player2)
        )
    }

    func testPlayerUnmuted() {
        checkEqualAndNotEqual(
            .playerUnmuted(player1),
            .playerUnmuted(player2)
        )
    }

    func testPlayerVolumedChangedWithDifferentPlayersAndSameVolume() {
        checkEqualAndNotEqual(
            .playerVolumedChanged(player1, previousVolume: 0.5),
            .playerVolumedChanged(player2, previousVolume: 0.5)
        )
        checkEqualAndNotEqual(
            .playerVolumedChanged(player1, previousVolume: 0.5),
            .playerVolumedChanged(player1, previousVolume: 0.85)
        )
    }

    // User Interaction

    func testPlayerPaused() {
        checkEqualAndNotEqual(
            .playerPaused(player1, item: video1),
            .playerPaused(player1, item: video2)
        )
        checkEqualAndNotEqual(
            .playerPaused(player1, item: video1),
            .playerPaused(player2, item: video1)
        )
    }

    func testPlayerPlaying() {
        checkEqualAndNotEqual(
            .playerPlaying(player1, item: video1),
            .playerPlaying(player1, item: video2)
        )
        checkEqualAndNotEqual(
            .playerPlaying(player1, item: video1),
            .playerPlaying(player2, item: video1)
        )
    }

    func testPlayerWaiting() {
        checkEqualAndNotEqual(
            .playerWaiting(player1, item: video1),
            .playerWaiting(player1, item: video2)
        )
        checkEqualAndNotEqual(
            .playerWaiting(player1, item: video1),
            .playerWaiting(player2, item: video1)
        )
    }

    func testPlayerTapped() {
        checkEqualAndNotEqual(
            .playerTapped(player1, item: video1),
            .playerTapped(player1, item: video2)
        )
        checkEqualAndNotEqual(
            .playerTapped(player1, item: video1),
            .playerTapped(player2, item: video1)
        )
    }

    // Ad Interactions

    func testPlayerAdSkipped() {
        checkEqualAndNotEqual(
            .playerAdSkipped(player1, adInfo: ad1),
            .playerAdSkipped(player2, adInfo: ad1)
        )
    }

    func testPlayerAdReturnedToNormalSize() {
        checkEqualAndNotEqual(
            .playerAdReturnedToNormalSize(player1, adInfo: ad1),
            .playerAdReturnedToNormalSize(player2, adInfo: ad1)
        )
    }

    func testPlayerAdWentFullscreen() {
        checkEqualAndNotEqual(
            .playerAdWentFullscreen(player1, adInfo: ad1),
            .playerAdWentFullscreen(player2, adInfo: ad1)
        )
    }

    func testPlayerAdVolumeChanged() {
        // Different players
        checkEqualAndNotEqual(
            .playerAdVolumeChanged(player1, adInfo: ad1, previousVolume: 0.5),
            .playerAdVolumeChanged(player2, adInfo: ad1, previousVolume: 0.5)
        )
        // Different volumes
        checkEqualAndNotEqual(
            .playerAdVolumeChanged(player1, adInfo: ad1, previousVolume: 0.25),
            .playerAdVolumeChanged(player1, adInfo: ad2, previousVolume: 0.75)
        )
    }

    func testPlayerAdMuted() {
        checkEqualAndNotEqual(
            .playerAdMuted(player1, adInfo: ad1),
            .playerAdMuted(player2, adInfo: ad2)
        )
    }

    func testPlayerAdUnmuted() {
        checkEqualAndNotEqual(
            .playerAdUnmuted(player1, adInfo: ad1),
            .playerAdUnmuted(player2, adInfo: ad2)
        )
    }

    func testAdClicked() {
        checkEqualAndNotEqual(
            .playerAdClicked(player1, adInfo: ad1),
            .playerAdClicked(player2, adInfo: ad2)
        )
    }

    func testPlayerAdWillOpenExternalApplication() {
        checkEqualAndNotEqual(
            .playerAdWillOpenExternalApplication(player: player1),
            .playerAdWillOpenExternalApplication(player: player2)
        )
    }

    func testPlayerAdWillOpenInAppLink() {
        checkEqualAndNotEqual(
            .playerAdWillOpenInAppLink(player: player1),
            .playerAdWillOpenInAppLink(player: player2)
        )
    }

    func testPlayerAdDidOpenInAppLink() {
        checkEqualAndNotEqual(
            .playerAdDidOpenInAppLink(player: player1),
            .playerAdDidOpenInAppLink(player: player2)
        )
    }

    func testPlayerAdWillCloseInAppLink() {
        checkEqualAndNotEqual(
            .playerAdWillCloseInAppLink(player: player1),
            .playerAdWillCloseInAppLink(player: player2)
        )
    }

    func testPlayerAdDidCloseInAppLink() {
        checkEqualAndNotEqual(
            .playerAdDidCloseInAppLink(player: player1),
            .playerAdDidCloseInAppLink(player: player2)
        )
    }

    // Ad Lifecycle

    func testPlayerAdLoaded() {
        checkEqualAndNotEqual(
            .playerAdLoaded(player1, adInfo: ad1),
            .playerAdLoaded(player2, adInfo: ad2)
        )
    }

    func testPlayerAdPaused() {
        checkEqualAndNotEqual(
            .playerAdPaused(player1, adInfo: ad1),
            .playerAdPaused(player2, adInfo: ad2)
        )
    }

    func testPlayerAdPlaying() {
        checkEqualAndNotEqual(
            .playerAdPlaying(player1, adInfo: ad1),
            .playerAdPlaying(player2, adInfo: ad2)
        )
    }

    // Ad Playback

    func testPlayerAdBreakStarted() {
        let adBreak1 = LivestreamAdBreak(adBreakId: "12345")
        let adBreak2 = LivestreamAdBreak(adBreakId: "67890")
        checkEqualAndNotEqual(
            .playerAdBreakStarted(player1, adBreak: adBreak1),
            .playerAdBreakStarted(player2, adBreak: adBreak1)
        )
        checkEqualAndNotEqual(
            .playerAdBreakStarted(player1, adBreak: adBreak1),
            .playerAdBreakStarted(player1, adBreak: adBreak2)
        )
    }

    func testPlayerAdBreakEnded() {
        let adBreak1 = LivestreamAdBreak(adBreakId: "12345")
        let adBreak2 = LivestreamAdBreak(adBreakId: "67890")
        checkEqualAndNotEqual(
            .playerAdBreakEnded(player1, adBreak: adBreak1),
            .playerAdBreakEnded(player2, adBreak: adBreak1)
        )
        checkEqualAndNotEqual(
            .playerAdBreakEnded(player1, adBreak: adBreak1),
            .playerAdBreakEnded(player1, adBreak: adBreak2)
        )
    }

    func testPlayerAdStarted() {
        checkEqualAndNotEqual(
            .playerAdStarted(player1, adInfo: ad1),
            .playerAdStarted(player2, adInfo: ad2)
        )
    }

    func testPlayerAdImpression() {
        checkEqualAndNotEqual(
            .playerAdImpression(player1, adInfo: ad1),
            .playerAdImpression(player2, adInfo: ad2)
        )
    }

    func testPlayerAdPlayed25Percent() {
        checkEqualAndNotEqual(
            .playerAdPlayed25Percent(player1, adInfo: ad1),
            .playerAdPlayed25Percent(player2, adInfo: ad2)
        )
    }

    func testPlayerAdPlayed50Percent() {
        checkEqualAndNotEqual(
            .playerAdPlayed50Percent(player1, adInfo: ad1),
            .playerAdPlayed50Percent(player2, adInfo: ad2)
        )
    }

    func testPlayerAdPlayed75Percent() {
        checkEqualAndNotEqual(
            .playerAdPlayed75Percent(player1, adInfo: ad1),
            .playerAdPlayed75Percent(player2, adInfo: ad2)
        )
    }

    func testPlayerAdCompleted() {
        checkEqualAndNotEqual(
            .playerAdCompleted(player1, adInfo: ad1),
            .playerAdCompleted(player2, adInfo: ad2)
        )
    }

    // Test fixtures

    func checkEqualAndNotEqual(_ event1: MediaEvent,
                               _ event2: MediaEvent,
                               file: String = #file,
                               line: UInt = #line) {
        XCTAssertEqual(event1, event1)
        XCTAssertNotEqual(event1, event2)
    }

}

// swiftlint:enable type_body_length
