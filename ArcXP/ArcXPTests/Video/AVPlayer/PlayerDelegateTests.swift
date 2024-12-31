//  Copyright © 2021 The Washington Post. All rights reserved.

@testable import ArcXP

import AVFoundation
import XCTest

/// Runs through all of the ad-related default implementations to make sure
/// that nothing crashes and to bump up unit-test coverage. :)
class PlayerDelegateTests: ArcMediaTestBase {

    /// An implementation of `PlayerDelegate` that simply uses the empty
    /// function implementations in the `PlayerDelegate` extension.
    class EmptyPlayerDelegate: NSObject, PlayerDelegate { }

    // swiftlint:disable identifier_name function_body_length

    func testAllAdDelegateCalls() throws {
        let delegate = EmptyPlayerDelegate()
        let player = AVPlayer()

        // Captioning

        delegate.player(player, captionsOn: .clientSide)
        delegate.playerCaptionsOff(player)

        // Player Lifecycle

        let item = AVPlayerItem(url: fiveSecondVideoUrl)
        delegate.player(player, currentItemChangedFrom: item)
        delegate.player(player, error: nil)
        delegate.playerAppeared(player)
        delegate.playerReady(player)
        delegate.playerStatusUnknown(player)
        delegate.player(player, item: item, error: nil)
        delegate.player(player, itemReady: item)
        delegate.player(player, itemStatusUnknown: item)
        delegate.player(player, completed: item)
        delegate.player(player, played25Percent: item)
        delegate.player(player, played50Percent: item)
        delegate.player(player, played75Percent: item)
        delegate.player(player, item: item, playedPercent: 0.6)
        delegate.player(player, started: item, byUser: false)

        // Muting & Volume

        delegate.playerMuted(player)
        delegate.playerUnmuted(player)
        delegate.player(player, volumeChangedFrom: 0.5)

        // User Interaction

        delegate.player(player, paused: item)
        delegate.player(player, resumed: item)
        delegate.playerTapped(player, item: item)
        delegate.playerBeganFullScreenPresentation(player, item: item)
        delegate.playerEndedFullScreenPresentation(player, item: item)
        delegate.player(player, item: item, skippedTo: CMTime(seconds: 2.0, preferredTimescale: 1))

        // Ad Breaks

        delegate.player(player, adBreakEnded: nil)
        delegate.player(player, adBreakStarted: nil)

        // Ad Playback

        let ad: Any? = nil
        delegate.player(player, adCompleted: ad)
        delegate.player(player, adImpression: ad)
        delegate.player(player, adInfo: ad, adError: nil)
        delegate.player(player, adPlayed25Percent: ad)
        delegate.player(player, adPlayed50Percent: ad)
        delegate.player(player, adPlayed75Percent: ad)
        delegate.player(player, adStarted: ad)
        delegate.player(player, adPaused: ad)
        delegate.player(player, adResumed: ad)
        delegate.player(player, adSkipped: ad)
        delegate.player(player, adTapped: ad)

        delegate.player(player, adMuted: ad)
        delegate.player(player, adUnmuted: ad)
        delegate.player(player, adInfo: ad, volumeChangedFrom: 0.5)
        delegate.player(player, adClicked: ad)

        // PAL
        delegate.playerInitializedwithPAL(nonce: "Nonce")
        delegate.player(palError: nil)
        delegate.playerReportedAdClickPAL(nonce: "Nonce")
        delegate.playerReportedVideoStartPAL(nonce: "Nonce")
        delegate.playerReportedVideoEndPAL(nonce: "Nonce")
    }

}
