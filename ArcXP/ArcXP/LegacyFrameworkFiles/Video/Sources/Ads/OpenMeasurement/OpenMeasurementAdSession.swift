//  Copyright © 2021 The Washington Post. All rights reserved.

import AVFoundation
import Foundation
import OMSDK_Washpost

/// Tracks ad impressions and ad events for compliance with the Open
/// Measurement standards. It receives ``MediaEvent``s and calls the
/// corresponding `OMIDWashpostAdEvents` and `OMIDWashpostMediaEvents`
/// functions.
///
/// The OMID library is auto-generated for us and can be found at
/// https://tools.iabtechlab.com/omsdk. This requires a account for a user
/// whose email domain is `washpost.com`. The library has to be downloaded and
/// embedded in our framework binary manually.
class OpenMeasurementAdSession: OMIDWashpostAdSession {

    // MARK: - Public Properties

#if DEBUG

    /// Create an `OpenMeasurementAdSession` that targets the IAB Open
    /// Measurement validation script. THIS MUST NOT BE USED IN PRODUCTION,
    /// because if it is, IAB will fine us!
    static func debugSession(for playerView: UIView? = nil) -> OpenMeasurementAdSession? {
        let scriptUrl = URL(string: "https://s3-us-west-2.amazonaws.com/content.iabtechlab.com/omid-validation-verification-logapi.js")!
        guard let debugResource = OMIDWashpostVerificationScriptResource(url: scriptUrl,
                                                                         vendorKey: "iabtechlab.com-omid",
                                                                         parameters: "iabtechlab-Washpost") else {
            return nil
        }

        do {
            let session = try OpenMeasurementAdSession(vastVerificationScriptResources: [debugResource],
                                                       contentUrl: nil,
                                                       playerView: playerView)

            return session
        } catch {
            ArcXPLogger.log("The OpenMeasurementAdSession couldn't be created: \(error.localizedDescription)")
        }

        return nil
    }

#endif // DEBUG

    /// The `AdDelegate` calls that the ad session implements use these
    /// ad events to notify verification partners when certain events have
    /// occurred, such as ad loading and impressions.
    var omAdEvents: OMIDWashpostAdEvents?

    /// The `AdDelegate` calls that the ad session implements use these to
    /// notify verification partners when playback events have occurred, such
    /// as progress, muting & unmuting, toggling between full-screen and
    /// regular size, etc.
    var omMediaEvents: OMIDWashpostMediaEvents?

    // MARK: - Internal Properties

    /// Save yourself from typing out `OMIDWashpostAdSessionConfiguration`
    /// every time.
    private typealias Config = OMIDWashpostAdSessionConfiguration

    /// Save yourself from typing out `OMIDWashpostAdSessionContext` every
    /// time.
    private typealias Context = OMIDWashpostAdSessionContext

    /// The JavaScript file that's included in the auto-generated OMID
    /// framework. The file is currently extracted from the OMID framework and
    /// placed directly into our framework (because prior to OMID 1.13.15, it
    /// _wasn't_ included in the OMID framework), but we can revisit that in
    /// The Future.™
    private static var omidScriptUrl: URL {
        return ArcXPSDK.bundle.url(forResource: "omsdk-v1", withExtension: "js")!
    }

    /// The contents of the `omidScriptUrl`.
    private static var omidScript: String {
        // swiftlint:disable force_try
        return try! String(contentsOf: omidScriptUrl)
        // swiftlint:enable force_try
    }

    // MARK: - Initialization

