//  Copyright © 2021 The Washington Post. All rights reserved.

import UIKit

public class ArcMediaPlayerView: ArcMediaPlayerBaseView {

    // MARK: - UIView Properties

    /// Allow the player to receive focus. This is important, especially on
    /// tvOS, because it allows the view to receive events from the TV remote.
    /// (It may also be important for accessibility, but this hasn't been
    /// tested.)
    public override var canBecomeFocused: Bool {
        return true
    }

    // MARK: - Initialization

    override func initializeUI() {
        super.initializeUI()

        clientSideCaptionTextShadowColor = UIColor.darkGray
    }

}
