//  Copyright © 2020 The Washington Post. All rights reserved.

import Foundation
import GoogleInteractiveMediaAds

/// Ad-related error types. These are based on `IMAAdError` types, since that's
/// the first third-party ad implementation that was used.
public enum ArcMediaAdError: LocalizedError {
    // Note that this must implement the LocalizedError protocol and the
    // errorDescription property. This seems backwards--why not implement Error
    // and localizedDescription? This is the preferred way now.

    /// The ad couldn't be loaded for some reason.
    case loadFailed(IMAAdError?)

    /// The ad content loaded, but it couldn't be played back for some reason.
    case playFailed(IMAAdError?)

    /// Some other error occurred.
    case unknown(IMAAdError?)

    // MARK: - Initialization

    /// Get an ``ArcMediaAdError`` that corresponds to an `IMAAdError`.
    ///
    /// - parameter adError: The `IMAAdError` type. This is either passed back
    ///   directly by a Google IMA delegate call (like
    ///   `IMAAdsManagerDelegate.adsManager(_:didReceive:)`, or from an
    ///   `IMAAdLoadingErrorData` object (like from
    ///   `IMAAdsLoaderDelegate.adsLoader(_:failedWith: IMAAdLoadingErrorData!)`).
    public init(withIMAAdError adError: IMAAdError?) {
        guard let adError = adError else {
            self = .unknown(nil)

            return
        }

        switch adError.type {
        case .adLoadingFailed:
            self = .loadFailed(adError)
        case .adPlayingFailed:
            self = .playFailed(adError)
        default:
            self = .unknown(adError)
        }
    }

    // MARK: - Error

    /// A string containing the underlying `IMAAdError`'s `message`, `type`,
    /// and `code`.
    /// - seeAlso: https://developers.google.com/interactive-media-ads/docs/sdks/ios/v3/reference/Classes/IMAAdError
    /// - seeAlso: https://developers.google.com/interactive-media-ads/docs/sdks/ios/v3/reference/Enums/IMAErrorCode.html
    /// - seeAlso: https://developers.google.com/interactive-media-ads/docs/sdks/ios/v3/reference/Enums/IMAErrorType.html
    public var errorDescription: String? {
        switch self {
        case .loadFailed(let adError),
             .playFailed(let adError),
             .unknown(let adError):
            if let adError = adError, let message = adError.message {
                return message + " (type \(adError.type.rawValue), code \(adError.code.rawValue))"
            } else {
                return "The Google IMAAdError is nil, so there are no " +
                       "specifics about what happened."
            }
        }
    }
}
