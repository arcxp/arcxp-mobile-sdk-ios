//  Copyright © 2020 The Washington Post. All rights reserved.

import Foundation

/// Settings for livestream ad requests.
///
/// 1. `adParams`: The JSON-encodable `adsParams` data to send in the _body_
///    of a request for a livestream. The `adParams`' `adsParams` dictionary
///    should contain entries outlined in the [MediaTailor
///    documentation](https://docs.aws.amazon.com/mediatailor/latest/ug/variables.html).
/// 2. `beaconHeaders`: HTTP headers to send with beacon requests to the ad
///     server.
/// 3. `streamHeaders`: HTTP headers to send with the initial stream request.
/// 4. `trackingUrl`: The URL for fetching information about upcoming ad breaks.
///    This is set by the video framework and should **not** be set manually by
///    framework users!
public struct LivestreamAdSettings: AdSettings {

    /// Parameters to send in the _body_ of requests to the livestream ad
    /// server.
    /// https://docs.aws.amazon.com/mediatailor/latest/ug/variables.html
    public var adParams: LivestreamAdParams?

    /// HTTP headers to use in livestream event beacon calls.
    @available (*, deprecated, renamed: "livestreamBeaconHeaders")
    public var beaconHeaders: [String: String] {
        get { return livestreamBeaconHeaders }
        set { livestreamBeaconHeaders = newValue }
    }

    /// HTTP headers to use in livestream event beacon calls.
    public var livestreamBeaconHeaders = [String: String]()

    /// HTTP headers to use when requesting livestream content.
    public var livestreamHTTPHeaders = [String: String]()

    /// The MediaTailor session ID, which is retrieved from MediaTailor when
    /// the video stream starts.
    public internal(set) var sessionId: String?

    /// HTTP headers to use when requesting livestream content.
    @available (*, deprecated, renamed: "livestreamHTTPHeaders")
    public var streamHeaders: [String: String] {
        get { return livestreamHTTPHeaders }
        set { livestreamHTTPHeaders = newValue }
    }

    /// Configure the Open Measurement components for validation testing. If
    /// this is `true`, then the Open Measurement validation script will be
    /// added to the list of OM session scripts.
    public var testOpenMeasurementCompliance = false

    /// The URL for livestream ad break metadata. This should be fetched AFTER
    /// the asset has been fetched and loaded, because the livestream ad server
    /// won't initialize the ads until the media's been 'fetched.
    public internal(set) var trackingUrl: URL?

    /// Empty initializer.
    public init() {
        // Empty. For some reason, if I don't include this, callers can't
        // initialize it, even though everything has a default initial value.
    }

}
