//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import AVFoundation
import XCTest

class MockPlayerDelegate: NSObject, PlayerDelegate {

    enum Call: Equatable {

        case playerAppeared
        case playerError

        // Ads

        case playerAdBreakEnded
        case playerAdBreakStarted
        case playerAdCompleted
        case playerAdImpression
        case playerAdError
        case playerAdInfo
        case playerAdPaused
        case playerAdPlayed25Percent
        case playerAdPlayed50Percent
        case playerAdPlayed75Percent
        case playerAdResumed
        case playerAdSkipped
        case playerAdStarted
        case playerAdTapped
        case playerAdMuted
        case playerAdUnmuted
        case playerAdVolumeChanged

        // PAL
        case playerInitializedPAL
        case playerPALerror
        case playerPALreportedAdClick
        case playerPALreportedVideoStart
        case playerPALreportedVideoEnd

        // Playback

        case playerCompleted
        case playerPaused
        case playerPlayed25Percent
        case playerPlayed50Percent
        case playerPlayed75Percent
        case playerPlayedPercent(Double)
        case playerResumed
        case playerSkippedTo(ImpreciseCMTime)
        case playerStarted
        case playerWaiting

        // AVPlayer.currentItem

        case playerItemChanged(oldItem: AVPlayerItem?, newItem: AVPlayerItem?)

        // AVPlayer.isMuted

        case playerMuted
        case playerUnmuted

        // AVPlayer.status

        case playerStatusFailed
        case playerStatusReady
        case playerStatusUnknown

        // AVPlayer.timeControlStatus

        // AVPlayerItem.status

        case playerItemStatusFailed
        case playerItemStatusReady
        case playerItemStatusUnknown

        // AVPlayer.volume

        case playerVolumeChanged

        // Captioning

        case playerCaptionsOn
        case playerCaptionsOff

        // Player View

        case playerViewControlBarDidAppear
        case playerViewControlBarDidDisappear
        case playerViewControlBarWillAppear
        case playerViewControlBarWillDisappear

    }

    var calls = [Call]()

    func reset() {
        calls = []
    }

    func playerAppeared(_ player: AVPlayer) {
        calls.append(.playerAppeared)
    }

    // MARK: - Ads

    func player(_ player: AVPlayer, error: Error?) {
        calls.append(.playerError)
    }

    func player(_ player: AVPlayer, adBreakEnded adInfo: Any?) {
        calls.append(.playerAdBreakEnded)
    }

    func player(_ player: AVPlayer, adBreakStarted adInfo: Any?) {
        calls.append(.playerAdBreakStarted)
    }

    func player(_ player: AVPlayer, adCompleted adInfo: Any?) {
        calls.append(.playerAdCompleted)
    }

    func player(_ player: AVPlayer, adImpression adInfo: Any?) {
        calls.append(.playerAdImpression)
    }

    func player(_ player: AVPlayer, adInfo: Any?, adError: Error?) {
        calls.append(.playerAdError)
    }

    func player(_ player: AVPlayer, adPaused adInfo: Any?) {
        calls.append(.playerAdPaused)
    }

    func player(_ player: AVPlayer, adPlayed25Percent adInfo: Any?) {
        calls.append(.playerAdPlayed25Percent)
    }

    func player(_ player: AVPlayer, adPlayed50Percent adInfo: Any?) {
        calls.append(.playerAdPlayed50Percent)
    }

    func player(_ player: AVPlayer, adPlayed75Percent adInfo: Any?) {
        calls.append(.playerAdPlayed75Percent)
    }

    func player(_ player: AVPlayer, adResumed adInfo: Any?) {
        calls.append(.playerAdResumed)
    }

    func player(_ player: AVPlayer, adSkipped adInfo: Any?) {
        calls.append(.playerAdSkipped)
    }

    func player(_ player: AVPlayer, adStarted adInfo: Any?) {
        calls.append(.playerAdStarted)
    }

    func player(_ player: AVPlayer, adTapped adInfo: Any?) {
        calls.append(.playerAdTapped)
    }

    func player(_ player: AVPlayer, adMuted: Any?) {
        calls.append(.playerAdMuted)
    }

    func player(_ player: AVPlayer, adUnmuted: Any?) {
        calls.append(.playerAdUnmuted)
    }

    func player(_ player: AVPlayer, adInfo: Any?, volumeChangedFrom previousVolume: Float?) {
        calls.append(.playerAdVolumeChanged)
    }
    
    func playerInitializedwithPAL(nonce: String) {
        calls.append(.playerInitializedPAL)
    }
    
    func player(palError: Error?) {
        calls.append(.playerPALerror)
    }
    
    func playerReportedAdClickPAL(nonce: String?) {
        calls.append(.playerPALreportedAdClick)
    }
    
    func playerReportedVideoStartPAL(nonce: String?) {
        calls.append(.playerPALreportedVideoStart)
    }
    
    func playerReportedVideoEndPAL(nonce: String?) {
        calls.append(.playerPALreportedVideoEnd)
    }

    // MARK: - Playback

    func player(_ player: AVPlayer, completed item: AVPlayerItem?) {
        calls.append(.playerCompleted)
    }

    func player(_ player: AVPlayer, paused item: AVPlayerItem?) {
        calls.append(.playerPaused)
    }

    func player(_ player: AVPlayer, played25Percent item: AVPlayerItem?) {
        calls.append(.playerPlayed25Percent)
    }

    func player(_ player: AVPlayer, played50Percent item: AVPlayerItem?) {
        calls.append(.playerPlayed50Percent)
    }

