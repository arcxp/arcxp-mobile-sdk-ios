//
//  ArcXP.swift
//  ArcXP
//
//  Created by Mahesh Venkateswarlu on 6/28/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import Foundation

/// A  utility class for getting the framework bundle and version number.
public final class ArcXPSDK: NSObject {

    /// The bundle for the framework. Using this is more reliable than calling
    /// `Bundle(for:)` every time a bundle is needed, and is especially handy
    /// if you're trying to get a bundle from inside a `struct` or other
    /// non-`class`.
    public static var bundle = Bundle(for: ArcXPSDK.self)

    /// The framework's version number, which is the bundle's
    /// `MARKETING_VERSION` (i.e. `CFBundleShortVersionString`).
    public static var version: String {
        return bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

}
