//
//  PictureInPictureManager.swift
//  ArcXP
//
//  Created by Seitz, David on 8/2/23.
//  Copyright © 2023 The Washington Post Company. All rights reserved.
//

import AVKit

// Related documentation
// • Configuring your app for media playback: https://developer.apple.com/documentation/avfoundation/media_playback/configuring_your_app_for_media_playback/
// • Adopting Picture in Picture in a Standard Player: https://developer.apple.com/documentation/avkit/adopting_picture_in_picture_in_a_standard_player
// • Adopting Picture in Picture in a Custom Player: https://developer.apple.com/documentation/avkit/adopting_picture_in_picture_in_a_custom_player
//
// Note: In order to allow picture in picture, the client application must first
// enable "Audio, Airplay, and Picture in Picture" in "Background Modes" under
// "Signing & Capabilities". If "Background Modes" isn't seen there, simply add
// it by clicking the "+" icon in the top left of the "Signing & Capabilities" view.
// View the "Configuring your app for media playback" documentation above for more details.

/// This manager provides convenient ways to enable, disable, and manage picture in picture functionality.
public class PictureInPictureManager: NSObject {

    enum Error: LocalizedError {
        case pictureInPictureNotSupported
        var errorDescription: String? {
            switch self {
            case .pictureInPictureNotSupported:
                return NSLocalizedString("Picture-in-picture operation failed due to picture-in-picture not being supported.",
                                         comment: "Picture-in-picture not supported.")
            }
        }
    }

    /// A custom picture-in-picture controller for handling PIP functionality.
    private static var pipController: AVPictureInPictureController?

    /// An abstracted instance which handles delegation responsibilities for `PictureInPictureControllerDelegate`.
    private static let pictureInPictureDelegationHandler = PictureInPictureManager()

    /// A reference to the player view for easily hiding the Picture-in-Picture controller when returning to the app.
    private static var playerLayer: AVPlayerLayer?

    // MARK: - Setup

    public static func setUp(with customPlayer: AVPlayer, for sender: UIViewController) throws {
        let playerLayer: AVPlayerLayer = AVPlayerLayer()
        playerLayer.player = customPlayer
        sender.view.layer.addSublayer(playerLayer)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = sender.view.bounds
        playerLayer.isHidden = true
        pipController = AVPictureInPictureController(playerLayer: playerLayer)
        guard let pipController = pipController,
              pipController.isPictureInPictureSuspended else {
            throw PictureInPictureManager.Error.pictureInPictureNotSupported
        }

        pipController.delegate = pictureInPictureDelegationHandler
    }

    // MARK: - Audio Session Management

    /// Activate the session that will support picture-in-picture playback.
    public static func activatePictureInPictureSession() throws {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try AVAudioSession.sharedInstance().setActive(true)
    }

    /// Stop the session that supports picture-in-picture playback.
    public static func deactivatePictureInPictureSession() throws {
        try AVAudioSession.sharedInstance().setActive(false)
    }

    // MARK: - Convenience Values

    /// Returns a boolean value indicating whether or not picture-in-picture is currently active.
    public static func isPictureInPictureSupported() -> Bool {
        return AVPictureInPictureController.isPictureInPictureSupported()
    }

    /// Starts picture-in-picture if it is supported.
    public static func manuallyStartPictureInPicture() {
        PictureInPictureManager.pipController?.startPictureInPicture()
    }

    /// Stops picture-in-picture if it is supported.
    public static func manuallyStopPictureInPicture() {
        PictureInPictureManager.pipController?.stopPictureInPicture()
    }
}

extension PictureInPictureManager: AVPictureInPictureControllerDelegate {

    // Note: These methods are required to be public to satisfy the protocol requirement.

    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // Hide the player layer (it will automatically be shown again when the app is backgrounded).
        PictureInPictureManager.playerLayer?.isHidden = true
    }
}
