//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import GoogleInteractiveMediaAds
import XCTest

class ArcMediaAdErrorTests: XCTestCase {

    func testLocalizedDescriptionForNilIMAAdError() {
        let arcAdError = ArcMediaAdError(withIMAAdError: nil)
        XCTAssertTrue(arcAdError.localizedDescription.starts(with: "The Google IMAAdError"))
    }
}
