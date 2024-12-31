//
//  Copyright © 2020 The Washington Post. All rights reserved.
//

import Foundation
import ProgrammaticAccessLibrary

#if os(iOS)
import OMSDK_Washpost
#endif

/// The Programmatic Access Libraries (PAL) are lightweight SDKs
/// that provide discrete access to targeting signals for Google Ad Manager programmatic ads.

/// Tracks PAL ad requests.
class PALTracker: NSObject {

    /// The loader to use for nonce requests.
    let nonceLoader = NonceLoader()

    /// The nonce manager result from the last successful nonce request.
    var nonceManager: NonceManager? {
        didSet {
            if let oldPalGesture = oldValue?.gestureRecognizer {
                playerView?.removeGestureRecognizer(oldPalGesture)
            }

            if let nonceManager = nonceManager {
                playerView?.addGestureRecognizer(nonceManager.gestureRecognizer)
                MediaEventCenter.shared.sendEvent(.playerInitializedWithPAL(nonce: nonceManager.nonce))
                ArcXPLogger.log("Programmatic access nonce: \(nonceManager.nonce)")
            }
        }
    }

    // MARK: - Partner properties

    /// The ID that's assigned to us by the provider.
    let publisherProvidedId = "wapo"

    /// The view in which a video would play.
    weak var playerView: UIView?

    /// Construct the tracker with the view that displays the ad content.
    init(playerView: UIView? = nil) {
        super.init()
        self.playerView = playerView
        nonceLoader.delegate = self
    }

    /// Reports an ad click for the current nonce manager, if not nil.
    func sendAdClick() {
        nonceManager?.sendAdClick()
        MediaEventCenter.shared.sendEvent(.playerReportedAdClickPAL(nonce: nonceManager?.nonce))
    }

    /// Reports the start of playback for the current content session.
    func sendPlaybackStart() {
        nonceManager?.sendPlaybackStart()
        MediaEventCenter.shared.sendEvent(.playerReportedVideoStartPAL(nonce: nonceManager?.nonce))
    }

    /// Reports the end of playback for the current content session.
    func sendPlaybackEnd() {
        nonceManager?.sendPlaybackEnd()
        MediaEventCenter.shared.sendEvent(.playerReportedVideoEndPAL(nonce: nonceManager?.nonce))
    }

    /// Requests a new nonce manager with a request containing arbitrary test values like a (sane) user
    /// might supply. Displays the nonce or error on success. This should be called once per stream.
    func requestNonceManager(videoDescriptionUrl: URL? = nil) {
        let nonceRequest = NonceRequest()
        nonceRequest.continuousPlayback = Flag.on
        nonceRequest.descriptionURL = videoDescriptionUrl
        nonceRequest.isIconsSupported = true
        nonceRequest.playerType = "ArcXP Video Player"
        nonceRequest.playerVersion = ArcXPSDK.version

        if let playerViewSize = playerView?.bounds.size {
            nonceRequest.videoPlayerHeight = UInt(playerViewSize.height)
            nonceRequest.videoPlayerWidth = UInt(playerViewSize.width)
        }

        nonceRequest.willAdAutoPlay = Flag.on
        nonceRequest.willAdPlayMuted = Flag.off
        nonceRequest.ppid = publisherProvidedId
        #if os(iOS)
        let partner = OpenMeasurementPartner.shared
        nonceRequest.omidPartnerName = partner.name
        nonceRequest.omidPartnerVersion = partner.versionString
        nonceRequest.omidVersion = partner.omidScriptVersion
        #endif

        nonceLoader.loadNonceManager(with: nonceRequest)
    }
}

extension PALTracker: NonceLoaderDelegate {

    /// Called when a NonceManager is successfully loaded.
    func nonceLoader(_ nonceLoader: NonceLoader,
                     with request: NonceRequest,
                     didLoad nonceManager: NonceManager) {
        // Capture the created nonce manager and attach its gesture recognizer to the video view.
        self.nonceManager = nonceManager
    }

    /// Called when there was an error loading the NonceManager, or if loading timed out.
    func nonceLoader(_ nonceLoader: NonceLoader,
                     with request: NonceRequest,
                     didFailWith error: Error) {
        MediaEventCenter.shared.sendEvent(.player(palError: error))
        ArcXPLogger.log("Error generating programmatic access nonce",
                   error: error)
    }
}
