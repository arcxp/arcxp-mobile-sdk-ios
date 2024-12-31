//  Copyright © 2020 The Washington Post. All rights reserved.

import Foundation

/// The section of a Video Center `findByUuid()` response that contains
/// the URLs for the livestream that has ads embedded into it (the
/// `manifestPath`) and the ad break data that's fetched at regular
/// intervals to prepare for upcoming ads (the `trackingPath`).
struct MediaTailorSession: Codable {

    /// Renames the JSON elements that aren't really full URLs.
    private enum CodingKeys: String, CodingKey {

        /// The name of the `manifestUrl` JSON element, which isn't really a
        /// URL.
        case manifestPath = "manifestUrl"

        /// The name of the `trackingUrl` JSON element, which isn't really a
        /// URL.
        case trackingPath = "trackingUrl"

    }

    /// The AWS session ID, which is the value of the `manifestPath`'s
    /// `aws.sessionId` query item. If the `manifestPath` is malformed, or
    /// doesn't have a sessionId, this will be `nil`.
    var sessionId: String? {
        // Thank goodness URLComponents can work with a partial URL, because
        // this is SO much easier than trying to use a regular expression to
        // extract the sessionId.
        guard let url = URL(string: manifestPath) else {
            return nil
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        return components?.queryItems?.first { $0.name == "aws.sessionId" }?.value
    }

    // MARK: - JSON Properties

    /// The path for the livestream video with embedded ads. This is
    /// added onto the base URL for the livestream service.
    private let manifestPath: String

    /// The path for the livestream ad break data.
    private let trackingPath: String

    // MARK: - Initialization

    /// Construct the session with the paths to the livestream's manifest and
    /// livestream ad break fetch endpoint.
    init(manifestPath: String, trackingPath: String) {
        self.manifestPath = manifestPath
        self.trackingPath = trackingPath
    }

    // MARK: - Functions

    /// Get the full URL of the manifest, relative to a specified
    /// `baseUrl`.
    ///
    /// - returns: The fully-qualified URL, if the path was well-formed.
    func manifestUrl(baseUrl: URL) -> URL? {
        return URL(string: manifestPath, relativeTo: baseUrl)
    }

    /// Get the full URL of the ad break data, relative to a specified
    /// `baseUrl`.
    ///
    /// - returns: The fully-qualified URL, if the path was well-formed.
    func trackingUrl(baseUrl: URL) -> URL? {
        return URL(string: trackingPath, relativeTo: baseUrl)
    }

}
