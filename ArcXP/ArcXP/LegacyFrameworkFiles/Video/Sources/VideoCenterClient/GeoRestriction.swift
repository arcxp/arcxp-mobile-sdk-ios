//  Copyright © 2020 The Washington Post. All rights reserved.

import Foundation

/// Video Center JSON response data for a video that's georestricted. Strictly
/// speaking, this format is also used for other kinds of restrictions (perhaps
/// including for copyright infringement or being out of date or too early),
/// but for now, we're only using it for georestrictions.
public struct GeoRestriction: Codable {

    /// The `JSONDecoder` that's configured for `GeoRestriction` data. It
    /// converts keys from `snake_case` to `camelCase`.
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return decoder
    }()

    /// `false` if the video is not allowed in the user's `computedLocation`.
    /// In actual use, this is never `true`, because if a video is allowed,
    /// Video Center will return the video data instead of `GeoRestriction`
    /// data.
    var allow: Bool

    /// The user's location, based on the router that the user's connected to.
    var computedLocation: Location

    /// The type of restriction. Right now, this will always be
    /// `geo-restriction`.
    var type: String

    /// Information about the user's location when they attempted to access a
    /// restricted video. This does not come from, and thus doesn't require,
    /// Location Services to be enabled; instead, it's based on the location of
    /// the router that the user's connected to.
    public struct Location: Codable {

        /// The country code where the video is restricted.
        var country: String

        /// The ZIP code(s) where the video is restricted.
        var zip: String
    }

}
