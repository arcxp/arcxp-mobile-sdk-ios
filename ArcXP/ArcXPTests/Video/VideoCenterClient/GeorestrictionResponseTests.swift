//  Copyright © 2021 The Washington Post. All rights reserved.

@testable import ArcXP

import XCTest

class GeorestrictionResponseTests: ArcMediaTestBase {

    func testResponseParser() throws {
        let responseUrl = testBundle.url(forResource: "georestriction-disallowed", withExtension: "json")!
        let geoRestriction: GeoRestriction = try GeoRestriction.decode(jsonURL: responseUrl,
                                                                       decoder: GeoRestriction.decoder)

        XCTAssertEqual(geoRestriction.type, "geo-restriction")
    }

}
