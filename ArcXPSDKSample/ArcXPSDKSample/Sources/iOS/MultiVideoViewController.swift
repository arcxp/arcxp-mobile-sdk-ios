//
//  MultiVideoViewController.swift
//  Sample iOS App
//
//  Created by Mahesh Venkateswarlu on 3/14/23.
//  Copyright © 2023 The Washington Post. All rights reserved.
//

import UIKit
import AVKit
import ArcXP
// swiftlint:disable force_cast trailing_whitespace line_length
class MultiVideoViewController: UIViewController {
    
    @IBOutlet weak var playerPlaceholder: UIView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView?
    
    @IBOutlet weak var adsEnabled: UISwitch!
    
    @IBOutlet weak var selectedMediaID: UILabel!
    
    @IBOutlet weak var orgID: UILabel!
    
    private var arcMediaPlayerView: ArcMediaPlayerView?
    
    private var playerController: PlayerController!
    
    private(set) lazy var mediaIds: [String] = {
        return ["ec4af1c5-adce-4dce-97af-b83b668a2136",
                "0abb4518-1b94-4a0f-9862-b0dd794d457e",
                "f9eb2823-1be6-4b4b-bff0-547ba1ea8a74"]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        orgID.text = "cmg"

        let playerViewController: UIViewController
        
        // Figure out which player controller container we want.
        
        let playerVC = ArcMediaPlayerViewController.loadFromStoryboard()
        playerVC.playerView.delegate = self
        playerController = playerVC.playerController
        playerViewController = playerVC
        arcMediaPlayerView = playerVC.playerView
 
        addChild(playerViewController)
        playerViewController.didMove(toParent: self)  // DON'T FORGET THIS!
        playerPlaceholder.addSubview(playerViewController.view)
        let playerView = playerViewController.view!
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.leadingAnchor.constraint(equalTo: playerPlaceholder.leadingAnchor).isActive = true
        playerView.trailingAnchor.constraint(equalTo: playerPlaceholder.trailingAnchor).isActive = true
        playerView.topAnchor.constraint(equalTo: playerPlaceholder.topAnchor).isActive = true
        playerView.bottomAnchor.constraint(equalTo: playerPlaceholder.bottomAnchor).isActive = true
        
        playerController.delegate = self
        // Do any additional setup after loading the view.
        ArcXP.Services.configure(service: .video(.init(organization: orgID.text ?? "",
                                                       environment: .production,
                                                       useGeorestrictions: nil)))
        AppSettings.organizationName.set(value: orgID.text)
        play(sender: nil)
    }
    
    func log(_ message: String, time: CMTime? = nil) {
        print("ArcXP Video SDK: \(message)")
    }

    @IBAction public func play(sender: UIButton!) {
        let tag = sender == nil ? 0 : sender.tag
        self.spinner?.startAnimating()
        ArcMediaClientManager.client.video(mediaID: mediaIds[tag],
                                           adSettings: nil,
                                           accessToken: "unused") { [unowned self] (videoResult) in
                switch videoResult {
                case .success(let video):
                    self.playerController?.adsEnabled = adsEnabled.isOn
                    if adsEnabled.isOn {
                        if self.adsEnabled.isOn {
                            // Load the ad config file.
                            let adConfigUrl: URL?
                            adConfigUrl = URL(string: "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/single_preroll_skippable&sz=640x480&ciu_szs=300x250%2C728x90&gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&impl=s&correlator=")
                            let adConfig = ArcMediaAdConfig(adConfigUrl: adConfigUrl, adEnabled: true)
                            self.playerController?.configureAds(adConfig)
                            video.adTagUrl = adConfigUrl
                        }
                    }
                    DispatchQueue.main.async {
                        self.selectedMediaID.text = self.mediaIds[tag]
                        self.spinner?.stopAnimating()
                        let playerItem = AVPlayerItem(asset: video)
                        self.playerController?.play(playerItem: playerItem)
                    }
                case .failure(let error):
                    print(error)
                }
        }
    }

}

extension MultiVideoViewController: PlayerDelegate {

    // MARK: - Ads

    func player(_ player: AVPlayer, adClicked: Any?) {
        if let adClicked = adClicked {
            log("Ad clicked \(adClicked)", time: player.currentTime())
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

extension MultiVideoViewController: ArcMediaPlayerViewDelegate {

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
