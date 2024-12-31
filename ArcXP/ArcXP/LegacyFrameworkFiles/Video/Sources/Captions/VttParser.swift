//  Copyright © 2020 The Washington Post. All rights reserved.

import Foundation

/// Parses Video Text Track (vtt) files for client-side captions in videos-on-
/// demand (VODs).
///
/// - see: https://en.wikipedia.org/wiki/WebVTT
class VttParser {

    /// Parse a Video Text Track (VTT) string and return an array of `Cue`s.
    ///
    /// ```
    /// Sample Format--
    /// WEBVTT FILE
    /// X-TIMESTAMP-MAP=MPEGTS:0,LOCAL:00:00:00.000
    ///
    /// 1
    /// 00:00:04.390 --> 00:00:04.720
    /// CONTINUE TO BE A PART OF MOST
    ///
    /// 2
    /// 00:00:04.720 --> 00:00:05.390
    /// PLANTS.
    /// ```
    /// - parameter vttPayload: the VTT file contents
    /// - returns: The parsed `Cue`s with the caption text and start and end
    ///   times.
    static func parse(vttPayload: String) -> [Cue] {
        let vttElements = vttPayload.components(separatedBy: "\n\n")
        let vttCues = vttElements.compactMap {Cue(cueBlock: $0)}
        return vttCues
    }

}

private extension String {

    /// A number of seconds, parsed from the VTT timestamp format
    /// (`HH:mm::ss.SSSS`).
    var secondFromString: Double {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSSS"

        if dateFormatter.date(from: self) != nil {
            // Split the timeformat "HH:mm:ss.SSSS" into an array of ["HH","mm","ss.SSSS"]
            let timeFormat = split(separator: ":")
                .map { $0.trimmingCharacters(in: .whitespaces)}
                .map { TimeInterval($0) ?? 0.0 }
            let totalTimeInSeconds = (timeFormat[0] * 60 * 60) + (timeFormat[1] * 60) + timeFormat[2]
            return totalTimeInSeconds
        }
        return 0.0
    }

}

/// A Cue block mainly contains three elements
/// text -- Text to display as caption
/// startTime -- start time to display the text
/// endTime -- end time to remove the text
struct Cue {

    /// The text to display.
    var text = ""

    /// The point at which the cue's text should start being displayed.
    let startTime: TimeInterval

    /// The point at which the cue's text should stop being displayed.
    let endTime: TimeInterval

    /// The number of seconds the cue's text should be displayed.
    var duration: TimeInterval {return endTime - startTime}

    /// Sample format for Cue String
    /// 1
    /// 00:00:04.390 --> 00:00:04.720
    /// CONTINUE TO BE A PART OF MOST
    ///
    /// - Parameter cueString: cueBodyString to be parsed
    init?(cueBlock: String) {
        let cueData = cueBlock.split(separator: "\n")
        let cueTimings = cueData.filter { $0.contains("-->") }

        guard let cueTimeString = cueTimings.first, cueData.count >= 3 else {
            return nil
        }

        let cueTimes = cueTimeString.components(separatedBy: "-->")
        startTime = cueTimes[0].secondFromString
        endTime = cueTimes[1].secondFromString

        text = cueData[2..<cueData.count].joined(separator: "\n")
    }

}
