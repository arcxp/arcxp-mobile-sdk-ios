//  Copyright © 2020 The Washington Post. All rights reserved.

import AVFoundation
import Foundation

/// A ``MediaEventSubscriber`` that calls functions on a ``PlayerDelegate``.
class DelegatingMediaEventSubscriber: NSObject, MediaEventSubscriber {

    // MARK: - Open Properties

    /// The delegate that framework users implement to track player events.
    weak var delegate: PlayerDelegate?

    // MARK: - Initialization

    /// Construct the observer with a player instance and optional delegate. If
    /// the delegate never gets set, then there's not much point to using an
    /// instance of this, but that's up to you.
    init(delegate: PlayerDelegate? = nil) {
        super.init()
        self.delegate = delegate
    }

    // swiftlint:disable cyclomatic_complexity function_body_length

    /// Receive a ``MediaEvent`` and call its corresponding function on a
    /// ``PlayerDelegate``.
    func receiveEvent(_ event: MediaEvent) {
        switch event {

        // MARK: - Playback

        case .playerItemCompleted(let player, let item):
            delegate?.player(player, completed: item)
        case .playerItemStarted(let player, let item):
            delegate?.player(player, started: item, byUser: false)
        case .playerItemPlayedPercent(let player, let item, let percent):
            switch percent {
            case 0.24...0.26:
                delegate?.player(player, played25Percent: player.currentItem)
            case 0.49...0.51:
                delegate?.player(player, played50Percent: player.currentItem)
            case 0.74...0.76:
                delegate?.player(player, played75Percent: player.currentItem)
            default:
                delegate?.player(player,
                                 item: item,
                                 playedPercent: percent)
            }
        case .playerCurrentItemChanged(let player, let oldPlayerItem):
            delegate?.player(player, currentItemChangedFrom: oldPlayerItem)

        // MARK: - AVPlayer.isMuted && .volume

        case .playerMuted(let player):
            delegate?.playerMuted(player)
        case .playerUnmuted(let player):
            delegate?.playerUnmuted(player)
        case .playerVolumedChanged(let player, let previousVolume):
            delegate?.player(player, volumeChangedFrom: previousVolume)

        // MARK: - AVPlayer.status (NOT AVPlayerItem.status!)

        case .playerError(let player, let error):
            delegate?.player(player, error: error)

        // MARK: - AVPlayer.timeControlStatus (i.e. play/pause)

        case .playerPlaying(let player, let item):
            delegate?.player(player, resumed: item)
        case .playerPaused(let player, let item):
            delegate?.player(player, paused: item)

        // MARK: - AVPlayerItem.status

        case .playerItemError(let player, let item, let error):
            delegate?.player(player, item: item, error: error)
        case .playerItemStatusUnknown(let player, let item):
            delegate?.player(player, itemStatusUnknown: item)
        case .playerItemReady(let player, let item):
            delegate?.player(player, itemReady: item)

        case .playerCaptionsOn(let player, let captionType):
            delegate?.player(player, captionsOn: captionType)
        case .playerCaptionsOff(let player):
            delegate?.playerCaptionsOff(player)

        case .playerAppeared(let player):
            delegate?.playerAppeared(player)
        case .playerReady(let player):
            delegate?.playerReady(player)
        case .playerStatusUnknown(let player):
            delegate?.playerStatusUnknown(player)
        case .playerItemPlayed25Percent(let player, let item):
            delegate?.player(player, played25Percent: item)
        case .playerItemPlayed50Percent(let player, let item):
            delegate?.player(player, played50Percent: item)
        case .playerItemPlayed75Percent(let player, item: let item):
            delegate?.player(player, played75Percent: item)
        case .playerTapped(let player, let item):
            delegate?.playerTapped(player, item: item)
        case .playerBeganFullScreenPresentation(let player, let item):
            delegate?.playerBeganFullScreenPresentation(player, item: item)
        case .playerEndedFullScreenPresentation(let player, let item):
            delegate?.playerEndedFullScreenPresentation(player, item: item)
        case .playerItemSkipped(let player, let item, let time):
            delegate?.player(player, item: item, skippedTo: time)
        case .playerAdTapped(let player, let adInfo):
            delegate?.player(player, adTapped: adInfo)
        case .playerAdReturnedToNormalSize,
                .playerWaiting,
                .playerAdWentFullscreen,
                .playerAdLoaded:
            // no corresponding delegate call
            break

        // MARK: - Ads

        case .playerAdBreakStarted(let player, let adBreak):
            delegate?.player(player, adBreakStarted: adBreak)
        case .playerAdBreakEnded(let player, let adBreak):
            delegate?.player(player, adBreakEnded: adBreak)
        case .playerAdError(let player, let adInfo, let error):
            delegate?.player(player, adInfo: adInfo, adError: error)
        case .playerAdPaused(let player, let adInfo):
            delegate?.player(player, adPaused: adInfo)
        case .playerAdPlaying(let player, let adInfo):
            delegate?.player(player, adResumed: adInfo)
        case .playerAdStarted(let player, let adInfo):
            delegate?.player(player, adStarted: adInfo)
        case .playerAdImpression(let player, let adInfo):
            delegate?.player(player, adImpression: adInfo)
        case .playerAdPlayed25Percent(let player, let adInfo):
            delegate?.player(player, adPlayed25Percent: adInfo)
        case .playerAdPlayed50Percent(let player, let adInfo):
            delegate?.player(player, adPlayed50Percent: adInfo)
        case .playerAdPlayed75Percent(let player, let adInfo):
            delegate?.player(player, adPlayed75Percent: adInfo)
        case .playerAdCompleted(let player, let adInfo):
            delegate?.player(player, adCompleted: adInfo)
        case .playerAdSkipped(let player, let adInfo):
            delegate?.player(player, adSkipped: adInfo)
        case .playerAdMuted(let player, let adInfo):
            delegate?.player(player, adMuted: adInfo)
        case .playerAdUnmuted(let player, let adInfo):
            delegate?.player(player, adUnmuted: adInfo)
        case .playerAdVolumeChanged(let player, let adInfo, let previousVolume):
            delegate?.player(player, adInfo: adInfo, volumeChangedFrom: previousVolume)
        case .playerAdClicked(let player, adInfo: let adInfo):
            delegate?.player(player, adClicked: adInfo)

        // MARK: - PAL events

        case .playerInitializedWithPAL(let nonce):
            delegate?.playerInitializedwithPAL(nonce: nonce)
        case .player(let palError):
            delegate?.player(palError: palError)
        case .playerReportedAdClickPAL(let nonce):
            delegate?.playerReportedAdClickPAL(nonce: nonce)
        case .playerReportedVideoStartPAL(let nonce):
            delegate?.playerReportedVideoStartPAL(nonce: nonce)
        case .playerReportedVideoEndPAL(let nonce):
            delegate?.playerReportedVideoEndPAL(nonce: nonce)

        // MARK: - Link Opener

        case .playerAdWillOpenExternalApplication(let player):
            delegate?.playerAdWillOpenExternalApplication(player: player)
        case .playerAdWillOpenInAppLink(let player):
            delegate?.playerAdWillOpenInAppLink(player: player)
        case .playerAdDidOpenInAppLink(let player):
            delegate?.playerAdDidOpenInAppLink(player: player)
        case .playerAdWillCloseInAppLink(let player):
            delegate?.playerAdWillCloseInAppLink(player: player)
        case .playerAdDidCloseInAppLink(let player):
            delegate?.playerAdDidCloseInAppLink(player: player)
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length
}
