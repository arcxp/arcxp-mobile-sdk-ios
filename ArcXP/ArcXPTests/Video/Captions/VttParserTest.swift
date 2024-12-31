//  Copyright © 2020 The Washington Post. All rights reserved.

@testable import ArcXP

import XCTest

class VttParserTest: ArcMediaTestBase {

    func testVttParsedCues() throws {
        let vttStrPath = testBundle.path(forResource: "VttSampleFile", ofType: "vtt")
        let payload = try String(contentsOfFile: vttStrPath!, encoding: String.Encoding.utf8)
        let cues = VttParser.parse(vttPayload: payload)
        XCTAssert(cues.count == 130, "Unknown error occurred")

        let firstCue = cues[0]
        XCTAssertEqual(firstCue.text, "CONTINUE TO BE A PART OF MOST")
        XCTAssertEqual(firstCue.startTime, 4.390, accuracy: 0.01)
        XCTAssertEqual(firstCue.endTime, 4.720, accuracy: 0.01)
        XCTAssertEqual(firstCue.duration, 0.33, accuracy: 0.01)

        let eleventyFirstCue = cues[110]
        XCTAssertEqual(eleventyFirstCue.text, "COMFORTABLE WITH GETTING IN OUR")
        XCTAssertEqual(eleventyFirstCue.startTime, 226.610, accuracy: 0.01)
        XCTAssertEqual(eleventyFirstCue.endTime, 229.840, accuracy: 0.01)
        XCTAssertEqual(eleventyFirstCue.duration, 3.23, accuracy: 0.01)
    }

    func testMalformedCueTimesReturnZeroes() {
        let cueString = """
        111
        malformedStartTime --> malformedEndTime
        COMFORTABLE WITH GETTING IN OUR
        """
        let cue = Cue(cueBlock: cueString)!
        XCTAssertEqual(cue.startTime, 0.00)
        XCTAssertEqual(cue.endTime, 0.00)
    }

    func testMalformedCueStringReturnsNil() {
        let cueString = """
        111
        malformedStartTime NO ARROW malformedEndTime
        COMFORTABLE WITH GETTING IN OUR
        """
        XCTAssertNil(Cue(cueBlock: cueString))
    }

}
