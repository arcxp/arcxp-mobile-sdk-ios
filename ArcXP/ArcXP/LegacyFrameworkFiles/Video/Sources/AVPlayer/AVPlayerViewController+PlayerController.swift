//  Copyright © 2020 The Washington Post. All rights reserved.

import AVFoundation
import AVKit

extension AVPlayerViewController: PlayerControllerContainer {

    /// A ``PlayerController`` instance that uses the ``AVPlayer`` and root
    /// view.
    ///
    /// **Note:** because extensions can't store properties, this returns a
    /// new ``PlayerController`` instance every time it's used, so callers
    /// should assign it to a local variable or class property.
    public var playerController: PlayerController? {
        if player == nil {
            player = ArcPlayer()
        }

        let playerController = PlayerController(player: player!,
                                                playerView: self.view,
                                                containedInViewController: self)
        self.delegate = playerController

        return playerController
    }

}

extension PlayerController: AVPlayerViewControllerDelegate {
#if os(iOS)
    /// When the player enters fullscreen mode, fire a
    /// ``MediaEvent/playerBeganFullScreenPresentation(_:item:)``. (Note: this
    /// delegate function is called *before* the player goes fullscreen, but
    /// the event says that it the transition happened already.)
    public func playerViewController(_ playerViewController: AVPlayerViewController,
                                     willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        MediaEventCenter.shared.sendEvent(.playerBeganFullScreenPresentation(player,
                                                                             item: player.currentItem))
    }

    /// When the player exits fullscreen mode, fire a
    /// ``MediaEvent/playerEndedFullScreenPresentation(_:item:)``. (Note: this
    /// delegate function is called *before* the player exits fullscreen mode,
    /// but the event says that it the transition happened already.)
    public func playerViewController(_ playerViewController: AVPlayerViewController,
                                     willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        MediaEventCenter.shared.sendEvent(.playerEndedFullScreenPresentation(player,
                                                                             item: player.currentItem))
    }
#endif
}
