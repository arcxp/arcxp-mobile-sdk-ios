//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import XCTest

/// Test cases that extend this class can easily get the 5- and 15-second
/// sample on-demand (not streaming) videos that are used throughout the test
/// suite.
class ArcMediaTestBase: XCTestCase {

    let testBundle = Bundle(for: ArcMediaTestBase.self)

    /// The URL for the 15-second sample video. This will be `nil` until
    /// `setUp()` is called.
    var fifteenSecondVideoUrl: URL!

    // The URL for the 5-second sample video. This will be `nil` until
    /// `setUp()` is called.
    var fiveSecondVideoUrl: URL!

    // swiftlint:disable line_length
    var realLivestreamVideoUrl = URL(string: "https://cmg-prod.video-api.arcpublishing.com/api/v1/ansvideos/findByUuid?uuid=67b34cf2-cd6a-4b46-a40b-1e6437ae0c64")
    // swiftlint:enable line_length

    override func setUp() {
        super.setUp()
        MediaEventCenter.shared.reset()
        fifteenSecondVideoUrl = testBundle.url(forResource: "space-15-seconds", withExtension: "mp4")!
        fiveSecondVideoUrl = testBundle.url(forResource: "space-5-seconds", withExtension: "mp4")!
    }
}
