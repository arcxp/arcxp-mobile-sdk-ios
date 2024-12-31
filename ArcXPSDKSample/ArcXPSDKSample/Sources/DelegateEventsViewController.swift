//  Copyright © 2020 The Washington Post. All rights reserved.

import ArcXP

import AVFoundation
import GoogleInteractiveMediaAds
import UIKit

/// A table that displays each `PlayerDelegate` function call as it's
/// called. This is a handy way to confirm that events are being fired as
/// expected.
class DelegateEventsViewController: UITableViewController {

    /// The events that have been fired. Because this is an array, any change
    /// to it triggers an assignment, so `didSet` gets called, and the table
    /// is refreshed.
    var events = [(String, CMTime)]() {
        didSet {
            guard events.count > 0 else {
                return
            }

            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: events.count - 1,
                                                section: 0),
                                  at: .bottom,
                                  animated: true)
        }
    }

    // MARK: - Functions

    /// Remove all events from the table.
    func reset() {
        events = []  // this will force the table to reload
    }

    // MARK: - UIView

    override func viewDidLoad() {
        super.viewDidLoad()

        #if os(tvOS)
        // Remove the top and bottom gradient mask that tvOS adds by default.
        tableView.mask = nil
        #endif
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as? EventCell else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }

        let event = events[indexPath.row]

        cell.label?.text = event.0
        cell.timeLabel?.text = TimeFormatter.timeFormatter.string(from: event.1.seconds)

        return cell
    }

    // MARK: - Private Functions

    private func log(_ message: String, time: CMTime) {
        events.insert((message, time), at: 0)
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        print("ArcXP Video SDK: \(message)")
    }

    private func logAd(_ adInfo: Any?, _ message: String, time: CMTime) {
        var prefix: String

        if let livestreamAd = adInfo as? LivestreamAd {
            prefix = "Livestream ad " + livestreamAd.adId
        } else if let googleAd = adInfo as? IMAAd {
            prefix = "Google IMA ad " + googleAd.adId
        } else {
            prefix = "Ad (unknown type)"
        }

        log("\(prefix) \(message)", time: time)
    }

}

class EventCell: UITableViewCell {

    @IBOutlet weak var timeLabel: UILabel?

    @IBOutlet weak var label: UILabel?

}

extension DelegateEventsViewController: PlayerDelegate {

    // MARK: - Ads

    func player(_ player: AVPlayer, adClicked: Any?) {
        if let adClicked = adClicked {
            log("Ad clicked \(adClicked).", time: player.currentTime())
        }
    }

    func player(_ player: AVPlayer, adBreakEnded adBreak: Any?) {
        if let adBreak = adBreak as? LivestreamAdBreak {
            log("Ad break \(adBreak.adBreakId!) ended", time: player.currentTime())
        }
    }

    func player(_ player: AVPlayer, adBreakStarted adBreak: Any?) {
        if let adBreak = adBreak as? LivestreamAdBreak,
            let adCount = adBreak.ads?.count {
            let duration = adBreak.durationInSeconds ?? 0
            log("\(duration)-second ad break \(adBreak.adBreakId!) started with \(adCount) ads",
                time: player.currentTime())
        } else {
            log("Ad break started", time: player.currentTime())
        }
    }

    func player(_ player: AVPlayer, adCompleted adInfo: Any?) {
        logAd(adInfo, "completed", time: player.currentTime())
    }

    func player(_ player: AVPlayer, adImpression adInfo: Any?) {
        logAd(adInfo, "impression", time: player.currentTime())
    }

    func player(_ player: AVPlayer, adInfo: Any?, adError error: Error?) {
        if let error = error {
            logAd(adInfo, "had an error: \(error.localizedDescription)", time: player.currentTime())
        } else {
            logAd(adInfo, "had some unspecified error.", time: player.currentTime())
        }
    }

    func player(_ player: AVPlayer, adPaused adInfo: Any?) {
        logAd(adInfo, "paused", time: player.currentTime())
    }

