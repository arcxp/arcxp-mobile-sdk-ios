//  Copyright © 2020 The Washington Post. All rights reserved.

// swiftlint:disable file_length

import Foundation

/// The stream file types that are supported by ArcXP Video Center.
public enum StreamType: String, Codable {

    /// A simple animated GIF.
    case gif

    /// An MP4 GIF.
    case gifmp4 = "gif-mp4"

    /// MP4 animated content.
    case mp4

    /// Apple's HTTP Live Streaming protocol.
    case hls

    /// Another form of HLS.
    case transportStreams = "ts"
}

// swiftlint:disable type_body_length

/// The `ArcMediaClient` that fetches videos from the ArcXP Video API.
class ArcMediaRealClient: NSObject, ArcMediaClient {

    /// URL builder for the Video Center API endpoints.
    enum Endpoint {

        /// Regular streaming or on-demand (VOD) videos. If
        /// ``serverEnvironment`` is `nil`, then the legacy URL format will be
        /// used.
        case video(mediaId: String, orgId: String, serverEnvironment: ServerEnvironment)

        /// Virtual channels.
        case virtualChannel(mediaId: String, orgId: String, serverEnvironment: ServerEnvironment)

        /// Live Events
        case liveEvents(orgId: String, serverEnvironment: ServerEnvironment)

        /// The endpoint's URL, with the associated data filled in as necessary.
        var url: URL? {
            let urlString: String
            switch self {
            case .video(let mediaId, let orgId, let serverEnvironment):
                if (orgId as NSString).hasPrefix("staging") {
                    // staging org doesn't go through Akamai as of 07/10
                    urlString = "https://\(orgId)-\(serverEnvironment.rawValue)-cdn.video-api.arcpublishing.com/api/v1/ansvideos/findByUuid?uuid=\(mediaId)"
                } else {
                    // Akamai endpoint
                    urlString = "https://\(orgId)-config-\(serverEnvironment.rawValue).api.arc-cdn.net/video/v1/ansvideos/findByUuid?uuid=\(mediaId)"
                }

            case .virtualChannel(let mediaId, let orgId, let serverEnvironment):
                urlString = "https://\(orgId)-\(serverEnvironment.rawValue)-vcx.video-api.arcpublishing.com/v1/virtual-channels/\(mediaId)"

            case .liveEvents(let orgId, let serverEnvironment):
                urlString = "https://\(orgId)-\(serverEnvironment.rawValue).video-api.arcpublishing.com/api/v1/generic/findLive"
            }
            return URL(string: urlString)
        }
    }

    /// Custom types for errors that can be thrown by the `ArcMediaRealClient`.
    public enum ClientError: Error, LocalizedError {

        /// The requested video is blocked in the user's geographical region.
        case geoRestricted(location: GeoRestriction.Location? = nil)

        /// The server response didn't have an error, but the data that was
        /// returned didn't match what the request expected.
        case malformedResponse(data: Data? = nil)

        /// The server didn't return any video results.
        case noMatchingResultsFound

        /// The server returned a video, but none of its streams met the
        /// specified criteria.
        case noMatchingStreamsFound(streamTypes: [StreamType],
                                    maximumBitrate: UInt)

        /// A user-friendly description of the error.
        public var errorDescription: String? {
            switch self {
            case .geoRestricted(let location):
                if let location = location {
                    return "The video isn't available in your location " +
                        "(\(location.country), ZIP code(s) \(location.zip))."
                } else {
                    return "The video isn't available in your location."
                }
            case .malformedResponse:
                return "The server's response wasn't in the expected format."
            case .noMatchingResultsFound:
                return "The video couldn't be found."
            case .noMatchingStreamsFound(let streamTypes, let maximumBitrate):
                let streamTypesString = streamTypes.map { $0.rawValue }.joined(separator: ", ")
                return "The video was found, but not in the expected types " +
                    "(\(streamTypesString)) or with a bitrate lower than " +
                    "\(maximumBitrate) bps."
            }
        }

    }

    // MARK: - Public Properties

