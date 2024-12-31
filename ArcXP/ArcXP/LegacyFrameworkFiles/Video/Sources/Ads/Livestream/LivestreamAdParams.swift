//  Copyright © 2020 The Washington Post. All rights reserved.

import Foundation

/// A simple struct for storing livestream `adsParams` values. Since it's so
/// easy to confuse `adParams` with `adsParams`, using this ensures that the
/// correct element name will be used.
///
/// - seeAlso: https://docs.aws.amazon.com/mediatailor/latest/ug/variables.html
public struct LivestreamAdParams: Codable {

    /// The dictionary to pass in the body of a livestream ad request.
    public var adsParams: [String: String]

    /// Construct the parameters with a dictionary of values. These will be
    /// in the body of the `adsParams` JSON element that's passed in the body
    /// of an ad `POST` request.
    ///
    /// - parameter adsParams: The dictionary of values.
    public init(adsParams: [String: String]) {
        self.adsParams = adsParams
    }

}
