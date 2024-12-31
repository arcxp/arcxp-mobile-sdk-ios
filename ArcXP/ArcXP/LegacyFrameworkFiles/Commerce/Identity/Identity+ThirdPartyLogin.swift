//
//  Identity+ThirdPartyLogin.swift
//  Commerce
//
//  Created by David Seitz Jr on 6/2/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation

public extension Subscriptions.Identity {

    /// Logs the user into Commerce using Facebook sign in.
    /// - Parameters:
    ///     - token: The token returned from the Facebook authentication service.
    ///     - completion: A completion handler returning the associated user data.
    static func logInWithFacebook(token: String, completion: UserCompletion? = nil) {
        Subscriptions.Identity.authenticate(credential: token, platform: .facebook) { completion?($0) }
    }

    /// Logs the user into Commerce using Apple sign in.
    /// - Parameters:
    ///     - token: The token returned from the Apple authentication service.
    ///     - completion: A completion handler returning the associated user data.
    static func logInWithApple(token: String, completion: UserCompletion? = nil) {
        Subscriptions.Identity.authenticate(credential: token, platform: .apple) { completion?($0) }
    }

    /// Logs the user into Commerce using Google sign in.
    /// - Parameters:
    ///     - token: The token returned from the Google authentication service.
    ///     - completion: A completion handler returning the associated user data.
    static func logInWithGoogle(token: String, completion: UserCompletion? = nil) {
        Subscriptions.Identity.authenticate(credential: token, platform: .google) { completion?($0) }
    }

    /// Removes one of a user's identity or login options.
    /// - Parameters:
    ///     - platform: The platform of the identity to be deleted.
    ///     - completion: A completion handler returning the associated user data.
    static func removeUserIdentity(platform: AuthService, completion: @escaping (_ result: Result<UserProfile, Error>) -> Void) {
        NetworkManager.requestForCodable(from: IdentityEndpoint.removeUserIdentity(platform: platform)) { completion($0) }
    }
}
