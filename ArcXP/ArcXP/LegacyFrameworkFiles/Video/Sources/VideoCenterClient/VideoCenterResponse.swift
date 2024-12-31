//  Copyright © 2020 The Washington Post. All rights reserved.

import Foundation

// swiftlint:disable nesting

/// The JSON data returned by calling the Video Center API with a video UUID.
struct VideoCenterResponse: Codable {

    /// The `JSONDecoder` that's configured for `VideoCenterResponse`s.
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return decoder
    }()

    /// Associated data, including `Advertising` settings.
    var additionalProperties: AdditionalProperties?

    /// The duration of the media. If it's a livestream, this will be `nil`.
    var duration: Int?

    /// All available stream formats and bitrates for this video.
    /// `findBestStream(preferredTypes:maximumBitrate:)` filters these to, well,
    /// find the best stream.
    var streams: [Stream]

    /// Information about client-side (VTT) captions, if any. This will be
    /// non-`nil` only if
    ///
    /// * this is an on-demand video (VOD),
    /// * the video's stream does not have captions embedded into it, and
    /// * it has an associated VTT captioning file.
    var subtitles: SubtitlesResponse?

    /// The first `WEB_VTT` URL in the `subtitles` element, if any.
    var clientSideCaptionUrl: String? {
        return subtitles?.urls?.filter({$0.format == "WEB_VTT"}).first?.url
    }

    /// Find the stream that most closely matches the preferred type and
    /// maximum bitrate. This is called recursively on each element of
    /// `preferredTypes`, in descending order of preference.
    ///
    /// - parameter preferredTypes: The `StreamType`s, sorted in descending
    ///   order of preference. For example, `[.hls, .ts, .mp4]` will first
    ///   try to  find an appropriate `.hls` stream whose bitrate doesn't
    ///   exceed `preferredBitrate`, and if none is found, it does the same
    ///   for `.ts` streams, and so on.
    /// - parameter maximumBitrate: The maximum bitrate that should be
    ///   used. This is inclusive, so if `maximumBitrate` is `1000`, then
    ///   a stream with `1000` will be matched.
    ///
    /// - returns: The stream that best matches one of the `preferredTypes`
    ///   and `maximumBitrate`, or `nil` if none of them matched.
    func findBestStream(preferredTypes types: [StreamType],
                        maximumBitrate: UInt = .max) -> Stream? {
        if streams.count == 1 {
            return streams[0]
        } else if streams.isEmpty || types.isEmpty {
            return nil
        } else {
            let preferredType = types[0]
            return streams
                .filter({$0.streamType == preferredType})
                .filter({$0.bitrate <= maximumBitrate})
                .sorted(by: {$0.bitrate > $1.bitrate})
                .first
                ?? findBestStream(preferredTypes: Array(types.dropFirst()),
                                  maximumBitrate: maximumBitrate)
        }
    }

    /// If the video is a livestream and has LivestreamAds ads configured for it,
    /// the stream's Video Center URL is not used to construct an ``ArcVideo``.
    /// Instead, this is called by the `ArcMediaRealClient` to get the
    /// MediaTailor metadata. This metadata contains two properties: the
    /// video stream URL that goes through MediaTailor, and the URL for polling
    /// for ad breaks.
    ///
    /// - parameter rawStreamUrl: the URL of the Video Center stream. Its path
    /// will be appended to the MediaTailor session URL.
    func mediaTailorUrl(for rawStreamUrl: URL) -> URL? {
        if let adInfo = additionalProperties?.advertising,
            let enableAdInsertion = adInfo.enableAdInsertion,
            enableAdInsertion,
            let mediaTailorBaseUrl = adInfo.adInsertionUrls?.mediaTailorSession {
            var basePath = rawStreamUrl.path

            if mediaTailorBaseUrl.absoluteString.hasSuffix("/") && basePath.hasPrefix("/") {
                basePath = String(basePath.dropFirst())
            }

            return mediaTailorBaseUrl.appendingPathComponent(basePath)
        } else {
            return nil
        }
    }

    /// Video metadata. The only part that we care about is the `Advertising`
    /// data, which tells us about MediaTailor ads for livestreams.
    struct AdditionalProperties: Codable {

        /// MediaTailor advertising data.
        var advertising: Advertising?

    }

    /// LivestreamAds advertising data.
    struct Advertising: Codable {

        /// MediaTailor client-side and server-side reporting URLs.
        var adInsertionUrls: AdInsertionUrls?

        /// `true` if MediaTailor ads should be used.
        var enableAdInsertion: Bool?

    }

    // swiftlint:disable inclusive_language
    /// MediaTailor stream URLs.
    struct AdInsertionUrls: Codable {

        /// All of these keys use snake_case in the JSON, but because we're
        /// using a convertFromSnakeCase key-decoding strategy, they have to
        /// be specified as CamelCase here.
        enum CodingKeys: String, CodingKey {

            /// The server-side ad reporting element name.
            case mediaTailorMaster = "mtMaster"

            /// The client-side ad reporting element name.
            case mediaTailorSession = "mtSession"
        }

        /// The MediaTailor base URL for server-side ad reporting, which is not
        /// currently used by this framework.
        var mediaTailorMaster: URL?

        /// The MediaTailor base URL for client-side ad reporting.
        var mediaTailorSession: URL?

    }
    // swiftlint:enable inclusive_language

    /// Information about subtitle information for this video, if any.
    struct SubtitlesResponse: Codable {

        /// Subtitle information.
        struct SubtitleFormat: Codable {

            /// The type of subtitle. The only one that we use right now is
            /// `WEB_VTT`.
            var format: String

            /// The URL of the associated `.VTT` file.
            var url: String

        }

        /// The various types of subtitles that are available for this video.
        var urls: [SubtitleFormat]?

    }

}

/// Information about a Video Center stream, including its file type and
/// bitrate.
public struct Stream: Codable {

    /// The stream's bitrate.
    public var bitrate: Int

    /// The stream's file type.
    public var streamType: StreamType?

    /// The stream's file type for liveEvent
    public var type: StreamType?

    /// The stream's Video Center URL.
    public var url: String

}
// swiftlint:enable nesting