    func player(_ player: AVPlayer, played75Percent item: AVPlayerItem?) {
        calls.append(.playerPlayed75Percent)
    }

    func player(_ player: AVPlayer, item: AVPlayerItem?, playedPercent percent: Double) {
        calls.append(.playerPlayedPercent(percent))
    }

    func player(_ player: AVPlayer, resumed item: AVPlayerItem?) {
        calls.append(.playerResumed)
    }

    func player(_ player: AVPlayer, item: AVPlayerItem?, skippedTo time: CMTime) {
        calls.append(.playerSkippedTo(ImpreciseCMTime(time)))
    }

    func player(_ player: AVPlayer, started item: AVPlayerItem?, byUser: Bool) {
        calls.append(.playerStarted)
    }

    func player(_ player: AVPlayer, waiting item: AVPlayerItem?) {
        calls.append(.playerWaiting)
    }

    // MARK: - Mute/unmute & Volume

    func playerMuted(_ player: AVPlayer) {
        calls.append(.playerMuted)
    }

    func playerUnmuted(_ player: AVPlayer) {
        calls.append(.playerUnmuted)
    }

    func player(_ player: AVPlayer,
                volumeChangedFrom previousVolume: Float?) {
        calls.append(.playerVolumeChanged)
    }

    // MARK: - Player Status

    func playerReady(_ player: AVPlayer) {
        calls.append(.playerStatusReady)
    }

    func playerStatusUnknown(_ player: AVPlayer) {
        calls.append(.playerStatusUnknown)
    }

    // MARK: - Player Item Status

    func player(_ player: AVPlayer, item: AVPlayerItem?, error: Error?) {
        calls.append(.playerAdError)
    }

    func player(_ player: AVPlayer, itemReady item: AVPlayerItem?) {
        calls.append(.playerItemStatusReady)
    }

    func player(_ player: AVPlayer, itemStatusUnknown item: AVPlayerItem?) {
        calls.append(.playerItemStatusUnknown)
    }

    // MARK: - Captioning

    func player(_ player: AVPlayer, captionsOn captionType: AVPlayerItem.CaptionType) {
        calls.append(.playerCaptionsOn)
    }

    func playerCaptionsOff(_ player: AVPlayer) {
        calls.append(.playerCaptionsOff)
    }

    // MARK: - AVPlayerItem.currentItem

    func player(_ player: AVPlayer, currentItemChangedFrom oldPlayerItem: AVPlayerItem?) {
        calls.append(.playerItemChanged(oldItem: oldPlayerItem, newItem: player.currentItem))
    }

}

extension MockPlayerDelegate: ArcMediaPlayerViewDelegate {

    func playerViewControlBarDidAppear(_ playerView: ArcMediaPlayerView) {
        calls.append(.playerViewControlBarDidAppear)
    }

    func playerViewControlBarDidDisappear(_ playerView: ArcMediaPlayerView) {
        calls.append(.playerViewControlBarDidDisappear)
    }

    func playerViewControlBarWillAppear(_ playerView: ArcMediaPlayerView) {
        calls.append(.playerViewControlBarDidDisappear)
    }

    func playerViewControlBarWillDisappear(_ playerView: ArcMediaPlayerView) {
        calls.append(.playerViewControlBarDidDisappear)
    }

    // MARK: - Test Fixtures & Assertions

    func standardStartupCalls(for item: AVPlayerItem) -> [MockPlayerDelegate.Call] {
        return [.playerItemChanged(oldItem: nil, newItem: item),
                .playerVolumeChanged,
                .playerUnmuted,
                .playerItemStatusReady,
                .playerResumed,
                .playerStarted]
    }

    func wereExpectedCallsMade(_ expectedCalls: [MockPlayerDelegate.Call]) -> Bool {
        var actualCalls = self.calls

        guard actualCalls.count >= expectedCalls.count else {
            print("Expected \(expectedCalls.count) to be made, but only \(actualCalls.count) were.")

            return false
        }

        var remainingExpectedCalls = expectedCalls

        while !actualCalls.isEmpty && !remainingExpectedCalls.isEmpty {
            var actualCall = actualCalls.first!
            let expectedCall = remainingExpectedCalls.first!
            remainingExpectedCalls = Array(remainingExpectedCalls.dropFirst())
            actualCalls = Array(actualCalls.dropFirst())

            if actualCall == expectedCall {
                // They're the same, so that's good.
                print("✓ Expected and got \(expectedCall)")
            } else {
                while !actualCalls.isEmpty && actualCall != expectedCall {
                    actualCall = actualCalls.first!
                    actualCalls = Array(actualCalls.dropFirst())

                    if actualCall == expectedCall {
                        print("✓ Expected and got \(expectedCall)")
                        break
                    } else {
                        print("! Expected \(expectedCall); got \(actualCall)")
                    }
                }
            }
        }

        if !remainingExpectedCalls.isEmpty && actualCalls.isEmpty {
            print("Failed to make one or more calls: \(remainingExpectedCalls)")
            return false
        }

        return true
    }

}

/// Wraps a `CMTime` and implements `Equatable` to compare times using
/// floating-point math.
struct ImpreciseCMTime: Equatable {

    static var accuracy: Double = 0.01

    let time: CMTime

    init(_ time: CMTime) {
        self.time = time
    }

    // MARK: - Equatable

    static func == (lhs: ImpreciseCMTime, rhs: ImpreciseCMTime) -> Bool {
        return lhs == rhs.time // call the other == function, below
    }

    static func == (lhs: ImpreciseCMTime, rhs: CMTime) -> Bool {
        return abs(lhs.time.seconds - rhs.seconds) <= ImpreciseCMTime.accuracy
    }

}
