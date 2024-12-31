//  Copyright © 2021 The Washington Post. All rights reserved.

import AVFoundation
import UIKit

/// Formerly the ``ArcMediaPlayerView``, this is now the *base class* for
/// platform-specific implementations of the ``ArcMediaPlayerView``.
public class ArcMediaPlayerBaseView: UIView, MediaEventSubscriber {

    // MARK: - Public Outlets

    /// Display error message on playerview
    @IBOutlet public weak var playErrorMessageLabel: UILabel?

    // MARK: - Public Properties

    /// Callbacks for UI-related actions.
    public weak var delegate: ArcMediaPlayerViewDelegate?

    /// The player that the `AVPlayerLayer` uses.
    public internal(set) var player: AVPlayer! {
        didSet {
            playerLayer.player = player
        }
    }

    /// Convenience property to get the view's root-level layer as an
    /// `AVPlayerLayer` instance. It works in conjunction with this class's
    /// implementation of ``layerClass``.
    public var playerLayer: AVPlayerLayer {
        // swiftlint:disable force_cast
        return layer as! AVPlayerLayer
        // swiftlint:enable force_cast
    }

    // MARK: - UIView Properties

    /// Sets `AVPlayerLayer` as the root-level layer type.
    public override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    // MARK: - Public Properties

    /// Get the views that may appear above the video layer. These have to be
    /// registered with ad providers as "friendly obstructions" so that ads
    /// won't report that they're partially blocked from view.
    public var friendlyAdObstructions: [FriendlyAdObstruction] = []

    // MARK: - Initialization

    /// Construct the view programmatically. The view will subscribe to the
    /// shared ``MediaEventCenter``.
    ///
    /// - parameter frame: The location and size of the view.
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initializeUI()
    }

    /// Construct the view by deserializing its nib data. The view will
    /// subscribe to the shared ``MediaEventCenter`` when ``awakeFromNib()`` is
    /// called.
    ///
    /// - parameter coder: The data decoder.
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// Load the nib data and subscribe to the shared ``MediaEventCenter``.
    public override func awakeFromNib() {
        super.awakeFromNib()
        initializeUI()
    }

    /// Set up the UI by setting the ``friendlyAdObstructions`` and subscribing
    /// to ``MediaEvent``s.
    func initializeUI() {
        MediaEventCenter.shared.addSubscriber(self)
    }

    // MARK: - Captioning

    /// The label that displays client-side (VTT) captions. Caption text is
    /// set as the label's `attributedString`.
    @IBOutlet public weak var captionsLabel: UILabel? {
        didSet {
            // Clear the text that was set in the storyboard.
            captionsLabel?.text = ""
        }
    }

    /// The text color for the client-side caption overlay text. The default
    /// value is `UIColor.white`. The color should contrast with the
    /// ``clientSideCaptionTextShadowColor`` so that it will show up clearly,
    /// no matter what the underlying video content looks like.
    public var clientSideCaptionTextColor = UIColor.white

    /// The text color for the client-side caption overlay text shadow. The
    /// default value is `UIColor.black`. It should contrast with the
    /// ``clientSideCaptionTextColor`` so that it will show up clearly, no
    /// matter what the underlying video content looks like.
    public var clientSideCaptionTextShadowColor = UIColor.black

    /// Whether closed captions are being shown.
    public var isDisplayingClosedCaptions: Bool = false

    /// Update the player UI to indicate whether client-side (VTT) captions are
    /// on or off.
    public var showClientSideCaptions: Bool = false {
        didSet {
            captionsLabel?.isHidden.toggle()

            // Just to be safe, clear everything.
            if !showClientSideCaptions {
                captionsLabel?.text = nil
                captionsLabel?.attributedText = nil
            }
        }
    }

    /// Display the multiline captions label with the specified `captionText`.
    /// The attributed string has `UIColor.lightText` (or `.white` on tvOS)
    /// text, with a `UIColor.darkText` (or `.black` on tvOS) shadow.
    ///
    /// - parameter captionText: The text to display in the label.
    func showClientSideCaption(_ captionText: String) {
        let textColor = clientSideCaptionTextColor
        let shadow = NSShadow()
        shadow.shadowColor = clientSideCaptionTextShadowColor
        shadow.shadowOffset = CGSize(width: 2.0, height: 2.0)
        shadow.shadowBlurRadius = 4.0
        let attributedCaption = NSAttributedString(string: captionText,
                                                   attributes: [.foregroundColor: textColor,
                                                                .shadow: shadow])
        captionsLabel?.attributedText = attributedCaption
    }

    // MARK: - MediaEventSubscriber

    /// An empty of the ``MediaEventSubscriber`` so that the subclasses can
    /// simply override it. (If I made each subclass implement the protocol
    /// themselves, then they'd both have to override all of the initializers,
    /// and that seems redundant.
    public func receiveEvent(_ event: MediaEvent) {

        // Empty. The platform-specific subclasses will override it.

    }

}
