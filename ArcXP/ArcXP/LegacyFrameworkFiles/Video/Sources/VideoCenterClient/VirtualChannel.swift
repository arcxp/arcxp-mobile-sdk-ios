//  Copyright © 2021 The Washington Post. All rights reserved.

import Foundation

/// The data model for a virtual channel, which is a video that consists of
/// multiple video segments, called ``Program``s. This is passed to
/// ``ArcMediaClient/virtualChannel(mediaID:handleResult:)``'s completion
/// handler. Information about the individual segments is in the ``programs``
/// property.
public struct VirtualChannel: Codable {

    /// The channel's unique ID.
    var id: String

    /// The channel's name, as configured in Video Center.
    var name: String

    /// The URL of the channel's media.
    var url: URL

    /// Information about the video segments that are in this channel.
    public var programs: [Program]

    /// The data model for a video segment of a virtual channel.
    public struct Program: Codable {

        /// The program's displayable description.
        public var description: String?

        /// The total duration of the program.
        public var duration: TimeInterval

        /// The program's unique identifier.
        public var id: String

        /// The URL of the program's thumbnail.
        public var imageUrl: URL?

        /// The program's name or title.
        public var name: String

        /// The URL for the individual program's video.
        public var url: URL

    }

}
