//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import XCTest

// swiftlint:disable force_try line_length
class ArcMediaRealClientJSONTests: ArcMediaTestBase {

    var liveStreamWithoutStreamsVideo: VideoCenterResponse! // UUID: ddb86210-6958-4fdf-921a-e93c334b7f54
    var onDemandVideoOfLemurs: VideoCenterResponse!

    override func setUp() {
        super.setUp()

        onDemandVideoOfLemurs = try! VideoCenterResponse.decode(fromJSONFilename: "api-v1-ansvideos-findByUuid",
                                                                inBundle: testBundle,
                                                                decoder: VideoCenterResponse.decoder)
        liveStreamWithoutStreamsVideo = try! VideoCenterResponse.decode(fromJSONFilename: "api-v1-ansvideos-findByUuid-livestream-no-streams",
                                                                        inBundle: testBundle,
                                                                        decoder: VideoCenterResponse.decoder)
    }

    // MARK: - On-Demand Videos

    func testOnDemandVideoJSONDecoding() throws {
        XCTAssertEqual(onDemandVideoOfLemurs.duration, 35989)
    }

    func testVideoFindBestHLSStreamTypes() {
        let stream = onDemandVideoOfLemurs.findBestStream(preferredTypes: [.hls],
                                                          maximumBitrate: .max)
        XCTAssertNotNil(stream)
        XCTAssertEqual(stream!.bitrate, 4500)
    }

    func testVideoFindBestHLSStreamWithLowBitrateReturnsNil() {
        XCTAssertNil(onDemandVideoOfLemurs.findBestStream(preferredTypes: [.hls],
                                                          maximumBitrate: 50))
    }

    func testVideoFindBestTSStreamWith400OrLowerBitrate() {
        let stream = onDemandVideoOfLemurs.findBestStream(preferredTypes: [.transportStreams],
                                                          maximumBitrate: 400)
        XCTAssertNotNil(stream)
        XCTAssertEqual(stream!.bitrate, 300)
    }

    func testVideoFindBestTSStreamWithExactly300Bitrate() {
        let stream = onDemandVideoOfLemurs.findBestStream(preferredTypes: [.transportStreams],
                                                          maximumBitrate: 300)
        XCTAssertNotNil(stream)
        XCTAssertEqual(stream!.bitrate, 300)
    }

    // MARK: - Livestreams

    func testLiveStreamVideoJSONDecoding() throws {
        let video: VideoCenterResponse = try! .decode(fromJSONFilename: "api-v1-ansvideos-findByUuid-livestream",
                                                      inBundle: testBundle,
                                                      decoder: VideoCenterResponse.decoder)
        XCTAssertEqual(video.streams.count, 1)
    }

    func testLiveStreamVideoHasAdInsertionUrls() {
        let video: VideoCenterResponse = try! .decode(fromJSONFilename: "api-v1-ansvideos-findByUuid-livestream",
                                                      inBundle: testBundle,
                                                      decoder: VideoCenterResponse.decoder)
        let advertising = video.additionalProperties!.advertising!

        XCTAssertTrue(advertising.enableAdInsertion!)
        XCTAssertEqual(advertising.adInsertionUrls!.mediaTailorMaster,
                       URL(string: "https://d2l3bcedbrip41.cloudfront.net/v1/master/77872db67918a151b697b5fbc23151e5765767dc/cmg_QA_cmg-tv-10010_68635d7c-2eba-49c1-9c02-8682fe764f7a_LE/")!)
    }
    
    func testLiveStreamVideoHasMediaTailorUrl() throws {
        let video: VideoCenterResponse = try! .decode(fromJSONFilename: "api-v1-ansvideos-findByUuid-livestream",
                                                      inBundle: testBundle,
                                                      decoder: VideoCenterResponse.decoder)
        
        let stream = video.findBestStream(preferredTypes: [.hls],
                                                          maximumBitrate: .max)
        let streamUrlString = try XCTUnwrap(stream?.url)
        let streamUrl = try XCTUnwrap(URL(string: streamUrlString))
        let mediaTailorUrl = video.mediaTailorUrl(for: streamUrl)
        XCTAssertEqual(mediaTailorUrl?.absoluteString, "https://d2l3bcedbrip41.cloudfront.net/v1/session/77872db67918a151b697b5fbc23151e5765767dc/cmg_QA_cmg-tv-10010_68635d7c-2eba-49c1-9c02-8682fe764f7a_LE/out/v1/ee77ac0bd333445e8dd30e8b7f91bc22/index.m3u8")
    }

    // MARK: - Virtual Channels

    func testVirtualChannelJSONDecoding() throws {
        let virtualChannel: VirtualChannel = try! .decode(fromJSONFilename: "virtual-channels-200",
                                                          inBundle: testBundle)
        XCTAssertEqual(virtualChannel.programs.count, 3)
    }

}
