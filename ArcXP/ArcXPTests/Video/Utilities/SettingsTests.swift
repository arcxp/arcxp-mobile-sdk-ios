//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import XCTest

class SettingsTests: XCTestCase {

    var originalShowClosedCaptionsSetting = false

    override func setUp() {
        super.setUp()

        originalShowClosedCaptionsSetting = Settings.showClosedCaptions.get
        Settings.showClosedCaptions.set(false)
    }

    override func tearDownWithError() throws {
        Settings.showClosedCaptions.set(originalShowClosedCaptionsSetting)
    }

    func testSetAndGetShowClosedCaptions() {
        // The grand old Captions Setting, it had ten thousand men,
        XCTAssertFalse(Settings.showClosedCaptions.get)

        // It marched them up the hill,
        Settings.showClosedCaptions.set(true)
        XCTAssertTrue(Settings.showClosedCaptions.get)

        // And it marched them down again.
        Settings.showClosedCaptions.set(false)
        XCTAssertFalse(Settings.showClosedCaptions.get)
    }
}
