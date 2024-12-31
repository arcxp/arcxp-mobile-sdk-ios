//
//  Reachability.swift
//  ArcXPContent
//
//  Created by David Seitz Jr on 2/1/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation
import SystemConfiguration

// Source: https://stackoverflow.com/questions/25398664/check-for-internet-connection-availability-in-swift

struct Reachability {
    /// A utility function for determining if the user's device has a network connection.
    static var isConnectedToNetwork: Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }

        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        if flags.isEmpty {
            return false
        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)

        return (isReachable && !needsConnection)
    }
}
