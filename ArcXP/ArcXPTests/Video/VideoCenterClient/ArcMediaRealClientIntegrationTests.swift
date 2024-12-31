//  Copyright © 2021 The Washington Post. All rights reserved.

@testable import ArcXP

import CoreLocation
import XCTest

class ArcMediaRealClientIntegrationTests: ArcMediaTestBase {

    static let orgId = "cmg"
    static let virtualChannelOrgId = "staging"
    let client = ArcMediaRealClient(organizationID: orgId,
                                    serverEnvironment: ServerEnvironment.production)

    // MARK: - Endpoint Tests

    func testValidNonGeorestrictedNonLegacyEndpoint() {
        let endpoint = ArcMediaRealClient.Endpoint.video(mediaId: "someId",
                                                         orgId: "someOrg",
                                                         serverEnvironment: .production)
        XCTAssertNotNil(endpoint.url)
    }
    
    func testNonAkamaiEndpointForStagingOnly() {
        let endpoint = ArcMediaRealClient.Endpoint.video(mediaId: "473d834",
                                                         orgId: "staging",
                                                         serverEnvironment: .sandbox)
        XCTAssertEqual(endpoint.url?.absoluteString, "https://staging-sandbox-cdn.video-api.arcpublishing.com/api/v1/ansvideos/findByUuid?uuid=473d834")
    }
    
    func testAkamaiEndpoint() {
        let endpoint = ArcMediaRealClient.Endpoint.video(mediaId: "3639d3b0-825e-4cd7-a6c6-9494e317629d",
                                                         orgId: Self.orgId,
                                                         serverEnvironment: .production)
        XCTAssertEqual(endpoint.url?.absoluteString, "https://cmg-config-prod.api.arc-cdn.net/video/v1/ansvideos/findByUuid?uuid=3639d3b0-825e-4cd7-a6c6-9494e317629d")
    }