    func player(_ player: AVPlayer, adPlayed25Percent adInfo: Any?) {
        logAd(adInfo, "played 25%", time: player.currentTime())
    }

    func player(_ player: AVPlayer, adPlayed50Percent adInfo: Any?) {
        logAd(adInfo, "played 50%", time: player.currentTime())
    }

    func player(_ player: AVPlayer, adPlayed75Percent adInfo: Any?) {
        logAd(adInfo, "played 75%", time: player.currentTime())
    }

    func player(_ player: AVPlayer, adStarted adInfo: Any?) {
        let adDuration: Double?

        if let livestreamAd = adInfo as? LivestreamAd {
            adDuration = livestreamAd.durationInSeconds
        } else if let googleIMAAd = adInfo as? IMAAd {
            adDuration = googleIMAAd.duration
        } else {
            adDuration = nil
        }

        let adDurationString: String

        if let duration = adDuration {
            adDurationString = String(Int(duration))
        } else {
            adDurationString = "unknown"
        }

        logAd(adInfo, "started (\(adDurationString) seconds)", time: player.currentTime())
    }

    func player(_ player: AVPlayer, adResumed adInfo: Any?) {
        logAd(adInfo, "resumed", time: player.currentTime())
    }

    func player(_ player: AVPlayer, adSkipped adInfo: Any?) {
        logAd(adInfo, "skipped", time: player.currentTime())
    }

    func player(_ player: AVPlayer, adTapped adInfo: Any?) {
        logAd(adInfo, "tapped", time: player.currentTime())
    }

    func player(_ player: AVPlayer, adMuted adInfo: Any?) {
        logAd(adInfo, "muted", time: player.currentTime())
    }

    func player(_ player: AVPlayer, adUnmuted adInfo: Any?) {
        logAd(adInfo, "unmuted", time: player.currentTime())
    }

    func player(_ player: AVPlayer, adInfo: Any?, volumeChangedFrom previousVolume: Float?) {
        logAd(adInfo, "volume changed", time: player.currentTime())
    }

    // MARK: - Link Opener

    func playerAdWillOpenExternalApplication(player: AVPlayer) {
        log("Player ad will open external application.", time: player.currentTime())
    }

    func playerAdWillOpenInAppLink(player: AVPlayer) {
        log("Player ad will open in-app link.", time: player.currentTime())
    }

    func playerAdDidOpenInAppLink(player: AVPlayer) {
        log("Player ad did open in-app link.", time: player.currentTime())
    }

    func playerAdWillCloseInAppLink(player: AVPlayer) {
        log("Player ad will close in-app link.", time: player.currentTime())
    }

    func playerAdDidCloseInAppLink(player: AVPlayer) {
        log("Player ad did close in-app link.", time: player.currentTime())
    }

    // MARK: - PAL events

    func playerInitializedwithPAL(nonce: String) {
        log("Player initialized, nonce = \(nonce)", time: CMTime.zero)
    }

    func player(palError: Error?) {
        if let error = palError {
            log("Error: \(error.localizedDescription)", time: CMTime.zero)
        } else {
            log("Some unspecified error.", time: CMTime.zero)
        }
    }

    func playerReportedAdClickPAL(nonce: String?) {
        log("PAL reported Ad tap", time: CMTime.zero)
    }

    func playerReportedVideoStartPAL(nonce: String?) {
        log("PAL reported video start", time: CMTime.zero)
    }

    func playerReportedVideoEndPAL(nonce: String?) {
        log("PAL reported video end", time: CMTime.zero)
    }

    // MARK: - Captioning

    func player(_ player: AVPlayer,
                captionsOn captionType: AVPlayerItem.CaptionType) {
        switch captionType {
        case .embedded(let locale):
            log("Embedded captions on for locale \(locale.identifier)", time: player.currentTime())
        case .clientSide:
            log("Client-side (VTT) captions on", time: player.currentTime())
        case .none:
            return
        @unknown default:
            return
        }
    }