    /// Construct the session with one or more
    /// `OMIDWashpostVerificationScriptResource`s.
    ///
    /// - parameter resources: Information that the superclass uses to make
    ///   calls to the ad-tracking server.
    /// - parameter contentUrl: The URL of the article or document that
    ///   contains the ad-enabled video. It may be `nil`.
    /// - parameter playerView: The `UIView` that plays the video. If it
    ///   contains any subviews that aren't part of the video itself (such as
    ///   playback controls, information labels, etc.), these must also be
    ///   registered as friendly obstructions. Failure to do so will impact the
    ///   ad's monetization, because the ad provider (and OpenMeasurement) will
    ///   consider the ad content to be partially blocked by something else.
    init(vastVerificationScriptResources resources: [OMIDWashpostVerificationScriptResource],
         contentUrl: URL?,
         playerView: UIView?) throws {

        // Step 3. Create and configure the ad session.
        // https://interactiveadvertisingbureau.github.io/Open-Measurement-SDKiOS/#3-create-and-configure-the-ad-session
        let sessionContext = try Context(partner: OpenMeasurementPartner.shared,
                                         script: Self.omidScript,
                                         resources: resources,
                                         contentUrl: contentUrl?.absoluteString,
                                         customReferenceIdentifier: nil)
        let sessionConfig = try Config(creativeType: .video,
                                       impressionType: .beginToRender,
                                       impressionOwner: .nativeOwner,
                                       mediaEventsOwner: .nativeOwner,
                                       isolateVerificationScripts: false)
        try super.init(configuration: sessionConfig, adSessionContext: sessionContext)

        // 4. Set the view on which to track viewability.
        // https://interactiveadvertisingbureau.github.io/Open-Measurement-SDKiOS/#4-set-the-view-on-which-to-track-viewability-1
        mainAdView = playerView

        // Register friendly obstructions. But is this necessary? The docs say
        // "all sub-views of the adView will be automatically treated as part
        // of the ad."
        if let obstructions = (playerView as? ArcMediaPlayerView)?.friendlyAdObstructions {
            for obstruction in obstructions {
                obstruction.register(with: self)
            }
        }

        // 5. Create the event publisher instances.
        // https://interactiveadvertisingbureau.github.io/Open-Measurement-SDKiOS/#5-create-the-event-publisher-instances
        omAdEvents = try OMIDWashpostAdEvents(adSession: self)
        omMediaEvents = try OMIDWashpostMediaEvents(adSession: self)

        // 6. Start the session.
        // https://interactiveadvertisingbureau.github.io/Open-Measurement-SDKiOS/#6-start-the-session
        // Media events won't be fired until this has completed.
        start()

        // Steps 7 & 8 are in player(_ player: AVPlayer, adStarted).
    }

    /// When an ad starts,
    ///
    /// * Start listening for  ``MediaEvent``s.
    /// * Fire `OMIDWashpostAdEvents.loaded(with:)` properties for no autoplay
    ///   and for midroll ads.
    /// * Fire `OMIDWashpostAdEvents.impressionOccurred()`.
    /// * Fire `OMIDWashpostMediaEvents.start(withDuration:mediaPlayerDuration:)`.
    private func adStarted(_ player: AVPlayer, adInfo: Any?) {
        MediaEventCenter.shared.addSubscriber(self)

        // 7. Register the ad load event.
        // https://interactiveadvertisingbureau.github.io/Open-Measurement-SDKiOS/#7-register-the-ad-load-event
        let properties = OMIDWashpostVASTProperties(autoPlay: false, position: .midroll)
        try? omAdEvents?.loaded(with: properties)
        ArcXPLogger.log("Fired OMIDWashpostAdEvents.loaded()")

        if let adInfo = adInfo as? LivestreamAd,
           let duration = adInfo.durationInSeconds {
            // 8. Register the impression.
            // https://interactiveadvertisingbureau.github.io/Open-Measurement-SDKiOS/#8-register-the-impression
             try? omAdEvents?.impressionOccurred()
            ArcXPLogger.log("Fired OMIDWashpostAdEvents.impressionOccurred()")

            omMediaEvents?.start(withDuration: CGFloat(duration),
                               mediaPlayerVolume: CGFloat(player.volume))
            ArcXPLogger.log("Fired OMIDWashpostMediaEvents.start()")
        }

        // Step 9 is in the session's implementation of AdDelegate &
        // PlayerDelegate.
    }

    private func adPaused(_ player: AVPlayer, adInfo: Any?) {
        omMediaEvents?.pause()
        adUserInteraction()
        // Step 8 Register the impression.
        // https://interactiveadvertisingbureau.github.io/Open-Measurement-SDKiOS/#8-register-the-impression
        // Bug AM-4552: Update impressions only when ad is paused in non-live videos
        if let currentItem = player.currentItem,
            !currentItem.isLive {
            try? omAdEvents?.impressionOccurred()
            ArcXPLogger.log("Fired OMIDWashpostMediaEvents.impressionOccurred()")
        }
    }

    private func adUserInteraction() {
        omMediaEvents?.adUserInteraction(withType: .click)
        ArcXPLogger.log("Fired OMIDWashpostMediaEvents.adUserInteraction()")
    }

    /// When an ad ends, fire `OMIDWashpostMediaEvents.complete()` and stop
    /// receiving ``MediaEvent``s.
    private func adEnded(_ player: AVPlayer, adInfo: Any?) {
        // 10. Complete the session.
        // https://interactiveadvertisingbureau.github.io/Open-Measurement-SDKiOS/#10-complete-the-session
        ArcXPLogger.log("Fired OMIDWashpostMediaEvents.complete()")
        omMediaEvents?.complete()
        finish() // end the session

        MediaEventCenter.shared.removeSubscriber(self)
    }

}

