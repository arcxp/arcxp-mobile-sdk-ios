//  Copyright © 2021 The Washington Post. All rights reserved.

import GoogleInteractiveMediaAds
import UIKit

#if os(iOS)
import OMSDK_Washpost
#endif

/// Information about a subview that appears in the player view on top of any
/// ad content. Both Google IMA ads and Open Measurement require these to be
/// registered so that the views' area isn't counted against the ad
/// impressions. It can be converted to the provider-specific types with
/// ``asIMAObstruction`.
///
/// One thing to keep in mind is that the Google IMA SDK _itself_ conforms to
/// the Open Measurement specification, and its `IMAFriendlyObstruction` and
/// `IMAFriendlyObstructionPurpose` types just wrap or shadow the OMID ones, so
/// they both the IMA and OMID ones use the exact same purpose names. (They
/// probably use the same raw enum values, too, but since there's no guarantee
/// of that, we have to use our own ``FriendlyAdObstruction/Purpose-swift.enum``
/// enum.)
public struct FriendlyAdObstruction {

    /// The reasons why a view can appear on top of ad content.
    public enum Purpose {

        /// A button to close the ad.
        case closeAd

        /// Player controls.
        case mediaControls

        /// Invisible views, such as for capturing gestures.
        case notVisible

        /// Any other kind. A description should be provided to report back to
        /// the ad tracker.
        case other(description: String)

        /// The description of the obstruction's purpose. This is passed to the
        /// ad trackers, but I'm not sure what they do with it.
        var description: String {
            switch self {
            case .closeAd:
                return "Close button"
            case .mediaControls:
                return "Player controls"
            case .notVisible:
                return "Invisible content"
            case .other(let description):
                return description
            }
        }

        /// Get the `IMAFriendlyObstructionPurpose` of the obstruction's
        /// `Purpose`.
        var asIMAPurpose: IMAFriendlyObstructionPurpose {
            switch self {
            case .closeAd:
                return .closeAd
            case .mediaControls:
                return .mediaControls
            case .notVisible:
                return .notVisible
            case .other:
                return .other
            }
        }

        #if os(iOS)
        /// Get the `OMIDFriendlyObstructionPurpose` of the obstruction's
        /// `Purpose`.
        var asOMIDPurpose: OMIDFriendlyObstructionType {
            switch self {
            case .closeAd:
                return .closeAd
            case .mediaControls:
                return .mediaControls
            case .notVisible:
                return .notVisible
            case .other:
                return .other
            }
        }
        #endif
    }

    /// The view that can be drawn over the ad content.
    public var view: UIView

    /// The reason for the obstruction.
    public var purpose: Purpose

    /// Get the `IMAFriendlyObstruction` equivalent of the obstruction.
    public var asIMAObstruction: IMAFriendlyObstruction {
        return IMAFriendlyObstruction(view: view,
                                      purpose: purpose.asIMAPurpose,
                                      detailedReason: purpose.description)
    }

    /// Tell the `IMAAdDisplayContainer` about this obstruction. (This
    /// function is a little redundant, since it's easy enough to simply call
    /// `IMAAdDisplayContainer.register()` directly, but since OMID doesn't
    /// have a type that's equivalent to IMA's `IMAFriendlyObstruction`, this
    /// function hides that fact from the caller, and works like the OMID one.)
    public func register(with displayContainer: IMAAdDisplayContainer) {
        displayContainer.register(self.asIMAObstruction)
    }

    #if os(iOS)

    /// Tell the OMID session about this obstruction.
    public func register(with session: OMIDWashpostAdSession) {
        do {
            try session.addFriendlyObstruction(view,
                                               purpose: purpose.asOMIDPurpose,
                                               detailedReason: purpose.description)
        } catch {
            ArcXPLogger.log("Failed to register a friendly obstruction with the OMID ad session", error: error)
        }
    }

    #endif

}
