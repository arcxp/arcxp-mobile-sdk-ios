//  Copyright © 2021 The Washington Post. All rights reserved.

@testable import ArcXP

import AVFoundation
import XCTest

class ClientSideCaptionsTests: ArcMediaTestBase {

    // MARK: - Embedded Captions

    func fetchVideo(_ handleSuccess: @escaping (ArcVideo) -> Void,
                    file: StaticString = #file,
                    line: UInt = #line) {
        let client = ArcMediaSampleClient()
        client.video(mediaID: "", adSettings: nil, accessToken: "") { (result) in
            switch result {
            case .success(let video):
                handleSuccess(video)
            case .failure:
                XCTFail("The sample video should have been returned.", file: file, line: line)
            }
        }
    }

//     func testSampleVideoHasEmbeddedCaptions() throws {
//         fetchVideo { (video) in
//             let playerItem = AVPlayerItem(asset: video)
//             XCTAssertTrue(playerItem.hasClosedCaptions)
//             XCTAssertTrue(playerItem.hasEmbeddedCaptions())
//
//             switch playerItem.captionType {
//             case .embedded(let locale):
//                 XCTAssertEqual(locale, AVPlayerItem.defaultLocale)
//             case .clientSide,
//                     .none:
//                 XCTFail("The sample video should have embedded captions")
//             }
//         }
//     }
//
//     func testSampleVideoDoesNotHaveEmbeddedSwahiliCaptions() throws {
//         fetchVideo { (video) in
//             let playerItem = AVPlayerItem(asset: video)
//             XCTAssertTrue(playerItem.hasClosedCaptions)
//             let swahili = Locale(identifier: "sw_KE") // Kenyan, specifically
//             XCTAssertFalse(playerItem.hasEmbeddedCaptions(forLocale: swahili))
//         }
//     }
//
//     func testShowAndHideEmbeddedCaptionsInSampleVideo() throws {
//         fetchVideo { (video) in
//             let playerItem = AVPlayerItem(asset: video)
//             XCTAssertTrue(playerItem.showEmbeddedCaptions())
//             XCTAssertTrue(playerItem.hideEmbeddedCaptions())
//         }
//     }

    func testShowAndHideEmbeddedSwahiliCaptionsInSampleVideoFails() throws {
        fetchVideo { (video) in
            let playerItem = AVPlayerItem(asset: video)
            let swahili = Locale(identifier: "sw_KE") // Kenyan, specifically
            XCTAssertFalse(playerItem.showEmbeddedCaptions(forLocale: swahili))
            XCTAssertFalse(playerItem.hideEmbeddedCaptions(forLocale: swahili))
        }
    }

}
