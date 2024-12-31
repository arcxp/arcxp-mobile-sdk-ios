//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import XCTest

class ArcMediaSampleClientTests: ArcMediaTestBase {

    let client = ArcMediaSampleClient()

// swiftlint:disable force_cast
    func testVideoInAlwaysThrowsMode() {
        let client = ArcMediaSampleClient(alwaysThrows: true)
        let exp = expectation(description: "video() in alwaysThrow mode should return an error result")

        do {
            client.video(mediaID: "none",
                         adSettings: nil,
                         accessToken: "none") { (videoResult) in
                switch videoResult {
                case .failure:
                    exp.fulfill()
                case .success:
                    XCTFail("alwaysFail mode should return an error result")
                }
            }
        }

        wait(for: [exp], timeout: TestConstant.standardTimeout)
    }

    func testVideoReturnsCannedVideo() throws {
        let client = ArcMediaSampleClient(alwaysThrows: false)
        let exp = expectation(description: "video() should return the canned video")

        client.video(mediaID: "none",
                                         adSettings: nil,
                                         accessToken: "none") { (videoResult) in
            switch videoResult {
            case .success(let video):
                XCTAssertEqual(video.url, client.sampleMediaUrl)
                exp.fulfill()
            case .failure:
                XCTFail("The canned video should have been returned")
            }
        }

        wait(for: [exp], timeout: TestConstant.standardTimeout)
    }
    
    func testLiveEvents() {
        let client = ArcMediaSampleClient(alwaysThrows: false)
        let exp = expectation(description: "Empty Live events")
        client.findLiveEvents { liveEventsResult in
            switch liveEventsResult {
            case .success(let liveEvents):
                XCTAssertNotNil(liveEvents)
                XCTAssertTrue(liveEvents.isEmpty)
            case .failure:
                XCTFail("Live events should be returned")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: TestConstant.standardTimeout)
    }
    
    @available(iOS 15.0.0, *)
    @available(tvOS 15.0.0, *)
    func testLiveEventsAync() throws {
        let client = ArcMediaSampleClient(alwaysThrows: false)
        let expectation = self.expectation(description: "async find live events")
        Task {
            let liveEvents = try await client.findLiveEvents()
            XCTAssertNotNil(liveEvents)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TestConstant.standardTimeout)
    }

    // MARK: - VirtualChannels

    @available(iOS 15.0, *)
    @available(tvOS 15.0, *)
    func testVirtualChannelAsyncReturnsVideoWithPrograms() {
        let client = ArcMediaSampleClient(alwaysThrows: false)
        let exp = expectation(description: "virtualChannel() should return an ArcVideo with Programs")

        Task {
            let virtualChannel = try await client.virtualChannel(mediaID: "some ID")
            let programs = virtualChannel.info as! [VirtualChannel.Program]
            XCTAssertEqual(1, programs.count)
            exp.fulfill()
        }

        wait(for: [exp], timeout: TestConstant.standardTimeout)
    }

    @available(iOS 15.0, *)
    @available(tvOS 15.0, *)
    func testVirtualChannelAsyncInErrorModeThrows() {
        let exp = expectation(description: "virtualChannel() throw an error")
        let client = ArcMediaSampleClient(alwaysThrows: true)

        Task {
            do {
                _ = try await client.virtualChannel(mediaID: "some ID")
                XCTFail("Expected an error to be thrown.")
            } catch {
                // As expected
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: TestConstant.standardTimeout)
    }
}
