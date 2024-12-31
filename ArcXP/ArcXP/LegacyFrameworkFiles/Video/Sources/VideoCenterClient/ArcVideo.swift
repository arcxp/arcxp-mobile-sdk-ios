//  Copyright © 2020 The Washington Post. All rights reserved.

import AVFoundation
import UIKit

/// The access token that will allow the caller to request the for the media asset.
/// Tokens are obtained by authenticating with the ArcXP Video Center. **Note:
/// The format and type of this value are subject to change.**
public typealias ArcAccessToken = String

/// An `AVAsset` that is created by an `ArcMediaClient` and returned in the
/// client's
/// `video(mediaID:adSettings:accessToken:handleResult:)
/// response block. This video can then be wrapped in an `AVPlayerItem` and
/// passed to the `PlayerController` for playback.
public class ArcVideo: AVURLAsset {

    /// Custom ad settings for this video. These will *usually* override any
    /// default ad settings in the `PlayerController.adController`.
    public var adSettings: AdSettings?

    /// The URL for Google IMA ads to play
    public var adTagUrl: URL?

    /// Additional information about this video. The data type depends on the
    /// kind of video. If it's an ordinary on-demand or livestream video, this
    /// will be `nil`. If it's a virtual channel, this will be an array of the
    /// channel's programs.
    public var info: Any?

    /// The URL for the VTT captioning data. This will be non-`nil` only if
    ///
    /// * it's a video-on-demand (VOD) video,
    /// * the video does not already have embedded captions in its stream, and
    /// * a VTT file has been created for it in ArcXP Video Center.
    public internal(set) var clientSideCaptionsUrl: URL?

    /// Construct an asset directly from a URL. This is useful for callers who
    /// aren't creating video assets from the `ArcMediaClient`, for example.
    ///
    /// - parameter streamUrl: The URL for the video content.
    /// - parameter adSettings: Custom ad settings for this video. For example,
    ///   livestream ads are configured in a `LivestreamAdSettings` object that
    ///   can be passed in as the `adSettings` argument.
    /// - parameter clientSideCaptionsUrl: The URL for a VTT captions file for
    ///   captions that aren't embedded in the stream. This is used only for
    ///   non-livestream videos.
    convenience init(streamUrl: URL,
                     adSettings: AdSettings? = nil,
                     clientSideCaptionsUrl: URL? = nil,
                     options: [String: Any]? = nil) {
        self.init(url: streamUrl, options: options)
        self.adSettings = adSettings
        self.clientSideCaptionsUrl = clientSideCaptionsUrl
    }

}
