//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import GoogleInteractiveMediaAds
import XCTest

// swiftlint:disable force_cast
class GoogleIMAAdControllerTests: ArcMediaTestBase {

    var adController: GoogleIMAAdController!

    var adsLoader: IMAAdsLoader!

    // swiftlint:disable weak_delegate
    // The delegate can't be weak because we're not retaining it anywhere else.
    var delegate: MockPlayerDelegate!
    // swiftlint:enable weak_delegate

    var playerController: PlayerController!

    var player: AVPlayer!

    var viewController: ArcMediaPlayerViewController!

    override func setUp() {
        super.setUp()

        player = AVPlayer()
        adsLoader = IMAAdsLoader(settings: nil)
        delegate = MockPlayerDelegate()
        viewController = ArcMediaPlayerViewController.loadFromStoryboard()
        _ = viewController.view // force viewDidLoad() to be called
        playerController = viewController.playerController
        playerController.delegate = delegate
        adController = (playerController.adController as! GoogleIMAAdController)
    }

    override func tearDown() {
        super.tearDown()
        player.replaceCurrentItem(with: nil)
        delegate = nil
    }

    func testInitializer() throws {
        XCTAssertEqual(adController.adDisplayContainerView, viewController.view)
        XCTAssertEqual(adController.webOpenerPresentingController, viewController)
    }

    func testConfigureWithJSONFile() throws {
        let config: ArcMediaAdConfig = ArcMediaAdConfig(adConfigUrl: adConfigUrl, adEnabled: true)
        adController.configure(config)
        XCTAssertEqual(adController.adTagUrl,
                       URL(string: "https://www.arcpublishing.com/fake_config_url")!)
    }

    func testPlayDefaultAd() {
        let playerItem = AVPlayerItem(url: fiveSecondVideoUrl)
        player.replaceCurrentItem(with: playerItem)

        // swiftlint:disable line_length
        adController.configure(adTagUrl: URL(string: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=")!)
        // swiftlint:enable line_length

        let expectation = self.expectation(description: "Sample ad and video")
        player.fire(at: 2.0) {
            expectation.fulfill()
        }

        player.play()
        adController.requestAds()

        wait(for: [expectation], timeout: TestConstant.standardTimeout)
        XCTAssertTrue(delegate.wereExpectedCallsMade([.playerAdStarted]))
    }

    func testPlayDefaultAdWithEmptyDelegate() {
        let playerItem = AVPlayerItem(url: fifteenSecondVideoUrl)
        player.replaceCurrentItem(with: playerItem)

        // swiftlint:disable line_length
        adController.configure(adTagUrl: URL(string: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=")!)
        // swiftlint:enable line_length

        player.fire(at: 4.0) { [unowned self] in
            adController.pauseAd()
            adController.resumeAd()
        }

        let adCompleted = expectation(description: "Do-nothing delegate ad")
        player.fire(at: 12.0) {
            adCompleted.fulfill()
        }

        player.play()
        adController.requestAds()

        wait(for: [adCompleted], timeout: TestConstant.longTimeout)
        // There's nothing to assert. This is just making sure that as many of
        // the default protocol implementation's callbacks are called.
    }

    let adConfigUrl = URL(string: "https://www.arcpublishing.com/fake_config_url")

}
