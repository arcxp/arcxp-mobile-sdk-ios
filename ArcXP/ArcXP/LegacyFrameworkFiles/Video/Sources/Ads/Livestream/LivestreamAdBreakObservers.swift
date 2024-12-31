//  Copyright © 2020 The Washington Post. All rights reserved.

import AVFoundation
import UIKit

/// All of the boundary time observers that are registered for a given
/// `LivestreamAdBreak` and the ads it contains. Originally, we simply added
/// boundary time observers for each ad's `trackingEvents` that we were
/// interested in, plus observers for the ad break's own start and end times.
/// Now, however, we could be getting redundant ad break data, and so we need
/// to clean up by removing all the observers for an existing ad break when a
/// new one is fetched from the ad server. This data structure keeps track of
/// them.
class LivestreamAdBreakObservers: NSObject {

    /// The lifecycle boundary observers for the ad break's ads, including the
    /// ad's start, end, and playback milestones.
    var adObservers = [Any]() {
        didSet {
            ArcXPLogger.log("There are now \(adObservers.count) ad observers.")
        }
    }

    /// The ad break whose observers are held in this object.
    var adBreak: LivestreamAdBreak

    /// Keeps track of PAL (Programmatic Access Library) requests.
    weak var palTracker: PALTracker?

    /// The `AVPlayer` to which the boundary observers are added.
    var player: AVPlayer

    // MARK: - Initialization

    /// Set up the ad-tracking and OpenMeasurement-tracking events from
    /// `LivestreamAdBreak` data.
    ///
    /// - Parameters:
    ///   - adBreak: The MediaTailor avails data.
    ///   - player: The `AVPlayer` to which boundary time observers will be
    ///     added to fire the ad events.
    ///   - palTracker: The Programmatic Access Libraries nonce tracker
    init(adBreak: LivestreamAdBreak,
         player: AVPlayer,
         palTracker: PALTracker? = nil) {
        self.adBreak = adBreak
        self.player = player
        self.palTracker = palTracker

        super.init()

        ArcXPLogger.log("Creating a new ad break observers for ad break \(String(describing: adBreak.adBreakId)).")

        if let startTime = adBreak.roundedStartTimeInSeconds {
            adObservers.append(
                player.fire(at: startTime) {
                    MediaEventCenter.shared.sendEvent(.playerAdBreakStarted(player, adBreak: adBreak))
                }
            )
        }

        if let endTime = adBreak.roundedEndTimeInSeconds {
            adObservers.append(
                player.fire(at: endTime) {
                    MediaEventCenter.shared.sendEvent(.playerAdBreakEnded(player, adBreak: adBreak))
                }
            )
        }

        addTrackingEvents()
    }

    /// Remove the time observers for all the ads in the ad break.
    func cancel() {
        adObservers.forEach { (observer) in
            ArcXPLogger.log("AdBreakObservers: Removing observer \(observer)")
            player.removeTimeObserver(observer)
        }

        adObservers.removeAll()
    }

    /// As I was building Video SDK,
    /// I got a `video` with seven `adBreak`s,
    ///
    /// Each `adBreak` had seven `ad`s,
    ///
    /// Each `ad` had seven `trackingEvent`s,
    ///
    /// Each `trackingEvent` had seven `beaconUrl`s:
    ///
    /// `adBreak`s, `ad`s, `trackingEvent`s,  and `beaconUrl`s,
    ///
    /// How many freaking time observers do I have to add to the `AVPlayer`?
    private func addTrackingEvent(_ trackingEvent: LivestreamAd.TrackingEvent,
                                  forAd adInfo: LivestreamAd) -> Any? {
        guard let startTime = trackingEvent.roundedStartTimeInSeconds else {
            return nil
        }

        let eventCenter = MediaEventCenter.shared

        switch trackingEvent.eventType {
        case .complete:
            return player.fire(at: startTime) { [unowned self] in
                ArcXPLogger.logIfNil(self)
                trackingEvent.fire(adInfo, headers: headers)
                eventCenter.sendEvent(.playerAdCompleted(player, adInfo: adInfo))
            }
        case .firstQuartile:
            return player.fire(at: startTime) { [unowned self] in
                ArcXPLogger.logIfNil(self)
                trackingEvent.fire(adInfo, headers: headers)
                eventCenter.sendEvent(.playerAdPlayed25Percent(player, adInfo: adInfo))
            }
        case .impression:
            return player.fire(at: startTime) { [unowned self] in
                ArcXPLogger.logIfNil(self)
                trackingEvent.fire(adInfo, headers: headers)
                eventCenter.sendEvent(.playerAdImpression(player, adInfo: adInfo))
            }
        case .midpoint:
            return player.fire(at: startTime) { [unowned self] in
                ArcXPLogger.logIfNil(self)
                trackingEvent.fire(adInfo, headers: headers)
                eventCenter.sendEvent(.playerAdPlayed50Percent(player, adInfo: adInfo))
            }
        case .start:
            return player.fire(at: startTime) { [unowned self] in
                ArcXPLogger.logIfNil(self)
                trackingEvent.fire(adInfo, headers: headers)
                eventCenter.sendEvent(.playerAdStarted(player, adInfo: adInfo))
            }
        case .thirdQuartile:
            return player.fire(at: startTime) { [unowned self] in
                ArcXPLogger.logIfNil(self)
                trackingEvent.fire(adInfo, headers: headers)
                eventCenter.sendEvent(.playerAdPlayed75Percent(player, adInfo: adInfo))
            }
        default:
            // Ignore it
            return nil
        }
    }

    /// For each ad in the ad break, add boundary time observers that will fire
    /// each of the ad events.
    private func addTrackingEvents() {
        adBreak.ads?.forEach { (adInfo) in
            adInfo.trackingEvents?.forEach { [weak self] (event) in
                ArcXPLogger.logIfNil(self)

                if let observer = self?.addTrackingEvent(event, forAd: adInfo) {
                    self?.adObservers.append(observer)
                }
            }
        }
    }

    /// The header values to pass with each ad event HTTP request.
    private var headers: [String: String] {
        guard let arcVideo = player.currentItem?.asset as? ArcVideo,
              let adSettings = arcVideo.adSettings as? LivestreamAdSettings else {
            return [:]
        }

        return adSettings.livestreamBeaconHeaders
    }

}
