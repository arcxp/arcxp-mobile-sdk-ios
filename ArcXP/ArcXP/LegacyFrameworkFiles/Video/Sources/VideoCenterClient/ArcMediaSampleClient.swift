//  Copyright © 2020 The Washington Post. All rights reserved.

import Foundation

/// A mock implementation that always returns canned data from
/// `video(mediaID:accessToken)`. If the client's `alwaysThrows` property is
/// `true`, then throwing calls will throw `Error`s. Like the
/// `ArcMediaRealClient`, you _can_ use an instance of this directly, but
/// unless you're using it in unit tests, it's better to set
/// `ArcMediaClientManager.client` to an instance of it, then use
/// `ArcMediaClientManager.client` throughout your application.
open class ArcMediaSampleClient: NSObject, ArcMediaClient {

    // MARK: - ArcMediaClient Properties

    /// The ID of the organization that this client fetches videos for. This
    /// sample client just sets it to a dummy value.
    public var organizationID: String = "NoOrganization"

    // MARK: - Public Properties

    /// If set to `true`, any method that _can_ throw an `Error` _will_ throw
    /// one.
    open var alwaysThrows = false

    /// The URL of the sample video that will always be returned by calls to
    /// `video(mediaID:accessToken:)`. This one is for a
    /// Washington Post video from the 2020 Iowa Democratic Caucus, but it can
    /// be set to any media URL you wish.
    open var sampleMediaUrl = URL(string: "https://d21rhj7n383afu.cloudfront.net/washpost-production/The_Washington_Post/20200211/5e42c3d4cff47e0001baedcc/5e42ee2046e0fb00099e96ed/mobile.m3u8")!

    // MARK: - ArcMediaClient Functions
    /// Initialize the client. If desired, pass `true` to force all calls to
    /// throw or return an error.
    public init(alwaysThrows: Bool = false) {
        self.alwaysThrows = alwaysThrows
        super.init()
    }

    /// Always returns the same sample video, regardless of the function
    /// parameters. If the ``alwaysThrows`` property is `true`, then it will
    /// throw a generic `Error` instead.
    open func video(mediaID: ArcMediaID,
                    adSettings: AdSettings?,
                    accessToken: ArcAccessToken,
                    handleResult: @escaping ArcVideoResultHandler) {
        if alwaysThrows {
            let error = NSError(domain: "ArcXPVideo", code: 0)
            handleResult(.failure(error))
        } else {
            handleResult(.success(ArcVideo(url: sampleMediaUrl)))
        }
    }

    /// Always returns the same sample video as a virtual channel, regardless
    /// of the function parameters. If the ``alwaysThrows`` property is `true`,
    /// then the result handler will return a generic `Error` instead.
    open func virtualChannel(mediaID: ArcMediaID,
                             handleResult: @escaping ArcVideoResultHandler) {
        if alwaysThrows {
            let error = NSError(domain: "ArcXPVideo", code: 0)
            handleResult(.failure(error))
        } else {
            handleResult(.success(sampleVideoChannel))
        }
    }

    /// Get the sample video. Its ``ArcVideo/info`` property will be an array
    /// with a single sample ``VirtualChannel/Program`` object.
    @available(iOS 15.0.0, *)
    @available(tvOS 15.0.0, *)
    open func virtualChannel(mediaID: ArcMediaID) async throws -> ArcVideo {
        if alwaysThrows {
            throw NSError(domain: "ArcXPVideo", code: 0)
        } else {
            return sampleVideoChannel
        }
    }

    @available(iOS 15.0.0, *)
    @available(tvOS 15.0.0, *)
    public func findLiveEvents() async throws -> [LiveEvent] {
        if alwaysThrows {
            throw NSError(domain: "ArcXPVideo", code: 0)
        } else {
            return []
        }
    }

    @available(iOS, deprecated: 15.0, obsoleted: 16.0)
    public func findLiveEvents(handleResult: @escaping (Result<[LiveEvent], Error>) -> Void) {
        if alwaysThrows {
            let error = NSError(domain: "ArcXPVideo", code: 0)
            handleResult(.failure(error))
        } else {
            handleResult(.success([]))
        }
    }

    private var sampleVideoChannel: ArcVideo {
        let video = ArcVideo(url: sampleMediaUrl)
        video.info = [
            VirtualChannel.Program(description: "No description",
                                   duration: Double(video.duration.seconds),
                                   id: "sample ID",
                                   imageUrl: nil,
                                   name: "Sample Virtual Channel",
                                   url: URL(string: "https://www.arcxp.com")!)
        ]

        return video
    }

}
