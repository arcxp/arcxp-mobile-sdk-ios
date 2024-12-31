//
//  IdentityRequests.swift
//  Commerce
//
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation

/// A user sign up request.
struct SignUpRequest: Encodable {

    /// The Identity portion of the sign up request. These are required fields.
    struct Identity: Encodable {
        var userName: String
        var credentials: String
        var grantType: String = "password"
    }

    /// The identity to be created from signing up.
    var identity: Identity
    /// The profile to be created from signing up.
    var profile: UserProfile
    var recaptchaToken: String?

    init?(from data: UserProfile) {
        guard let username = data.userName, let password = data.password, let email = data.email else { return nil }
        self.identity = Identity(userName: username, credentials: password)
        self.profile = UserProfile(userName: username,
                                   password: password,
                                   email: email,
                                   firstName: data.firstName,
                                   lastName: data.lastName,
                                   secondLastName: data.secondLastName,
                                   displayName: data.displayName,
                                   gender: data.gender,
                                   imageUrlString: data.imageUrlString,
                                   birthYear: data.birthYear,
                                   birthMonth: data.birthMonth,
                                   birthDay: data.birthDay,
                                   contacts: data.contacts,
                                   addresses: data.addresses,
                                   attributes: data.attributes,
                                   legacyID: data.legacyID,
                                   deletionRule: data.deletionRule)
    }

    mutating func setRecaptchaToken(to token: String?) {
        recaptchaToken = token
    }
}

/// The model for a user login request.
struct LoginRequest: Encodable {
    var userName: String
    var credentials: String
    var recaptchaToken: String?
    var grantType: String = "password"
}

/// The model for a third party login request.
struct ThirdPartyLoginRequest: Encodable {
    var credentials: String
    var grantType: String
}

/// The model for updating password request.
struct UpdatePasswordRequest: Encodable {
    var oldPassword: String
    var newPassword: String
}

/// The model for an extending user session request.
struct ExtendSessionRequest: Encodable {
    var token: String
    var grantType: String = "refresh-token"
}

/// The model for a one time access link request.
struct OTALinkRequest: Encodable {
    var email: String
    var recaptchaToken: String?
}

/// The model for a reset password email request.
struct ResetPasswordEmailRequest: Encodable {
    var userName: String
}

/// The model for a password reset request.
struct ResetPasswordRequest: Encodable {
    var newPassword: String
}

/// The model for a user account deletion request.
struct DeclineDeleteAccountRequest: Encodable {
    var reason: String
    var notes: String
}