    // MARK: - Virtual Channel Tests
    func testInvalidVirtualChannel() throws {
        let expectation = self.expectation(description: "invalid virtual channel")

        let client = ArcMediaRealClient(organizationID: Self.virtualChannelOrgId,
                                        serverEnvironment: .sandbox)
        client.virtualChannel(mediaID: "this-media-id-does-not-exist") { (result) in
            switch result {
            case .success:
                XCTFail("An error should have been returned")
            case .failure(let error):
                XCTAssertNotNil(error)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testInvalidVirtualChannel() async throws {
        let client = ArcMediaRealClient(organizationID: Self.virtualChannelOrgId,
                                        serverEnvironment: .sandbox)
        do {
            _ = try await client.virtualChannel(mediaID: "this-media-id-does-not-exist")
            XCTFail("An error should have been returned")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // This virtual channel `611ebfbef173c220a3b7db69` is running from 2021,
    // but if it throws invalid/stops in future, try updating with new or remove this test.
    func testValidVirtualChannel() async throws {
        let client = ArcMediaRealClient(organizationID: "cmg",
                                        serverEnvironment: .sandbox)
        do {
            let virtualChannel = try await client.virtualChannel(mediaID: "611ebfbef173c220a3b7db69")
            XCTAssertNotNil(virtualChannel.info)
        } catch {
            XCTFail("Expected a valid virtual channel but received - \(error.localizedDescription)")
        }
    }

    // MARK: - Livestream Tests

    func testMissingLivestreamVideoNotFound() {
        let expectation = self.expectation(description: "missing livestream video")
        // Use an ID that's fake, but that won't cause the Video Center URL to
        // be malformed.
        client.video(mediaID: "67b34cf2",
                     adSettings: nil,
                     accessToken: "unused") { (result) in
            switch result {
            case .success:
                XCTFail("The video should not have been found")
            case .failure(let error):
                guard let clientError = error as? ArcMediaClientError else {
                    XCTFail("Expected an ArcMediaClientError, but got \(error)")
                    return
                }

                switch clientError {
                case .mediaNotFound:
                    print("This is ok")
                default:
                    XCTFail("Got error \"\(error)\", but expected it to be ClientError.noMatchingResultsFound")
                }
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testMalformedLivestreamVideoUUIDNotFound() {
        let expectation = self.expectation(description: "malformed UUID")
        // Use an ID that will cause the Video Center URL to be malformed.
        let malformedID = "this ID has spaces, so it can't be a valid URL path"
        client.video(mediaID: malformedID,
                     adSettings: nil,
                     accessToken: "unused") { result in
            switch result {
            case .success:
                XCTFail("The video should not have been found")
            case .failure(let error):
                // Originally, the error would be a URLRequestError, but Swift and Xcode now replace spaces with "%20"
                // allowing a valid URL. Instead of returning a URLRequestError, an ArcXP.ArcMediaClientError is now returned.
                XCTAssertTrue(error is ArcXP.ArcMediaClientError) // Xcode 15

                // This is being returned to URLRequestError for the current Bitrise testing build.
//                XCTAssertTrue(error is URLRequestError) // Xcode 14
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    // MARK: - Georestrictions Tests

    // Since the the video uuids aren't consistent in the video-center,
    // Commenting the test to skip iy.
    /*
    func testUSGeorestrictedLivestreamVideoThrowsGeoRestrictionError() throws {
        let expectation = self.expectation(description: "georestricted video")
        let client = ArcMediaRealClient(organizationID: Self.orgId,
                                        serverEnvironment: ServerEnvironment.sandbox,
                                        enableLivestreamAds: false,
                                        useGeoRestrictions: true)
        client.video(mediaID: "ULOUNMEZB3KXC6H3MUJYXKAGM4",
                     adSettings: nil,
                     accessToken: "unused") { (result) in
            switch result {
            case .success:
                XCTFail("The video should be georestricted")
            case .failure(let error):
                if case let ArcMediaRealClient.ClientError.geoRestricted(location) = error {
                    XCTAssertEqual(location?.country, "US")

                    // Specific values will depend on the tester's location,
                    // so just make sure they're not nil.
                    XCTAssertNotNil(location?.zip)
                } else {
                    XCTFail("Got \"\(error)\", but it should have been a geoRestricted error")
                }
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }
*/
    func testUSNonGeorestrictedLivestreamVideoOk() throws {
        let expectation = self.expectation(description: "non-georestricted video")
        let client = ArcMediaRealClient(organizationID: Self.orgId,
                                        serverEnvironment: ServerEnvironment.sandbox,
                                        enableLivestreamAds: false)
        client.video(mediaID: "3639d3b0-825e-4cd7-a6c6-9494e317629d",
                     adSettings: nil,
                     accessToken: "unused") { (result) in
            switch result {
            case .success(let video):
                XCTAssertNil(video.adSettings)
            case .failure(let error):
                XCTFail("Expected the non-georestricted video to be returned without errors, but got \"\(error)\"")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }
    
    func testLiveStreamEvents() throws {
        let expectation = self.expectation(description: "find live stream events")
        client.findLiveEvents { liveEventsResult in
            switch liveEventsResult {
            case .success(let liveEvents):
                XCTAssertNotNil(liveEvents)
            case .failure(let error):
                XCTFail("Error in getting live events = \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testLiveEventMalformed() {
        let expectation = self.expectation(description: "malformed UUID")
        let client = ArcMediaRealClient(organizationID: "Malformed Org With Space",
                                        serverEnvironment: ServerEnvironment.production)
        client.findLiveEvents { liveEventsResult in
            switch liveEventsResult {
            case .success(_):
                XCTFail("The url should not have been broken")
            case .failure(let error):
                XCTAssertTrue(error is URLRequestError)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }
    
    @available(iOS 15.0.0, *)
    @available(tvOS 15.0.0, *)
    func testLiveStreamEventsAync() throws {
        let expectation = self.expectation(description: "async find live stream events")
        Task {
            let liveEvents = try await client.findLiveEvents()
            XCTAssertNotNil(liveEvents)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
}