    /// The highest bitrate that a stream should have. The default is
    /// `UInt.max`. If ArcXP Video Center has multiple bitrates available for a
    /// given stream, the highest bitrate among the ``preferredStreamTypes`` will
    /// will be used. Set this to a lower value if the device's connection is
    /// weak.
    ///
    /// - seeAlso: `Video.findBestStream(preferredTypes:maximumBitrate:)`
    open var maximumBitrate: UInt = .max

    /// Parameters used for livestream ads.
    public var livestreamAdSettings: LivestreamAdSettings?

    /// The ArcXP ID for the organization. The default is an empty string, which
    /// will (intentionally) cause a malformed endpoint URL.
    public private(set) var organizationID: String = ""

    /// The stream types, in descending order of preference. Video data is
    /// returned from the server with a list of available stream, and these
    /// streams' types and bitrates are checked to find the highest-quality
    /// match.
    ///
    /// - see: `VideoCenterResponse.findBestStream(preferredTypes:maximumBitrate:)`
    open var preferredStreamTypes: [StreamType] = [.hls, .transportStreams, .mp4, .gif, .gifmp4]

    /// The endpoint's server environment.
    ///
    /// Possible choices are
    /// * ``ServerEnvironment/production``
    /// * ``ServerEnvironment/sandbox``
    /// * ``ServerEnvironment/none``.
    public private(set) var serverEnvironment: ServerEnvironment = .production

    // MARK: - ArcMediaClient

    /// `true` if livestream ads should be enabled for livestream videos.
    /// Pre-roll and post-roll ads, like Google IMA ads, are not affected by
    /// this setting.
    open var enableLivestreamAds: Bool = true

    // MARK: - Initialization

    /// Create a Video Center client for a specific organization.
    ///
    /// - parameter organizationID: The ArcXP ID of your organization. This will
    ///   be part of the Video Center API endpoint.
    /// - parameter serverEnvironment: Usually ``ServerEnvironment/production``
    ///   or `sandbox`, but legacy partners that don't use a server environment
    ///   should pass in `.none`.
    /// - parameter enableLivestreamAds: `true` if midroll livestream ads
    ///   should be used. The default is `true`. **Note that this does not
    ///   affect preroll ads, if any.**
    public init(organizationID: String,
                serverEnvironment: ServerEnvironment = .production,
                enableLivestreamAds: Bool = true) {
        self.organizationID = organizationID
        self.serverEnvironment = serverEnvironment
        self.enableLivestreamAds = enableLivestreamAds
        super.init()
    }

    // MARK: - ArcMediaClient Functions

    /// - parameter mediaID: the media's UUID.
    /// - parameter adSettings: Settings for this video's ads. This is
    ///   typically an instance of `LivestreamAdSettings`.
    /// - parameter accessToken: **Currently ignored.** This will eventually be
    ///   a key that allows the caller to access the content.
    /// - parameter handleResult: An `ArcVideoResultHandler` block that takes
    ///   an `ArcVideoResult` (an alias for `Result<ArcVideo, Error>`) and
    ///   returns nothing.
    open func video(mediaID: ArcMediaID,
                    adSettings: AdSettings?,
                    accessToken: ArcAccessToken,
                    handleResult: @escaping ArcVideoResultHandler) {
        livestreamAdSettings = adSettings as? LivestreamAdSettings

        do {
            let url = try constructVideoUrl(orgName: organizationID,
                                            serverEnvironment: serverEnvironment,
                                            mediaId: mediaID)
            let request = URLRequest(endpoint: url, httpMethod: "GET")
            video(request, handleResult: handleResult)
        } catch {
            handleResult(.failure(error))
            return
        }
    }

