//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import XCTest

class MediaTailorSessionTests: ArcMediaTestBase {

    func testManifestUrlAndTrackingUrlFromString() {
        let session = MediaTailorSession(manifestPath: "/manifest", trackingPath: "/tracking")
        let baseUrl = URL(string: "https://arcpublishing.com")!
        XCTAssertEqual(session.manifestUrl(baseUrl: baseUrl)!.absoluteString,
                       "https://arcpublishing.com/manifest")
        XCTAssertEqual(session.trackingUrl(baseUrl: baseUrl)!.absoluteString,
                       "https://arcpublishing.com/tracking")
    }

    func testManifestUrlAndTrackingUrlFromRealData() throws {
        let session: MediaTailorSession = try MediaTailorSession.decode(fromJSONFilename: "mediatailor-session",
                                                                        inBundle: testBundle)
        let baseUrl = URL(string: "https://arcpublishing.com")!
        // swiftlint:disable line_length
        XCTAssertEqual(session.manifestUrl(baseUrl: baseUrl)!.absoluteString,
                       "https://arcpublishing.com/v1/master/77872db67918a151b697b5fbc23151e5765767dc/cmg_PROD_cmg-tv-10020_27d61a9c-67b2-4d7c-9486-626a6a071467_LE/in/cmg-wftxtv-hls-v3/live.m3u8?aws.sessionId=21a60830-a326-4a25-a895-c049cda40a67")
        XCTAssertEqual(session.trackingUrl(baseUrl: baseUrl)!.absoluteString,
                       "https://arcpublishing.com/v1/tracking/77872db67918a151b697b5fbc23151e5765767dc/cmg_PROD_cmg-tv-10020_27d61a9c-67b2-4d7c-9486-626a6a071467_LE/21a60830-a326-4a25-a895-c049cda40a67")
    }

    func testSessionIdFromWellFormedPathOk() throws {
        let session: MediaTailorSession = try MediaTailorSession.decode(fromJSONFilename: "mediatailor-session",
                                                                        inBundle: testBundle)
        XCTAssertEqual(session.sessionId, "21a60830-a326-4a25-a895-c049cda40a67")
    }

    func testSessionIdFromMalformedPathReturnsNil() throws {
        let session = MediaTailorSession(manifestPath: "/manifest", trackingPath: "/tracking")
        XCTAssertNil(session.sessionId)
    }

}
