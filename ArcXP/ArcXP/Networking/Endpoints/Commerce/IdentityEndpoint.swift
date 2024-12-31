//
//  IdentityNetworkManager.swift
//  Commerce
//
//  Created by Seitz, David on 7/2/20.
//  Copyright © 2020 The Washington Post Company. All rights reserved.
//

import Foundation

// Swagger documentation: https://washpost.arcpublishing.com/alc/docs/swagger/?url=./arc-products/arc-identity-v1.json

/// Represents an Arc Identity endpoint
@available(iOS 13.0, *)
enum IdentityEndpoint: Endpoint {

    /// For user sign up requests.
    case signUp(_ user: SignUpRequest, _ reCaptchaToken: String?)
    /// For tenant configuration requests.
    case config
    /// For user login requests.
    case login(request: LoginRequest)
    /// For user third party login requests.
    case thirdPartyLogin(request: ThirdPartyLoginRequest)
    /// For deletion of third party identity.
    case removeUserIdentity(platform: AuthService)
    /// For user profile requests.
    case profile
    /// For updating login password requests.
    case updateLoginPassword(request: UpdatePasswordRequest)
    /// For updating user profile requests.
    case updateProfile(updatedUserProfileData: [String: Encodable])
    /// For extending user session requests.
    case extendUserSession(request: ExtendSessionRequest)
    /// For one time access link requests.
    case requestOTALink(request: OTALinkRequest)
    /// For redeeming one time access links.
    case redeemOTALink(nonceString: String)
    /// For reset password requests.
    case requestResetPassword(request: ResetPasswordEmailRequest)
    /// For redeeming reset password requests.
    case resetPassword(nonceString: String, request: ResetPasswordRequest)
    /// For account deletion requests.
    case requestDeleteAccount
    /// For approving account deletion requests.
    case approveDeleteAccount(nonce: String)
    /// For declining account deletion requests.
    case declineDeleteAccount(nonce: String, request: DeclineDeleteAccountRequest)

    var baseUrl: String {
        return Subscriptions.configuration.baseUrl+"/identity/public/v1"
    }

    var path: String {
        switch self {

        case .config:
            return "/config"

        case .signUp:
            return "/signup"

        case .login, .thirdPartyLogin:
            return "/auth/login"

        case .removeUserIdentity(let platform):
            return "/identity/\(platform.rawValue)"

        case .profile, .updateProfile:
            return "/profile"

        case .updateLoginPassword:
            return "/password"

        case .extendUserSession:
            return "/auth/token"

        case .requestOTALink:
            return "/auth/magiclink"

        case .redeemOTALink(let nonceString):
            return "/auth/magiclink/\(nonceString)"

        case .requestResetPassword:
            return "/password/reset"

        case .resetPassword(let nonceString, _):
            return "/password/reset/\(nonceString)"

        case .requestDeleteAccount:
            return "/user/anonymize"

        case .approveDeleteAccount(let nonceString):
            return "/user/anonymize/approve/\(nonceString)"

        case .declineDeleteAccount(let nonceString, _):
            return "/user/anonymize/decline/\(nonceString)"
        }
    }

    var method: String {
        switch self {

        case .signUp,
             .login,
             .thirdPartyLogin,
             .extendUserSession,
             .requestOTALink,
             .requestResetPassword:
            return "POST"

        case .updateProfile:
            return "PATCH"

        case .resetPassword,
             .updateLoginPassword,
             .approveDeleteAccount,
             .declineDeleteAccount:
            return "PUT"

        case .requestDeleteAccount, .removeUserIdentity:
            return "DELETE"

        default:
            return "GET"
        }
    }

    var headers: [String: String]? {

        var standardHeaders = ["Content-Type": ArcXPConstants.contentTypeHeader,
                               "Arc-Organization": Subscriptions.configuration.organization,
                               "Arc-Site": Subscriptions.configuration.site,
                               "User-Agent": ArcXPConstants.userAgentHeader]
        switch self {

        case .profile,
             .updateProfile,
             .updateLoginPassword,
             .requestDeleteAccount,
             .approveDeleteAccount,
             .declineDeleteAccount,
             .thirdPartyLogin,
             .removeUserIdentity:
            if let accessToken = Subscriptions.Identity.accessToken {
                standardHeaders["Authorization"] = "Bearer \(accessToken)"
            }

        default:
            break
        }

        return standardHeaders
    }

    var urlParameters: [String: String]? {
        return nil
    }

    /// The body data to be attached with the relevant Identity request.
    var body: Data? {

        switch self {

        case .signUp(var user, let reCaptchaToken):
            user.setRecaptchaToken(to: reCaptchaToken)
            return user.toJSONData()

        case .login(let request):
            return request.toJSONData()

        case .thirdPartyLogin(let request):
            return request.toJSONData()

        case .updateLoginPassword(let request):
            return request.toJSONData()

        case .requestOTALink(let request):
            return request.toJSONData()

        case .extendUserSession(let request):
            return request.toJSONData()

        case .requestResetPassword(let request):
            return request.toJSONData()

        case .resetPassword(_, let request):
            return request.toJSONData()

        case .updateProfile(let updatedUserProfileData):
            var updates = [String: AnyEncodable]()

            for update in updatedUserProfileData {
                let anyEncode = AnyEncodable(value: update.value)
                updates[update.key] = anyEncode
            }
            return updates.toJSONData()

        case .approveDeleteAccount:
            return Data("{}".utf8)

        case .declineDeleteAccount(_, let request):
            return request.toJSONData()

        default:
            return nil
        }
    }
}

struct AnyEncodable: Encodable {
    let value: Encodable

    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
