//  Copyright © 2020 The Washington Post. All rights reserved.

import AVFoundation
import Foundation

/// Implemented by items that have `startTimeInSeconds` and `durationInSeconds`
/// properties.
protocol TimedElement {

    /// The length of the `Codable`.
    var durationInSeconds: Double? { get set }

    /// The start time of the `Codable`, relative to the start time of the
    /// stream that it's playing in.
    var startTimeInSeconds: Double? { get set }
}

extension TimedElement {

    /// The end time of the element, calculated from the `startTimeInSeconds`
    /// and `durationInSeconds`.
    var endTimeInSeconds: Double? {
        guard let start = startTimeInSeconds, let duration = durationInSeconds else {
            return nil
        }

        return start.advanced(by: duration)
    }

    /// The end time, rounded up.
    var roundedEndTimeInSeconds: Double? {
        return endTimeInSeconds?.rounded(.up)
    }

    /// The start time, rounded down.
    var roundedStartTimeInSeconds: Double? {
        return startTimeInSeconds?.rounded(.down)
    }

}

// swiftlint:disable nesting
/// Information about ads that will be played within a certain timeframe.
public struct LivestreamAdBreak: Codable, Hashable, TimedElement {

    /// Custom mappings of JSON elements to property names.
    private enum CodingKeys: String, CodingKey {

        case ads
        /// The `availId`.
        case adBreakId = "availId"
        case durationInSeconds
        case startTimeInSeconds
    }

    // MARK: - Public Proeprties

    /// The ads in this ad break.
    public internal(set) var ads: [LivestreamAd]?

    /// The unique ID of the ad break. This is used to calculate changes
    /// in each period fetch of the ad data.
    public internal(set) var adBreakId: String?

    /// The total length of the ad break.
    public internal(set) var durationInSeconds: Double?

    /// The start time of the break, relative to the stream's beginning.
    public internal(set) var startTimeInSeconds: Double?

    // MARK: - Hashable Functions

    /// Calculate a unique-ish hash value of the ad break by using its
    /// ``adBreakId``, ``startTimeInSeconds``, and ``durationInSeconds``.
    public func hash(into hasher: inout Hasher) {
        let startTimeInt = Int(startTimeInSeconds ?? 0.0)
        let durationInt = Int(durationInSeconds ?? 0.0)

        hasher.combine(adBreakId)
        hasher.combine(startTimeInt)
        hasher.combine(durationInt)
    }

    /// The top-level JSON response from fetching ad break data.
    struct Response: Codable {

        /// Custom mappings of JSON elements to property names.
        private enum CodingKeys: String, CodingKey {

            /// We're trying to move away from the "avails" and "MediaTailor"
            /// terminology, so call `avails` `adBreaks` instead.
            case adBreaks = "avails"

        }

        /// The list of ad breaks.
        var adBreaks: [LivestreamAdBreak]

    }

}
// swiftlint:enable nesting

/// Information about a single advertisement. In addition to the ad's
/// ID and duration, it includes a list of `TrackingEvent`s that are
/// beacons to be fired when certain ad-related events take place, such
/// as starting, stopping, clickthrough, pause, etc.
public struct LivestreamAd: Codable, Hashable, TimedElement {

    // MARK: - Public Properties

    /// The ad's unique identifier within this stream.
    public var adId: String

    /// Configurations for third-party ad verification & auditing tools.
    var adVerifications: [AdVerification]?

    /// The legnth of the ad.
    public var durationInSeconds: Double?

    /// Rich media data that's associated with this ad. These are
    /// not used by the video framework itself, but they're passed back to
    /// the framework's caller in the various ad-related ``MediaEvent``s.
    public var mediaFiles: MediaFiles?

    /// The start time of the ad, relative to the stream's beginning.
    public var startTimeInSeconds: Double?

    // MARK: - Internal Properties

    /// Blocks of data that are called at key playback points in the
    /// ad, when the ad's lifecycle changes, or when the user interacts
    /// with the ad. If these aren't fired, then the customer doesn't
    /// get paid!
    var trackingEvents: [TrackingEvent]?

    /// Get the first `TrackingEvent` of the specified type.
    func trackingEvent(ofType type: EventType) -> TrackingEvent? {
        return trackingEvents?.first { $0.eventType == type }
    }

    // MARK: - Hashable Functions

    /// Use the ``adId`` to calculate a unique-ish hash value.
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(adId)
    }

// swiftlint: disable nesting
    /// Configuration for third-party ad verification tools that Open
    /// Measurement uses to report ad metrics. There are two types: JavaScript
    /// resources and executable resources. Executable ones are ignored by our
    /// implementation. JavaScript ones are converted into
    /// `OMIDWashpostVerificationScriptResource`s, and these, in turn, are used
    /// to configure an `OpenMeasurementAdSession`.
    struct AdVerification: Codable, Equatable {

        /// The Javascript verification scripts. All Javascript resources whose `apiFramework` is
        /// `omid` will be converted to `OMIDWashpostVerificationScriptResource`s and
        /// passed to the `OpenMeasurementAdSession`.
        var javascriptResource: [JavascriptResource]?

        /// The vendor ID. This becomes the
        /// `OMIDWashpostVerificationScriptResource.vendorKey`.
        var vendor: String

        /// Additional parameters that are set verbatim as the
        /// `OMIDWashpostVerificationScriptResource.parameters`.
        var verificationParameters: String?

        /// Data about an ad verification JavaScript file.
        struct JavascriptResource: Codable, Equatable {

            /// The type of verification script. The only value that I know of
            /// is `omid`, so other values should cause this script resource to
            /// be ignored.
            var apiFramework: String

            /// The `OMIDWashpostVerificationScriptResource.URL`.
            var uri: String

        }

    }
