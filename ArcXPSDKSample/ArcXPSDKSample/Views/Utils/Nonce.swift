//
//  Nonce.swift
//  ArcXPSDKSample
//
//  Created by Cassandra Balbuena on 7/31/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import Foundation

/// Represents a value that is only used once, and its specific type.
struct Nonce {
    /// The type of the ``Nonce``
    /// Can be: `oneTimeAccess`, `resetPassword`, `deleteAccount`
    enum NonceType: String {
        case oneTimeAccess
        case resetPassword
        case deleteAccount

        var webSocketMessageType: String {
            switch self {
            case .oneTimeAccess:
                return "MAGIC_LINK_SEND"
            case .resetPassword:
                return "PASSWORD_RESET_REQUEST"
            case .deleteAccount:
                return "ANONYMIZE_USER_DELETION_REQUESTED"
            }
        }
    }
    let value: String
    let type: NonceType
}
