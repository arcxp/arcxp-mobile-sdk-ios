//  Copyright © 2020 The Washington Post. All rights reserved.

import AVFoundation

/// Convenient additions to `AVPlayerItem`.
public extension AVPlayerItem {

    // MARK: - Timing

    /// The very _latest_ possible time that's been loaded so far.
    var endTime: CMTime? {
        return seekableTimeRanges.last?.timeRangeValue.end
    }

    /// `true` if the asset has an indefinite duration. Note that it's possible
    /// for a non-live asset to be indefinite if it hasn't finished loading,
    /// but this is the best way that I know of to detect a livestream without
    /// checking the URL type.
    var isLive: Bool {
        return asset.duration.isIndefinite
    }

    /// How far along in the video the current time is, where `0.0` is the
    /// beginning of the item and `1.0` is the end.
    var progress: Float? {
        guard let endTimeSeconds = endTime?.seconds else {
            return nil
        }

        let currentSeconds = currentTime().seconds
        let progress = currentSeconds / endTimeSeconds

        return Float(progress)
    }

    /// The very _earliest_ possible time that's been loaded so far.
    var startTime: CMTime? {
        return seekableTimeRanges.last?.timeRangeValue.start
    }

}

/// Adds a simpler way to toggle embedded captions in an `AVPlayerItem`.
public extension AVPlayerItem {

    /// The default locale to use for client-side captioning. In theory, this
    /// can be changed to something other than `en_US`, but no other locale has
    /// been tested.
    static var defaultLocale = Locale(identifier: "en_US")

    /// The types of captions that this item supports.
    enum CaptionType: Equatable {

        /// Client-side captions, such as WebVTT (.vtt files).
        case clientSide

        /// Captions that are embedded into the stream itself. **Right now**,
        /// the locale will _always_ be the `defaultLocale`, which is `en_US`.
        case embedded(locale: Locale)

        /// No captions are available.
        case none

    }

    /// The type of captions supported by this item, if any. First, it checks
    /// whether there are client-side captions; if not, it checks whether there
    /// are embedded captions in the `defaultLocale`.
    var captionType: CaptionType {
        if hasClientSideCaptions {
            return .clientSide
        } else if hasEmbeddedCaptions() {
            return .embedded(locale: AVPlayerItem.defaultLocale)
        } else {
            return .none
        }
    }

    /// If the `asset` is an ``ArcVideo``, this will be its
    /// `clientSideCaptionsUrl`; otherwise, it's `nil`.
    var clientSideCaptionsUrl: URL? {
        return (asset as? ArcVideo)?.clientSideCaptionsUrl
    }

    /// The `.legible` media selections in the asset, which represent any
    /// captions embedded in the stream.
    var embeddedCaptionsGroup: AVMediaSelectionGroup? {
        return asset.mediaSelectionGroup(forMediaCharacteristic: .legible)
    }

    /// `true` if the `asset` is an ``ArcVideo`` and it has a non-`nil`
    /// `clientSideCaptionsUrl`.
    var hasClientSideCaptions: Bool {
        return clientSideCaptionsUrl != nil
    }

    /// `true` if the asset `hasEmbeddedCaptions` or `hasClientSideCaptions`.
    var hasClosedCaptions: Bool {
        return hasEmbeddedCaptions() || hasClientSideCaptions
    }

    /// `true` if one of the asset's media characteristics is `legible` for
    /// a give locale, which indicates that captions are embedded into the
    /// stream.
    ///
    /// - parameter locale: The locale for the desired captions. The default is
    ///   `en_US`.
    func hasEmbeddedCaptions(forLocale locale: Locale = AVPlayerItem.defaultLocale) -> Bool {
        guard let group = embeddedCaptionsGroup else {
            return false
        }

        let options =
            AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: locale)

        return !options.isEmpty
    }

    /// Hide captions by disabling their media selection group.
    ///
    /// - parameter locale: The locale for the desired captions. The default is
    ///   `en_US`.
    ///
    /// - returns: `true` if the stream contains embedded captions, and they
    ///   were disabled.
    @discardableResult
    func hideEmbeddedCaptions(forLocale locale: Locale = AVPlayerItem.defaultLocale) -> Bool {
        if hasEmbeddedCaptions(forLocale: locale) {
            guard let group = embeddedCaptionsGroup else {
                return false
            }

            select(nil, in: group)

            return true
        } else {
            return false
        }
    }

    /// Show captions by enabling their media selection group.
    ///
    /// - returns: `true` if the stream contains embedded captions for the
    ///   specified locale (by default, the `AVPlayerItem.defaultLocale`), and
    ///   they were enabled.
    @discardableResult
    func showEmbeddedCaptions(forLocale locale: Locale = AVPlayerItem.defaultLocale) -> Bool {
        guard let group = embeddedCaptionsGroup,
            let option = group.options(forLocale: locale).first else {
                return false
        }

        select(option, in: group)

        return true
    }

}

extension AVMediaSelectionGroup {

    /// Get the media selection options for the specified locale.
    ///
    /// - parameter locale: The locale whose media selection options are
    ///   being looked up. By default, this is `AVPlayerItem.defaultLocale`.
    func options(forLocale locale: Locale = AVPlayerItem.defaultLocale) -> [AVMediaSelectionOption] {
        return AVMediaSelectionGroup.mediaSelectionOptions(from: self.options, with: locale)
    }

}

// MARK: - AVPlayerItem.Status

extension AVPlayerItem.Status {

    /// Get the `int` value of the `AVPlayerItem.Status` from an  `NSNumber`,
    /// which is what's returned by a key-value observation of the
    /// `AVPlayerItem.status` property.
    ///
    /// - parameter anyNumber: The `NSNumber` returned by a key-value change.
    ///   This is cast to an `NSNumber`, which is then used to get an `int`,
    ///   which in turn is used to get an `AVPlayerItem.Status`.
    static func from(anyNumber: Any?) -> AVPlayerItem.Status? {
        if let intValue = (anyNumber as? NSNumber)?.intValue {
            return AVPlayerItem.Status(rawValue: intValue)
        } else {
            return nil
        }
    }

}