    /// Get an ``ArcVideo`` for a video channel. A channel is a bundle of
    /// videos that are stitched together to look and act like one long video.
    /// Its``ArcVideo/info`` property will be an array of
    /// ``VirtualChannel/Program``s that provide information about each clip in
    /// the channel.
    ///
    /// - Parameters:
    ///   - mediaID: The unique ID of the video.
    ///   - handleResult: A block that takes a `Result` object that
    ///     will contain the video (if found), or an error if any of the
    ///     parameters are malformed, or if the caller doesn't have access to the
    ///     media. **Note:** The block will be called on the main thread.
    open func virtualChannel(mediaID: ArcMediaID,
                             handleResult: @escaping ArcVideoResultHandler) {
        do {
            let url = try constructVirtualChannelUrl(mediaId: mediaID,
                                                     serverEnvironment: serverEnvironment,
                                                     orgName: organizationID)
            let request = URLRequest(endpoint: url, httpMethod: "GET")
            request.callAndExpectCodable { (result: Result<VirtualChannel, Error>) in
                switch result {
                case .success(let virtualChannel):
                    let video = ArcVideo(url: virtualChannel.url)
                    video.info = virtualChannel.programs
                    handleResult(.success(video))
                case .failure(let error):
                    handleResult(.failure(error))
                }
            }
        } catch {
            handleResult(.failure(error))
        }
    }

    /// Get an ``ArcVideo`` for a video channel asynchronously. A channel is a
    /// bundle of videos that are stitched together to look and act like one
    /// long video. Its ``ArcVideo/info`` property will be an array of
    /// ``VirtualChannel/Program``s that provide information about each clip in
    /// the channel.
    ///
    /// - parameter mediaID: The unique ID of the video.
    ///
    /// - returns: An ``ArcVideo`` object that plays the virtual channel. Its
    ///   ``ArcVideo/info`` property will be an array of
    ///   ``VirtualChannel/Program``s that provide information about each clip
    ///   in the channel.
    ///
    /// - throws: If the `mediaID` is malformed, if the channel doesn't exist,
    ///   or if the caller doesn't have access to it.
    @available(iOS 15.0.0, *)
    @available(tvOS 15.0.0, *)
    open func virtualChannel(mediaID: ArcMediaID) async throws -> ArcVideo {
        let url = try constructVirtualChannelUrl(mediaId: mediaID,
                                                 serverEnvironment: serverEnvironment,
                                                 orgName: organizationID)
        let request = URLRequest(endpoint: url, httpMethod: "GET")
        let (data, _) = try await URLSession.shared.data(for: request)
        let virtualChannel = try JSONDecoder().decode(VirtualChannel.self, from: data)
        let video = ArcVideo(url: virtualChannel.url)
        video.info = virtualChannel.programs

        return video
    }

    /// Fetch a video from the georestriction-checking endpoint. Unlike the
    /// non-georestricted endpoint, this can return two different _successful_
    /// response types: an array of videos (if they're not georestricted for
    /// the user), or information about the restriction. A better approach
    /// would be for a restricted video to return a non-HTTP 200 response code,
    /// and put the georestriction information in the error, but that's not
    /// under our control.
    ///
    /// - parameter request: The Video Center request.
    /// - parameter handleResult: The block that's executed when the response
    ///   or an error is received.
    private func video(_ request: URLRequest,
                       handleResult: @escaping ArcVideoResultHandler) {
        request.callAndExpectData { (result) in
            switch result {
            case .success(let data):
                guard let data = data else {
                    handleResult(.failure(ClientError.malformedResponse(data: nil)))

                    return
                }

                if let response = try? VideoCenterResponse.decoder.decode([VideoCenterResponse].self,
                                                                          from: data) {
                    // The video was found, and isn't georestricted.
                    self.handleSuccessfulVideoResponse(response, handleResult: handleResult)
                } else if let restrictionInfo = try? GeoRestriction.decoder.decode(GeoRestriction.self,
                                                                                   from: data),
                          restrictionInfo.type == "geo-restriction",
                          restrictionInfo.allow == false {
                    // The video was found, but it's georestricted.
                    let location = restrictionInfo.computedLocation
                    handleResult(.failure(ClientError.geoRestricted(location: location)))
                } else {
                    // The video couldn't be found. For some reason, the
                    // georestrictions API doesn't return a normal 404 when a
                    // UUID can't be found.
                    handleResult(.failure(ClientError.noMatchingResultsFound))
                }
            case .failure(let error):
                handleResult(.failure(error))
            }
        }
    }

