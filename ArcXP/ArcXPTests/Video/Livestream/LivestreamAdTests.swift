//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import AVFoundation
import XCTest

class LivestreamAdTests: ArcMediaTestBase {

    typealias Response = LivestreamAdBreak.Response

    var adBreak: LivestreamAdBreak!

    var player: AVPlayer!

    var playerView: UIView!

    override func setUp() {
        super.setUp()

        player = AVPlayer(url: fifteenSecondVideoUrl)
        playerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 800.0, height: 600.0))
        let adBreaksUrl = testBundle.url(forResource: "real-avails", withExtension: "json")!

        do {
            let response: LivestreamAdBreak.Response = try .decode(jsonURL: adBreaksUrl)
            adBreak = response.adBreaks[0]
        } catch {
            XCTFail("Failed to decode the real-avails.json file")
        }
    }

    // MARK: - Ad Breaks

    func testAdBreaksProperties() throws {
        let response: Response = try Response.decode(fromJSONFilename: "avails",
                                                     inBundle: Bundle(for: type(of: self)))
        let adBreak = response.adBreaks[0]
        XCTAssertEqual(adBreak.adBreakId, "8104385")
        let firstAd = adBreak.ads![0]
        XCTAssertEqual(firstAd.adId, adBreak.adBreakId)
        XCTAssertEqual(firstAd.durationInSeconds, 15.1)
        XCTAssertEqual(firstAd.trackingEvents?.count, 6)
    }

    func testParseAdBreaksWithMediaFiles() throws {
        let response: Response = try Response.decode(fromJSONFilename: "avails-with-media-files",
                                                     inBundle: Bundle(for: type(of: self)))
        let adBreak = response.adBreaks[0]
        XCTAssertEqual(adBreak.adBreakId, "6744037")
    }

    func testParseAdBreaksWithCompanionAds() throws {
        let response: Response = try Response.decode(fromJSONFilename: "avails-with-companion-ads",
                                                     inBundle: Bundle(for: type(of: self)))
        let adBreak = response.adBreaks[0]
        XCTAssertEqual(adBreak.adBreakId, "3348173")

        #if os(iOS)
        // Confirm that there's a single Javascript resource, and that the
        // resource can be converted into an
        // `OMIDWashpostVerificationScriptResource`.
        guard let livestreamAd = adBreak.ads?.first else {
            XCTFail("There should be at least one ad.")
            return
        }

        XCTAssertEqual(livestreamAd.omidVerificationScriptResources.count, 1)
        #endif
    }

    // MARK: - AdBreakObservers
    // For some reason, these tests won't run in their own file.

    func testInitHasNonNilStartAndEndObservers() throws {
        let observers = LivestreamAdBreakObservers(adBreak: adBreak,
                                                   player: player)
        // each adObserver has 5 observers, + the start and end observers
        XCTAssertEqual(observers.adObservers.count, 60 + 2)
    }

    func testUpdateAvailWithFewerAds() throws {
        let observers = LivestreamAdBreakObservers(adBreak: adBreak,
                                                   player: player)
        XCTAssertEqual(observers.adBreak, adBreak)
        XCTAssertEqual(observers.adObservers.count, 60 + 2)

        // Remove all the observers.
        observers.cancel()
        XCTAssertEqual(observers.adBreak, adBreak)
        XCTAssertEqual(observers.adObservers.count, 0) // each adObserver has 5 observers
    }

}
