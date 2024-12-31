//  Copyright © 2021 The Washington Post. All rights reserved.

@testable import ArcXP

import XCTest

class ArcMediaRealClientErrorTests: XCTestCase {

    typealias Err = ArcMediaRealClient.ClientError

    func testGeoRestrictionWithoutLocation() {
        let error = Err.geoRestricted(location: nil)
        XCTAssertEqual(error.localizedDescription,
                       "The video isn't available in your location.")
    }

    func testGeoRestrictionWithLocation() {
        let location = GeoRestriction.Location(country: "US", zip: "90210")
        let error = Err.geoRestricted(location: location)

        if case let Err.geoRestricted(location) = error {
            XCTAssertEqual(location?.country, "US")
            XCTAssertEqual(location?.zip, "90210")
            XCTAssertEqual(error.localizedDescription,
                           "The video isn't available in your location (US, ZIP code(s) 90210).")

        } else {
            XCTFail("Somehow, the if case let failed.")
        }
    }

    func testMalformedResponse() {
        let errorWithNilData = Err.malformedResponse(data: nil)
        XCTAssertEqual(errorWithNilData.localizedDescription,
                       "The server's response wasn't in the expected format.")

        let expectedData = "Some data".data(using: .ascii)
        let errorWithStringData = Err.malformedResponse(data: expectedData)

        if case let Err.malformedResponse(data) = errorWithStringData {
            XCTAssertNotNil(data)
            let convertedString = String(data: data!, encoding: .ascii)
            XCTAssertEqual(convertedString, "Some data")
        } else {
            XCTFail("Somehow, the if case let failed.")
        }

        XCTAssertEqual(errorWithNilData.localizedDescription, "The server's response wasn't in the expected format.")
    }

    func testNoMatchingResultsFound() {
        XCTAssertEqual(Err.noMatchingResultsFound.localizedDescription,
                       "The video couldn't be found.")
    }

    func testNoMatchingStreamsFoundError() {
        let streamTypes: [StreamType] = [.gif, .hls]
        let maxBitrate = UInt(500)
        let error = Err.noMatchingStreamsFound(streamTypes: streamTypes, maximumBitrate: maxBitrate)
        if case let Err.noMatchingStreamsFound(actualTypes, actualBitrate) = error {
            XCTAssertEqual(actualTypes, streamTypes)
            XCTAssertEqual(actualBitrate, maxBitrate)
        } else {
            XCTFail("Somehow, the if case let failed.")
        }

        XCTAssertEqual(error.localizedDescription,
                       """
The video was found, but not in the expected types (gif, hls) or with a \
bitrate lower than 500 bps.
""")
    }

}
