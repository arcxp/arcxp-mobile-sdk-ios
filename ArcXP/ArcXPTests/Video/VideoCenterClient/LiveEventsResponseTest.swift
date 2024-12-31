//
//  LiveEventsResponseTest.swift
//  ArcXPVideoiOSTests
//
//  Created by Mahesh Venkateswarlu on 10/19/22.
//  Copyright © 2022 The Washington Post. All rights reserved.
//

import XCTest
@testable import ArcXP

final class LiveEventsResponseTest: ArcMediaTestBase {

    func testLiveEventsResponse() throws {
        let responseUrl = testBundle.url(forResource: "liveEvents", withExtension: "json")!
        let liveEvents: [LiveEvent] = try [LiveEvent].decode(jsonURL: responseUrl,
                                                                             decoder: LiveEvent.decoder)
        XCTAssertEqual(liveEvents.count, 2)
        let liveEvent = liveEvents.first!
        XCTAssertNotNil(liveEvent.id)
        XCTAssertEqual(liveEvent.contentConfig.title, "NBA Sports live")
        XCTAssertNotNil(liveEvent.promoImage.imageUrl)
    }
    
    func testLiveEventsResponseWith() throws {
        let responseUrl = testBundle.url(forResource: "liveEvents", withExtension: "json")!
        let liveEvents: [LiveEvent] = try [LiveEvent].decode(jsonURL: responseUrl,
                                                                             decoder: LiveEvent.decoder)
        XCTAssertEqual(liveEvents.count, 2)
        let liveEvent = liveEvents[1]
        XCTAssertNil(liveEvent.promoImage.imageUrl)
    }

}
