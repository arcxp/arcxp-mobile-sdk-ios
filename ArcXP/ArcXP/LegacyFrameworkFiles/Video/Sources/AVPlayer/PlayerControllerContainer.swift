//  Copyright © 2020 The Washington Post. All rights reserved.

/// Implemented by classes that provide or use a `PlayerController`. This
/// is currently implemented by the `ArcMediaPlayerViewController` and an
/// extension of the `AVPlayerViewController` so that callers don't need to
/// know which one was the owner of a `PlayerController` after they've been
/// set up.
@available(*, deprecated, renamed: "PlayerControllerContainer")
public typealias AVPlayerControllerContainer = PlayerControllerContainer

/// Implemented by classes that provide or use a `PlayerController`. This
/// is currently implemented by the `ArcMediaPlayerViewController` and an
/// extension of the `AVPlayerViewController` so that callers don't need to
/// know which one was the owner of a `PlayerController` after they've been
/// set up.
///
/// ```
/// var useCustomPlayer = true
/// let playerControllerContainer: PlayerControllerContainer
/// let playerController: PlayerController?
///
/// if useCustomPlayer {
///     playerControllerContainer = ArcMediaPlayerViewController(...)
/// } else {
///     playerControllerContainer = AVPlayerViewController(...)
/// }
///
/// // From this point on, the caller doesn't need to know or care which kind
/// // of view controller provided the `PlayerController`.
/// playerController = playerControllerContainer.playerController
///
/// ```
/// The sample app's `ConfigureVideoViewController.prepareForSegue(for:sender:)`
/// shows how to do this with segues.
public protocol PlayerControllerContainer {

    /// The `PlayerController` that this container provides. **Note:** the
    /// container may not hold a strong reference to the `PlayerController`,
    /// so the caller must do so.
    var playerController: PlayerController? { get }

}