    func playerCaptionsOff(_ player: AVPlayer) {
        log("Captions off", time: player.currentTime())
    }

    // MARK: - Lifecycle

    func playerStatusUnknown(_ player: AVPlayer) {
        log("Player status unknown", time: player.currentTime())
    }

    func playerItemStatusUnknown(_ player: AVPlayer, item: AVPlayerItem) {
        log("Player item status unknown", time: player.currentTime())
    }

    func playerAppeared(_ player: AVPlayer) {
        log("Player appeared", time: player.currentTime())
    }

    func player(_ player: AVPlayer, error: Error?) {
        if let error = error {
            log("Player error: \(error.localizedDescription)", time: player.currentTime())
        } else {
            log("Unspecified player error", time: player.currentTime())
        }
    }

    func player(_ player: AVPlayer, item: AVPlayerItem?, error: Error?) {
        if let error = error {
            log("Player item error: \(error.localizedDescription)", time: player.currentTime())
        } else {
            log("Unspecified player item error", time: player.currentTime())
        }
    }

    // MARK: - Playback Milestones

    func player(_ player: AVPlayer, completed item: AVPlayerItem?) {
        log("Video completed", time: player.currentTime())
    }

    func player(_ player: AVPlayer, played25Percent video: AVPlayerItem?) {
        log("Video is 25% finished", time: player.currentTime())
    }

    func player(_ player: AVPlayer, played50Percent video: AVPlayerItem?) {
        log("Video is 50% finished", time: player.currentTime())
    }

    func player(_ player: AVPlayer, played75Percent video: AVPlayerItem?) {
        log("Video is 75% finished", time: player.currentTime())
    }

    // MARK: - User Interaction

    func playerMuted(_ player: AVPlayer) {
        log("Player muted", time: player.currentTime())
    }

    func playerUnmuted(_ player: AVPlayer) {
        log("Player unmuted", time: player.currentTime())
    }

    func player(_ player: AVPlayer, paused video: AVPlayerItem?) {
        log("Video paused", time: player.currentTime())
    }

    func player(_ player: AVPlayer, resumed item: AVPlayerItem?) {
        log("Video resumed", time: player.currentTime())
    }

    func player(_ player: AVPlayer, skipped item: AVPlayerItem?, to time: CMTime) {
        log("Video skipped to \(time.seconds)", time: player.currentTime())
    }

    func player(_ player: AVPlayer, started video: AVPlayerItem?, byUser: Bool) {
        log("Video started" + (byUser ? " by the user" : " automatically"), time: player.currentTime())
    }

    func playerTapped(_ player: AVPlayer, item: AVPlayerItem?) {
        log("Player tapped", time: player.currentTime())
    }

    func playerBeganFullScreenPresentation(_ player: AVPlayer, item: AVPlayerItem?) {
        log("Player went into fullscreen mode", time: player.currentTime())
    }

    func playerEndedFullScreenPresentation(_ player: AVPlayer, item: AVPlayerItem?) {
        log("Player returned from fullscreen mode", time: player.currentTime())
    }

}

extension DelegateEventsViewController: ArcMediaPlayerViewDelegate {

    func playerViewControlBarDidAppear(_ playerView: ArcMediaPlayerView) {
        log("Control bar appeared", time: playerView.player.currentTime())
    }

    func playerViewControlBarWillAppear(_ playerView: ArcMediaPlayerView) {
        log("Control bar will appear", time: playerView.player.currentTime())
    }

    func playerViewControlBarDidDisappear(_ playerView: ArcMediaPlayerView) {
        log("Control bar disappeared", time: playerView.player.currentTime())
    }

    func playerViewControlBarWillDisappear(_ playerView: ArcMediaPlayerView) {
        log("Control bar will disappear", time: playerView.player.currentTime())
    }

}