// swiftlint: enable nesting
    /// Information about media that's associated with this ad. This is
    /// generally content that can be displayed alongside the ad video
    /// itself. The framework itself does nothing with this information; instead,
    /// it's passed back with the ad data in the callbacks.
    public struct MediaFile: Codable, Hashable {

        /// The media's API type, such as `VPAID`.
        public var apiFramework: String?

        /// How the media is delivered. Possible types include `streaming` and
        /// `progressive`.
        public var delivery: String

        /// The file URL.
        public var mediaFileUri: URL

        /// The media's height.
        public var height: Int

        /// The media's MIME type, such as `video/mp4` or `video/webm`.
        public var mediaType: String

        /// Whether the app can change the media's scale.
        public var scalable: Bool

        /// Whether the app should maintain the media's original aspect ratio
        /// when resizing.
        public var maintainAspectRatio: Bool

        /// The media's width.
        public var width: Int

    }

    /// Media files associated with the ad. The framework itself does nothing
    /// with this information; instead, it's passed back with the ad data
    /// in the callbacks.
    public struct MediaFiles: Codable, Hashable, TimedElement {

        /// The length of the media.
        public var durationInSeconds: Double?

        /// The media files.
        public var mediaFilesList: [MediaFile]

        /// A URL for a mezzanine media file, whatever that is.
        public var mezzanine: String?

        /// The time at which this media starts playing, relative to the start
        /// time of the video.
        public var startTimeInSeconds: Double?

        /// The events that should be fired.
        var trackingEvents: [TrackingEvent]?

    }

    /// An ad-related event that can be `fire(_)`d when the event occurs,
    /// such as pausing, completion, skipping, etc. Firing a tracking event
    /// calls the tracking URLs that the ad server uses to track user
    /// engagement.
    struct TrackingEvent: Codable, Hashable, TimedElement {

        /// The URLs to call when the event is `fire()`d.
        var beaconUrls: [String]

        /// The length of the event. Most of these are simply `0.0` because
        /// they're one-time occurrences.
        var durationInSeconds: Double?

        /// The ID of the tracking event.
        var eventId: String

        /// The type of event.
        var eventType: EventType

        /// The start time of the event.
        var startTimeInSeconds: Double?

        /// Call each of the `beaconUrls` and print out their success or
        /// failure status to the console.
        func fire(_ adInfo: LivestreamAd,
                  headers: [String: String] = [:]) {
            for urlString in beaconUrls {
                // Don't check the result's HTTP status. The calls seem to
                // be returning a 1x1 pixel tracking GIF and setting a
                // cookie. And if the URL is malformed, ignore it.
                URL(string: urlString)?.callAndExpectVoid(headers: headers) { _ in }
            }
        }

    }

    /// Tracking event types .
    enum EventType: String, Codable {

        // MARK: Ignored types

        /// Livestream ads don't have invitations.
        case acceptInvitation

        /// Livestream ads don't have invitations.
        case acceptInvitationLinear

        /// Livestream ads can't be clicked.
        case clickThrough

        /// Livestream ads don't track clicks.
        case clickTracking

        /// Livestream ads can't be closed.
        case close

        /// Livestream ads can't be closed.
        case closeLinear

        /// Livestream ads can't be collapsed.
        case collapse

        /// Livestream ads' creative views aren't displayed by the SDK.
        case creativeView

        /// Livestream ads' progress is tracked at 25% intervals.
        case progress

        /// Livestream ads can't be skipped.
        case skip

        // MARK: Playback error

        /// There was an error playing the ad.
        case error

        // MARK: Fullscreen mode

        /// The player returned to its normal size while the ad was playing.
        case exitFullscreen

        /// The player went into fullscreen mode while the ad was playing.
        case fullscreen

        // MARK: Playback progress

        /// The ad was viewed. This is typically fired at the _beginning_ of
        /// the ad, not the end, at least according to Open Measurement's
        /// instructions.
        case impression

        /// 25% of the ad has played.
        case firstQuartile

        /// Half of the ad has played.
        case midpoint

        /// 75% of the ad has played.
        case thirdQuartile

        /// The ad has finished playing.
        case complete

        // MARK: Muting

        /// The ad was muted.
        case mute

        /// The ad was unmuted.
        case unmute

        // MARK: Play/Pause

        /// The ad was paused.
        case pause

        /// The ad was resumed.
        case resume

        /// The ad was rewound (to the beginning?). In practice, we won't fire
        /// this because we don't allow livestreams to be rewound.
        case rewind

        /// The ad was started.
        case start

    }

}