    /// Encode the `livestreamAdSettings.adParams` as `Data`.
    private func livestreamAdRequestBody() throws -> Data? {
        if let params = livestreamAdSettings?.adParams {
            return try? JSONEncoder().encode(params)
        } else {
            return nil
        }
    }

    /// Find and return the live events in the organization
    /// - Parameter handleResult:  A block that takes a `Result` object that
    ///     will contain the live events (if found), or any error if any of the
    ///     configuration is malformed **Note:** The block will be called on the main thread.
    @available(iOS, deprecated: 15.0, obsoleted: 16.0)
    public func findLiveEvents(handleResult: @escaping ArcLiveEventsResultHandler) {
        do {
            let url = try getLiveEventsUrl(serverEnvironment: serverEnvironment, orgName: organizationID)
            let request = URLRequest(endpoint: url, httpMethod: "GET")
            request.callAndExpectCodable { (result: ArcLiveEventResult) in
                switch result {
                case .success(let liveEvents):
                    handleResult(.success(liveEvents))
                case .failure(let error):
                    handleResult(.failure(error))
                }
            }
        } catch {
            handleResult(.failure(error))
        }
    }

    /// Find and return the live events in the organization
    /// - Returns: List of Live Events
    @available(iOS 15.0.0, *)
    @available(tvOS 15.0.0, *)
    public func findLiveEvents() async throws -> [LiveEvent] {
        let url = try getLiveEventsUrl(serverEnvironment: serverEnvironment, orgName: organizationID)
        let request = URLRequest(endpoint: url, httpMethod: "GET")
        let (data, _) = try await URLSession.shared.data(for: request)
        let liveEvents = try JSONDecoder().decode([LiveEvent].self, from: data)
        return liveEvents
    }

    // MARK: - Internal Functions

    // swiftlint:disable function_body_length

