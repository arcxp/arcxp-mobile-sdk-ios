//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import XCTest

// swiftlint:disable line_length

class ArcMediaAdConfigTests: XCTestCase {

    func testDecodeFromString() throws {
        let adConfigUrl = URL(string: "https://pubads.g.doubleclick.net/gampad/ads?slotname=/124319096/external/ad_rule_samples&sz=640x480&ciu_szs=300x250&cust_params=deployment%3Ddevsite%26sample_ar%3Dpostonly&url=https://developers.google.com/interactive-media-ads/docs/sdks/html5/tags&unviewed_position_start=1&output=xml_vast3&impl=s&env=vp&gdfp_req=1&ad_rule=0&vad_type=linear&vpos=postroll&pod=1&ppos=1&lip=true&min_ad_duration=0&max_ad_duration=30000&vrid=6016&video_doc_id=short_onecue&cmsid=496&kfa=0&tfcd=0")
        let config: ArcMediaAdConfig = ArcMediaAdConfig(adConfigUrl: adConfigUrl, adEnabled: true)

        XCTAssertTrue(config.adEnabled)
    }

}
