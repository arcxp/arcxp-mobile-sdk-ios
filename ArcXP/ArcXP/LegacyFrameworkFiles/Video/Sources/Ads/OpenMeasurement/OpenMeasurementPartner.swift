//  Copyright © 2021 The Washington Post. All rights reserved.

import OMSDK_Washpost

/// Subclass of `OMIDWashpostPartner` that adds an OpenMeasurement script
/// version string property, as well as a singleton instance that can be used
/// both by PAL and by the OM code itself.
class OpenMeasurementPartner: OMIDWashpostPartner {

    /// Identifies the SDK to the Open Measurement server. The name was
    /// assigned to us when we signed up as an Open Measurement partner. The
    /// SDK is the ArcXPVideo framework's current version, and the script
    /// version should match the `OMSDK_Washpost.xcframework`'s version.
    static var shared: OpenMeasurementPartner = {
        let partner = OpenMeasurementPartner(name: "washpost",
                                             sdkVersion: "\(ArcXPSDK.version)",
                                             omidScriptVersion: "1.13.22")

        return partner!
    }()

    /// The version number of the JavaScript script that's injected into the
    /// OMID session.
    var omidScriptVersion: String

    /// Construct the partner info. For deployment purposes, the values will be
    /// the ones that are passed in when initializing the `shared` parameter,
    /// but this initializer can take other values for testing.
    ///
    /// - parameter name: The name that IAB generates to uniquely identify each
    ///   partner. It's taken from the domain name of the email address that
    ///   was used to register the partner account!
    /// - parameter sdkVersion: Our own framework's version number.
    /// - parameter omidScriptVersion: The version number of the generated
    ///   JavaScript file, which has to be downloaded from the "JS" tab of the
    ///   [OM SDK download site](https://tools.iabtechlab.com/omsdk) and copied
    ///   into the same folder as this class file.
    init?(name: String,
          sdkVersion: String,
          omidScriptVersion: String) {
        self.omidScriptVersion = omidScriptVersion
        super.init(name: name, versionString: sdkVersion)
    }

}