/// 9. Signal playback progress events.
/// https://interactiveadvertisingbureau.github.io/Open-Measurement-SDKiOS/#9-signal-playback-progress-events
///
/// Step 10 is in adEnded().
extension OpenMeasurementAdSession: MediaEventSubscriber {
// swiftlint: disable cyclomatic_complexity
    /// Receive a variety of `MediaEvent`s by firing corresponding
    /// `OMIDWashpostMediaEvents`s; for example, receiving a
    /// ``MediaEvent/playerAdPlayed25Percent(_:adInfo:)`` fires
    /// `OMIDWashpostMediaEvents.firstQuartile()`.
    func receiveEvent(_ event: MediaEvent) {
        switch event {
        case .playerAdPlayed25Percent:
            ArcXPLogger.log("Fired OMIDWashpostMediaEvents.firstQuartile()")
            omMediaEvents?.firstQuartile()
        case .playerAdPlayed50Percent:
            ArcXPLogger.log("Fired OMIDWashpostMediaEvents.midpoint()")
            omMediaEvents?.midpoint()
        case .playerAdPlayed75Percent:
            ArcXPLogger.log("Fired OMIDWashpostMediaEvents.thirdQuartile()")
            omMediaEvents?.thirdQuartile()
        case .playerAdCompleted(let player, let adInfo):
            adEnded(player, adInfo: adInfo)
        case .playerAdPaused(let player, let adInfo):
            ArcXPLogger.log("Fired OMIDWashpostMediaEvents.pause()")
            adPaused(player, adInfo: adInfo)
        case .playerAdPlaying:
            ArcXPLogger.log("Fired OMIDWashpostMediaEvents.resume()")
            omMediaEvents?.resume()
            adUserInteraction()
        case .playerAdStarted(let player, let adInfo):
            adStarted(player, adInfo: adInfo)
        case .playerAdMuted:
            ArcXPLogger.log("Fired OMIDWashpostMediaEvents.volumeChange(0.0) (muted)")
            omMediaEvents?.volumeChange(to: 0.0)
        case .playerAdUnmuted:
            ArcXPLogger.log("Fired OMIDWashpostMediaEvents.volumeChange(1.0) (unmuted)")
            omMediaEvents?.volumeChange(to: 1.0)
        case .playerAdVolumeChanged:
            // DO NOT send an event to OM. Toggling AVPlayer.isMuted can
            // sometimes also send incremental AVPlayer.volumeChanged
            // notifications, and OM doesn't want to see those. A better
            // solution would be for OM to have separate calls for mute/unmute
            // and volumeChange(), but they don't.
            return
        case .playerItemStarted:
            ArcXPLogger.log("Fired OMIDWashpostMediaEvents.bufferStart()")
            omMediaEvents?.bufferStart()
        case .playerItemCompleted:
            ArcXPLogger.log("Fired OMIDWashpostMediaEvents.bufferFinish()")
            omMediaEvents?.bufferFinish()
        case .playerAdWentFullscreen:
            ArcXPLogger.log("Fired OMIDWashpostMediaEvents.playerStateChanged(.fullscreen)")
            omMediaEvents?.playerStateChange(to: .fullscreen)
        case .playerAdReturnedToNormalSize:
            ArcXPLogger.log("Fired OMIDWashpostMediaEvents.playerStateChanged(.normal)")
            omMediaEvents?.playerStateChange(to: .normal)
        case .playerAdError(_, adInfo: _, error: _):
            MediaEventCenter.shared.removeSubscriber(self)
        default:
            return
        }
    }
// swiftlint: enable cyclomatic_complexity
}

extension LivestreamAd {

    /// Get the concatenation of all the
    /// `OMIDWashpostVerificationScriptResource`s in the `adVerifications`.
    var omidVerificationScriptResources: [OMIDWashpostVerificationScriptResource] {
        return adVerifications?.reduce(into: [OMIDWashpostVerificationScriptResource]()) {
            $0.append(contentsOf: $1.omidVerificationScriptResources)
        } ?? []
    }

}

extension LivestreamAd.AdVerification {

    /// Get an array of the OMID Javascript resources that have been converted
    /// into `OMIDWashpostVerificationScriptResource`s. Executable resource,
    /// and JS resources that don't have a valid URI or whose `apiFramework`
    /// type isn't `omid` are ignored.
    var omidVerificationScriptResources: [OMIDWashpostVerificationScriptResource] {
        guard let jsResources = javascriptResource else {
            return []
        }

        return jsResources
            .filter { $0.apiFramework == "omid" }
            .compactMap { (resourceData) in
                guard let url = URL(string: resourceData.uri) else {
                    return nil
                }

                let params = self.verificationParameters ?? ""
                let resource = OMIDWashpostVerificationScriptResource(url: url,
                                                                      vendorKey: self.vendor,
                                                                      parameters: params)

                return resource
            }
    }

}