    /// If Video Center responds with an array of `VideoCenterResponse`
    /// objects, use the first one to create an ``ArcVideo`` object and pass it
    /// to the `handleResult` block.
    ///
    /// * If the first result is a livestream, make a `POST` request for the
    ///   stream's ad metadata. This is the stream's URL, resolved against the
    ///   MediaTailor ad server's session base URL. This response will contain
    ///   two URLs:
    ///   1. the MediaTailor livestream URL proper
    ///   2. the URL for periodically requesting ad break information.
    /// * If the result is a video on demand (VOD), and it has a non-`nil`
    ///   `clientSideCaptionUrl`, set that URL on the ``ArcVideo`` so that it can
    ///   load client-side (VTT) captions when it plays.
    ///
    /// - parameter videos: The Video Center response. Only the first element
    ///   is turned into an ``ArcVideo`` and passed to the `handleResult`
    ///   handler.
    /// - parameter handleResult: The block to invoke with an ``ArcVideo`` that
    ///   can be played, or an error if no video was found with the media ID
    ///   that was passed to
    ///   `video(mediaID:adSettings:accessToken:handleResult:)`.
    private func handleSuccessfulVideoResponse(_ videos: [VideoCenterResponse],
                                               handleResult: @escaping ArcVideoResultHandler) {
        // 1. Were any videos returned? If so, get the first one in the list
        //    and ignore the others.
        guard let videoData = videos.first else {
            handleResult(.failure(ClientError.noMatchingResultsFound))

            return
        }

        // 2. Does the first video have a stream that's within the preferred
        //    limits?
        guard let videoStream = videoData.findBestStream(preferredTypes: preferredStreamTypes,
                                                         maximumBitrate: maximumBitrate),
              let videoUrl = URL(string: videoStream.url) else {
            let error = ClientError.noMatchingStreamsFound(streamTypes: preferredStreamTypes,
                                                           maximumBitrate: maximumBitrate)
            handleResult(.failure(error))

            return
        }

        // 3. Is it a livestream, and do we want to show ads?
        guard enableLivestreamAds == true,
           let livestreamUrl = videoData.mediaTailorUrl(for: videoUrl) else {
            // Show the video without midroll ads.
            let video: ArcVideo

            // 3a. If it's an on-demand (i.e. not livestream) video, check
            //     whether it has client-side (VTT) captions.
            if let captionUrl = videoData.clientSideCaptionUrl {
                video = ArcVideo(streamUrl: videoUrl,
                                 clientSideCaptionsUrl: URL(string: captionUrl))
            } else {
                video = ArcVideo(url: videoUrl)
            }

            handleResult(.success(video))

            return
        }

        let body: Data?

        do {
            body = try livestreamAdRequestBody()
        } catch {
            handleResult(.failure(error))
            return
        }

        let request = URLRequest(endpoint: livestreamUrl,
                                 httpMethod: "POST",
                                 body: body,
                                 headers: livestreamAdSettings?.livestreamHTTPHeaders)
        request.callAndExpectCodable { [self] (result: Result<MediaTailorSession, Error>) in
            ArcXPLogger.logIfNil(self)
            if case Result.success(let session) = result {
                let mediaTailorBaseUrl = livestreamUrl.deletingPathExtension()

                if let streamUrl = session.manifestUrl(baseUrl: mediaTailorBaseUrl),
                   let trackingUrl = session.trackingUrl(baseUrl: mediaTailorBaseUrl) {
                    self.livestreamAdSettings?.trackingUrl = trackingUrl
                    self.livestreamAdSettings?.sessionId = session.sessionId

                    if let mediaTailorAdsParams = livestreamAdSettings?.adParams?.adsParams {
                        self.livestreamAdSettings?.livestreamBeaconHeaders = mediaTailorAdsParams
                    }

                    let video = ArcVideo(streamUrl: streamUrl,
                                         adSettings: self.livestreamAdSettings)
                    handleResult(.success(video))

                    return
                }
            }

            // Fall back to the version of the video without
            // livestream ads if either the URL request failed,
            // or the request didn't contain valid stream and
            // tracking URLs.
            let video = ArcVideo(url: videoUrl)
            handleResult(.success(video))
        }
    }

    // swiftlint:enable function_body_length

    /// Get the Video Center URL for the media, depending on whether
    /// georestrictions are being enforced. Why they don't use the same domain
    /// is beyond me. Not only that, but
    /// `videoWithGeoRestrictions(_:handleResult:)` and
    /// `videoWithoutGeoRestrictions(_:handleResult:)` don't return the same
    /// JSON response types!
    ///
    /// - parameter orgName: The name or abbreviation of the organization.
    private func constructVideoUrl(orgName: String,
                                   serverEnvironment: ServerEnvironment,
                                   mediaId: ArcMediaID) throws -> URL {
        let url: URL? = Endpoint.video(mediaId: mediaId,
                                      orgId: orgName,
                                      serverEnvironment: serverEnvironment).url
        guard let url = url else {
            throw URLRequestError.malformedEndpoint(urlString: "invalid")
        }
        return url
    }

    /// Create the API URL with the specified media ID.
    private func constructVirtualChannelUrl(mediaId: ArcMediaID,
                                            serverEnvironment: ServerEnvironment,
                                            orgName: String) throws -> URL {
        let virtualChannel = Endpoint.virtualChannel(mediaId: mediaId,
                                                     orgId: orgName,
                                                     serverEnvironment: serverEnvironment)
        guard let url = virtualChannel.url else {
            throw URLRequestError.malformedEndpoint(urlString: mediaId)
        }
        return url
    }

    /// Get the API url for live Events
    private func getLiveEventsUrl(serverEnvironment: ServerEnvironment,
                                  orgName: String) throws -> URL {
        let liveEvents = Endpoint.liveEvents(orgId: orgName, serverEnvironment: serverEnvironment)

        guard let url = liveEvents.url else {
            throw URLRequestError.malformedEndpoint(urlString: "Find_Live_Events")
        }
        return url
    }
}

// swiftlint:enable file_length type_body_length
