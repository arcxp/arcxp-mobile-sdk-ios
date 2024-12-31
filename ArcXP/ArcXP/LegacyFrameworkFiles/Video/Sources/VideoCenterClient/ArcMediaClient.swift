//  Copyright © 2020 The Washington Post. All rights reserved.

import AVFoundation
import Foundation

/// The type for media IDs requested from ArcXP Video Center.
public typealias ArcMediaID = String

/// The `Result` type that's passed into an ``ArcVideoResultHandler`` block.
public typealias ArcVideoResult = Result<ArcVideo, Error>

/// The type of block that's passed to an ``ArcMediaClient`` function.
public typealias ArcVideoResultHandler = (ArcVideoResult) -> Void

public typealias ArcLiveEventResult = Result<[LiveEvent], Error>

public typealias ArcLiveEventsResultHandler = (ArcLiveEventResult) -> Void

// COMMENTED For Compiling
/*
/// The ArcXP server environment. For most partners, this will be either
/// ``production`` or ``sandbox``. Some partners don't use separate environments,
/// so they should use ``none`` instead.
public enum ServerEnvironment: String {

    /// For partners that don't need to specify a server environment.
    case none

    /// The production server environment.
    case production = "prod"

    /// The sandbox server environment, usually reserved for testing.
    case sandbox
}
 */

/// Implemented by objects that retrieve ArcXP media content. Two
/// implementations are provided:
///
/// 1. ``ArcMediaRealClient``: The real implementation that fetches videos from
///   the ArcXP servers.
/// 2. ``ArcMediaSampleClient``: A mock implementation that always serves the
///   same sample content. This is perfect for unit tests, but is included in the
///   the main bundle.
public protocol ArcMediaClient {

    /// The ID of the organization that this client fetches videos for.
    var organizationID: String { get }

    /// Get an ``ArcVideo`` object that can be played in a ``PlayerController``.
    ///
    /// - Parameters:
    ///   - mediaID: The unique ID of the video. This is usually extracted
    ///     from the raw article content.
    ///   - adReportParams: A dictionary of settings, such as the device
    ///     information, any custom params to be reported for Media Tailor.
    ///   - accessToken: The token that allows access to the video
    ///     being requested. You will either get this value from your ArcXP setup,
    ///     or you will obtain it by authentication outside of this framework.
    ///   - handleResult: A block that takes a `Result` object that
    ///     will contain the video (if found), or an error if any of the
    ///     parameters are malformed, or if the caller doesn't have access to
    ///     the media. **Note:** The block will be called on the main thread.
    func video(mediaID: ArcMediaID,
               adSettings: AdSettings?,
               accessToken: ArcAccessToken,
               handleResult: @escaping ArcVideoResultHandler)

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
    func virtualChannel(mediaID: ArcMediaID,
                        handleResult: @escaping ArcVideoResultHandler)

    /// Get an ``ArcVideo`` for a video channel asynchronously. A channel is a
    /// bundle of videos that are stitched together to look and act like one
    /// long video. Its``ArcVideo/info`` property will be an array of
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
    func virtualChannel(mediaID: ArcMediaID) async throws -> ArcVideo

    /// Find and return the live events in the organization
    /// - Parameter handleResult:  A block that takes a `Result` object that
    ///     will contain the live events (if found), or any error if any of the
    ///     configuration is malformed **Note:** The block will be called on the main thread.
    @available(iOS, deprecated: 15.0, obsoleted: 16.0)
    func findLiveEvents(handleResult: @escaping ArcLiveEventsResultHandler)

    /// Find and return the live events in the organization
    /// - Returns: List of Live Events
    @available(iOS 15.0.0, *)
    @available(tvOS 15.0.0, *)
    func findLiveEvents() async throws -> [LiveEvent]
}

/// Custom types for ``ArcMediaClient`` errors.
public enum ArcMediaClientError: Error {

    /// The specified URL returned a 400-series error (if it's an HTTP URL), or
    /// the file wasn't found.
    case mediaNotFound(_ url: URL? = nil)

}

/// Holds a static property that points to a singleton ``ArcMediaClient``
/// instance that will be used throughout the app. Callers should call
/// functions on the ``ArcMediaClientManager/client`` instead of managing their
/// own client property, e.g.
///
/// ```
/// let video = try ArcMediaClientManager.client.video(mediaID: "5e42ee2046e0fb00099e96ed",
///                                                    accessToken: "<some-token">) { (videoResult) in
///     ...
/// }
/// ```
public struct ArcMediaClientManager {

    /// The singleton instance of the ``ArcMediaClient`` used throughout the app.
    public static var client: ArcMediaClient = ArcMediaSampleClient()

}
