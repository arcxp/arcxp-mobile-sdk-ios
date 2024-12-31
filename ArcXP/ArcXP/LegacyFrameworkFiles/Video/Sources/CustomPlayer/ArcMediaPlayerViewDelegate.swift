//  Copyright © 2020 The Washington Post. All rights reserved.

import Foundation
import AVKit

/// A protocol for callbacks that are specific to the `ArcMediaPlayerView`, as
/// opposed to ones that are for the `AVPlayer` or
/// ``ArcMediaPlayerViewController``.
public protocol ArcMediaPlayerViewDelegate: PlayerDelegate {

    /// The control bar is now visible.
    ///
    /// - parameter playerView: The `ArcMediaPlayerView`.
    func playerViewControlBarDidAppear(_ playerView: ArcMediaPlayerView)

    /// The control bar is about to be shown.
    ///
    /// - parameter playerView: The `ArcMediaPlayerView`.
    func playerViewControlBarWillAppear(_ playerView: ArcMediaPlayerView)

    /// The control bar is no longer visible.
    ///
    /// - parameter playerView: The `ArcMediaPlayerView`.
    func playerViewControlBarDidDisappear(_ playerView: ArcMediaPlayerView)

    /// The control bar is about to be hidden.
    ///
    /// - parameter playerView: The `ArcMediaPlayerView`.
    func playerViewControlBarWillDisappear(_ playerView: ArcMediaPlayerView)

}

public extension ArcMediaPlayerViewDelegate {

    func playerViewControlBarDidAppear(_ playerView: ArcMediaPlayerView) { }

    func playerViewControlBarWillAppear(_ playerView: ArcMediaPlayerView) { }

    func playerViewControlBarDidDisappear(_ playerView: ArcMediaPlayerView) { }

    func playerViewControlBarWillDisappear(_ playerView: ArcMediaPlayerView) { }

    func playerAdWillOpenExternalApplication(player: AVPlayer) { }

    func playerAdWillOpenInAppLink(player: AVPlayer) { }

    func playerAdDidOpenInAppLink(player: AVPlayer) { }

    func playerAdWillCloseInAppLink(player: AVPlayer) { }

    func playerAdDidCloseInAppLink(player: AVPlayer) { }
}
