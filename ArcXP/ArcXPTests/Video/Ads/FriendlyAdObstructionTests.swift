//  Copyright © 2021 The Washington Post. All rights reserved.

@testable import ArcXP

#if os(iOS)
import OMSDK_Washpost
#endif

import GoogleInteractiveMediaAds
import XCTest

class FriendlyAdObstructionTests: ArcMediaPlayerBaseViewTestBase {

    func testCloseAdObstruction() {
        let view = UILabel(frame: .zero)
        let obstruction = FriendlyAdObstruction(view: view, purpose: .closeAd)
        XCTAssertEqual(obstruction.purpose.description, FriendlyAdObstruction.Purpose.closeAd.description)

        let imaObstruction = obstruction.asIMAObstruction
        XCTAssertEqual(imaObstruction.purpose, IMAFriendlyObstructionPurpose.closeAd)
    }

    func testMediaControlsObstruction() {
        let view = UILabel(frame: .zero)
        let obstruction = FriendlyAdObstruction(view: view, purpose: .mediaControls)
        XCTAssertEqual(obstruction.purpose.description, FriendlyAdObstruction.Purpose.mediaControls.description)

        let imaObstruction = obstruction.asIMAObstruction
        XCTAssertEqual(imaObstruction.purpose, IMAFriendlyObstructionPurpose.mediaControls)
    }

    func testNotVisibleObstruction() {
        let view = UILabel(frame: .zero)
        let obstruction = FriendlyAdObstruction(view: view, purpose: .notVisible)
        XCTAssertEqual(obstruction.purpose.description, FriendlyAdObstruction.Purpose.notVisible.description)

        let imaObstruction = obstruction.asIMAObstruction
        XCTAssertEqual(imaObstruction.purpose, IMAFriendlyObstructionPurpose.notVisible)
    }

    func testOtherObstruction() {
        let view = UILabel(frame: .zero)
        let description = "Some other description"
        let obstruction = FriendlyAdObstruction(view: view, purpose: .other(description: description))
        XCTAssertEqual(obstruction.purpose.description, description)

        let imaObstruction = obstruction.asIMAObstruction
        XCTAssertEqual(imaObstruction.purpose, IMAFriendlyObstructionPurpose.other)
    }

    #if os(iOS)

    func testRegisterWithOMIDAsSession() {
        let view = UILabel(frame: .zero)
        let obstruction = FriendlyAdObstruction(view: view, purpose: .notVisible)

        let adSession = OMIDWashpostAdSession()
        obstruction.register(with: adSession)
    }

    #endif

}
