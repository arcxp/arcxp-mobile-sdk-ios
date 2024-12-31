//  Copyright © 2021 The Washington Post. All rights reserved.

import AVFoundation

/// Empty default implementations of the delegate functions so that framework
/// users don't have to implement all of them.
public extension PlayerDelegate {

    // MARK: - Captioning

    /// - seeAlso: `PlayerDelegate.player(_:captionsOn:)`
    func player(_ player: AVPlayer,
                captionsOn captionType: AVPlayerItem.CaptionType) { }

    /// This default implementation does nothing.
    func playerCaptionsOff(_ player: AVPlayer) { }

    // MARK: - Player Lifecycle

    /// This default implementation does nothing.
    func player(_ player: AVPlayer,
                currentItemChangedFrom: AVPlayerItem?) { }

    /// This default implementation does nothing.
    func player(_ player: AVPlayer,
                error: Error?) { }

    /// This default implementation does nothing.
    func playerAppeared(_ player: AVPlayer) { }

    /// This default implementation does nothing.
    func playerReady(_ player: AVPlayer) { }

    /// This default implementation does nothing.
    func playerStatusUnknown(_ player: AVPlayer) { }

    // MARK: - AVPlayerItem Lifecycle

    /// This default implementation does nothing.
    func player(_ player: AVPlayer,
                item: AVPlayerItem?,
                error: Error?) { }

    /// This default implementation does nothing.
    func player(_ player: AVPlayer,
                itemReady item: AVPlayerItem?) { }

    /// This default implementation does nothing.
    func player(_ player: AVPlayer,
                itemStatusUnknown item: AVPlayerItem?) { }

    // MARK: - Playback

    /// This default implementation does nothing.
    func player(_ player: AVPlayer,
                completed item: AVPlayerItem?) { }

    /// This default implementation does nothing.
    func player(_ player: AVPlayer,
                played25Percent item: AVPlayerItem?) { }

    /// This default implementation does nothing.
    func player(_ player: AVPlayer,
                played50Percent item: AVPlayerItem?) { }

    /// This default implementation does nothing.
    func player(_ player: AVPlayer,
                played75Percent item: AVPlayerItem?) { }

    /// This default implementation does nothing.
    func player(_ player: AVPlayer,
                item: AVPlayerItem?,
                playedPercent percent: Double) { }

    // MARK: - AVPlayer.isMuted & .volume

    /// This default implementation does nothing.
    func playerMuted(_ player: AVPlayer) { }

    /// This default implementation does nothing.
    func playerUnmuted(_ player: AVPlayer) { }

    /// This default implementation does nothing.
    func player(_ player: AVPlayer,
                volumeChangedFrom previousVolume: Float?) { }

    // MARK: - User Interaction

    /// This default implementation does nothing.
    func player(_ player: AVPlayer,
                paused item: AVPlayerItem?) { }

    /// This default implementation does nothing.
    func player(_ player: AVPlayer,
                resumed item: AVPlayerItem?) { }

    /// This default implementation does nothing.
    func player(_ player: AVPlayer,
                item: AVPlayerItem?,
                skippedTo time: CMTime) { }

    /// This default implementation does nothing.
    func player(_ player: AVPlayer,
                started item: AVPlayerItem?,
                byUser: Bool) { }

    /// This default implementation does nothing.
    func playerTapped(_ player: AVPlayer, item: AVPlayerItem?) { }

    /// This default implementation does nothing.
    func playerBeganFullScreenPresentation(_ player: AVPlayer,
                                           item: AVPlayerItem?) { }

    /// This default implementation does nothing.
    func playerEndedFullScreenPresentation(_ player: AVPlayer,
                                           item: AVPlayerItem?) { }

    // MARK: - Ads

    func player(_ player: AVPlayer,
                adBreakEnded adInfo: Any?) { }

    func player(_ player: AVPlayer,
                adBreakStarted adInfo: Any?) { }

    func player(_ player: AVPlayer,
                adCompleted adInfo: Any?) { }

    func player(_ player: AVPlayer,
                adImpression adInfo: Any?) { }

    func player(_ player: AVPlayer,
                adInfo: Any?,
                adError error: Error?) { }

    func player(_ player: AVPlayer,
                adPaused adInfo: Any?) { }

    func player(_ player: AVPlayer,
                adPlayed25Percent adInfo: Any?) { }

    func player(_ player: AVPlayer,
                adPlayed50Percent adInfo: Any?) { }

    func player(_ player: AVPlayer,
                adPlayed75Percent adInfo: Any?) { }

    func player(_ player: AVPlayer,
                adResumed adInfo: Any?) { }

    func player(_ player: AVPlayer,
                adSkipped adInfo: Any?) { }

    func player(_ player: AVPlayer,
                adStarted adInfo: Any?) { }

    func player(_ player: AVPlayer,
                adTapped adInfo: Any?) { }

    func player(_ player: AVPlayer,
                adMuted adInfo: Any?) { }

    func player(_ player: AVPlayer,
                adUnmuted adInfo: Any?) { }

    func player(_ player: AVPlayer,
                adInfo: Any?,
                volumeChangedFrom previousVolume: Float?) { }

    func player(_ player: AVPlayer, adClicked: Any?) { }

    func playerInitializedwithPAL(nonce: String) { }

    func player(palError: Error?) { }

    func playerReportedAdClickPAL(nonce: String?) { }

    func playerReportedVideoStartPAL(nonce: String?) { }

    func playerReportedVideoEndPAL(nonce: String?) { }

    // MARK: - Link Opener

    func playerAdWillOpenExternalApplication(player: AVPlayer) { }

    func playerAdWillOpenInAppLink(player: AVPlayer) { }

    func playerAdDidOpenInAppLink(player: AVPlayer) { }

    func playerAdWillCloseInAppLink(player: AVPlayer) { }

    func playerAdDidCloseInAppLink(player: AVPlayer) { }
}
