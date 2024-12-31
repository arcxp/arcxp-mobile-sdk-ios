//
//  Identity.swift
//  Commerce
//
//  Created by Davis, Tyler on 5/27/21.
//  Copyright © 2020 The Washington Post Company. All rights reserved.
//

import Foundation
// swiftlint: disable file_length
// MARK: - API calls
@available(iOS 13.0, *)
extension Subscriptions.Identity {

    /// Creates a new user, identity, profile with the provided data
    /// - Parameters:
    ///   - user: Data model that contains a user's sign up information
    ///   - rememberMe: RememberMe flag that can be used to refresh the user session if the access token expires
    ///   - reCaptchaToken: Invinsible reCAPTCHA V2 token to deter bots and other malicious actors
    ///   - completion: Completion Handler with ``UserCompletion`` Result type
    public static func signUp(user: UserProfile,
                              rememberMe: Bool = false,
                              reCaptchaToken: String? = nil,
                              completion: @escaping UserCompletion) {

        // Return if recaptcha is nil but the org settings needs it.
        if let tenantSettings = Subscriptions.configOptions, tenantSettings.signupRecaptcha, reCaptchaToken == nil {
            return completion(.failure(SubscriptionsError.userAccountError(reason: .noDataProvided(while: "attempting to sign up for new Commerce account with recaptcha."))))
        }

        guard let signUpRequest = SignUpRequest(from: user) else {
            return completion(.failure(SubscriptionsError.userAccountError(reason: .noDataProvided(while: "attempting to sign up without required fields"))))
        }

        let signUpEndpoint = IdentityEndpoint.signUp(signUpRequest, reCaptchaToken)
        NetworkManager.requestForCodable(from: signUpEndpoint) { (result: Result<UserAuthResponse, Error>)  in
            switch result {
            case .success(let userSignupResponse):
                Subscriptions.rememberMe = rememberMe
                storeUserData(userSignupResponse, completion: nil)
                guard let userProfile = userSignupResponse.profile else {
                    completion(.failure(SubscriptionsError.userAccountError(reason: .noUserProfileReturnedFromBackend)))
                    return
                }
                completion(.success(userProfile))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Login to Commerce with the given credentials and creates a user session for the logged in user.
    /// - Parameters:
    ///   - username: Username of the user
    ///   - password: Password of the user
    ///   - rememberMe: RememberMe flag that can be used to refresh the user session if the access token expires
    ///   - reCaptchaToken: Invinsible reCAPTCHA V2 token to deter bots and other malicious actors
    ///   - completion: Completion Handler with ``UserCompletion`` Result type
    public static func logIn(username: String,
                             password: String,
                             rememberMe: Bool = false,
                             reCaptchaToken: String? = nil,
                             completion: @escaping UserCompletion) {

        // Return if recaptcha is nil but the org settings needs it.
        if let tenantSettings = Subscriptions.configOptions, tenantSettings.signinRecaptcha, reCaptchaToken == nil {
            completion(.failure(SubscriptionsError.userAccountError(reason: .noDataProvided(while: "attempting to login for new Commerce account with recaptcha."))))
        }

        let loginEndpoint = IdentityEndpoint.login(request: LoginRequest(userName: username, credentials: password, recaptchaToken: reCaptchaToken))
        NetworkManager.requestForCodable(from: loginEndpoint) { (result: Result<UserAuthResponse, Error>) in

            switch result {
            case .success(let user):
                Subscriptions.rememberMe = rememberMe
                storeUserData(user, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Login to Commerce with the given uuid and tokens. Creates a user session for the logged in user.
    /// - Parameters:
    ///   - uuid: A universal unique identifier for the user
    ///   - accessToken: A user access token
    ///   - refreshToken: A refresh token to extend a user session
    ///   - completion: Completion Handler with ``UserCompletion`` Result type
    public static func logIn(uuid: String,
                             accessToken: String,
                             refreshToken: String,
                             completion: @escaping UserCompletion) {
        let authData = UserAuthResponse(uuid: uuid,
                                          identities: nil,
                                          accessToken: accessToken,
                                          refreshToken: refreshToken,
                                          existingSocialLogin: nil)
        storeUserData(authData, completion: completion)
    }

    /// Authenticates third party login credentials with the Commerce backend.
    /// - parameter credential: The credential delivered by the third party auth service.
    /// - parameter platform: The third party platform that was used to authenticate the user.
    /// - parameter completion: A completion function including the user that is returned from the Commerce backend.
    static func authenticate(credential: String, platform: AuthService, completion: @escaping UserCompletion) {
        let thirdPartyLoginRequest = ThirdPartyLoginRequest(credentials: credential, grantType: platform.rawValue)
        let endpoint = IdentityEndpoint.thirdPartyLogin(request: thirdPartyLoginRequest)
        NetworkManager.requestForCodable(from: endpoint) { (result: Result<UserAuthResponse, Error>) in
            switch result {
            case .success(let user):
                if let existingSocialLogin = user.existingSocialLogin,
                   existingSocialLogin && Subscriptions.cachedUserProfile != nil {
                    let error = SubscriptionsError.userAccountError(reason: user.uuid == Subscriptions.cachedUserProfile?.uuid ?
                                                                .socialAccountAlreadyAdded : .socialLoginAlreadyExists)
                    completion(.failure(error))
                    return
                }
                // Third party login utilize rememberMe by default
                Subscriptions.rememberMe = true
                storeUserData(user, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Commits any queuedUserProfileUpdates.
    /// This will clear the queue regardless if the result is successful or errors. Ensure all updates conform to their model.
    /// - Parameters:
    ///   - completion: Completion Handler with ``UserCompletion`` Result type
    public static func commitUserProfileUpdates(completion: @escaping UserCompletion) {

        let commitCompletion: UserCompletion = { userResult in
            queuedUserProfileUpdates.removeAll()
            completion(userResult)
        }

        guard queuedUserProfileUpdates.count > 0 else {
            let noUpdatesError = SubscriptionsError.userAccountError(reason: .noDataProvided(while: "Skipping user profile updates due to no updates being queued."))
            commitCompletion(.failure(noUpdatesError))
            return
        }

        guard let accessToken = accessToken else {
            devPrint("Commerce: Failed to update user profile due to missing access token.")
            commitCompletion(.failure(SubscriptionsError.userAccountError(reason: .noAccessTokenAvailable)))
            return
        }

        guard validateAccessToken(accessToken: accessToken) else {
            extendUserSession { result in
                switch result {
                case .success:
                    commitUserProfileUpdates(completion: completion)
                case .failure(let error):
                    commitCompletion(.failure(error))
                }
            }
            return
        }

        let updateProfileEndpoint = IdentityEndpoint.updateProfile(updatedUserProfileData: queuedUserProfileUpdates)

        NetworkManager.requestForCodable(from: updateProfileEndpoint) { (result: Result<UserProfile, Error>) in
            switch result {
            case .success(let userProfile):
                saveUserProfileData(userProfile)
                guard let currentUser = Subscriptions.cachedUserProfile else {
                    commitCompletion(.failure(SubscriptionsError.userAccountError(reason: .currentUserNotAvailable)))
                    return
                }
                commitCompletion(.success(currentUser))
            case .failure(let error):
                commitCompletion(.failure(error))
            }
        }
    }

    /// Requests a one time access link.
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - reCaptchaToken: A reCaptcha token, if available.
    ///   - completion: Completion handler with a ``ServiceCompletion`` result type.
    public static func requestOneTimeAccessLink(email: String,
                                                reCaptchaToken: String? = nil,
                                                completion: @escaping ServiceCompletion) {

        // Return if recaptcha is nil but the org settings needs it.
        if let tenantSettings = Subscriptions.configOptions, tenantSettings.magicLinkRecaptcha, reCaptchaToken == nil {
            completion(.failure(SubscriptionsError.userAccountError(reason: .noDataProvided(while: "attempting to generate one time access email with recaptcha."))))
        }

        let endpoint = IdentityEndpoint.requestOTALink(request: OTALinkRequest(email: email, recaptchaToken: reCaptchaToken))

        NetworkManager.requestForCodable(from: endpoint) { (result: Result<EmailSentSuccessResponse, Error>) in
            switch result {
            case .success(let emailSent):
                if emailSent.success {
                    completion(.success)
                } else {
                    completion(.failure(SubscriptionsError.userAccountError(reason: .failedToSendEmail)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Redeem the nonce from one time access link and creates non-refreshable user session.
    /// - Parameters:
    ///   - nonce: Nonce information associated with the user.
    ///   - completion: Completion handler with a ``ServiceCompletion`` result type.
    public static func redeemOneTimeAccessLink(nonce: String, completion: @escaping ServiceCompletion) {
        let endpoint = IdentityEndpoint.redeemOTALink(nonceString: nonce)

        NetworkManager.requestForCodable(from: endpoint) { (result: Result<OTALinkResponse, Error>) in
            switch result {
            case .success(let oneTimeAccessResponse):
                accessToken = oneTimeAccessResponse.accessToken
                completion(.success)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Requests a password reset link for the provided username.
    /// - Parameters:
    ///   - username: Username for which a password reset is being requested.
    ///   - completion: Completion handler with a ``ServiceCompletion`` result type.
    public static func requestResetPassword(username: String, completion: @escaping ServiceCompletion) {
        let endpoint = IdentityEndpoint.requestResetPassword(request: ResetPasswordEmailRequest(userName: username))

        NetworkManager.requestForCodable(from: endpoint) { (result: Result<EmailSentSuccessResponse, Error>) in
            switch result {
            case .success(let emailSent):
                if emailSent.success {
                    completion(.success)
                } else {
                    completion(.failure(SubscriptionsError.userAccountError(reason: .failedToSendEmail)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Redeem the nonce provided by the reset password action.
    /// - Parameters:
    ///   - nonce: The nonce assocaited with the user's request for password reset.
    ///   - newPassword: The new password to use when logging the user in.
    ///   - completion: Completion handler with a ``ServiceCompletion`` result type
    public static func resetPassword(nonce: String, newPassword: String, completion: @escaping ServiceCompletion) {
        let endpoint = IdentityEndpoint.resetPassword(nonceString: nonce, request: ResetPasswordRequest(newPassword: newPassword))

        NetworkManager.requestForCodable(from: endpoint) { (result: Result<PasswordResetResponse, Error>) in
            switch result {
            case .success(_):
                completion(.success)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Updates the user's account with the provided new password.
    /// - Parameters:
    ///   - oldPassword: The existing password on the user's account.
    ///   - newPassword: The new password to update the user's account with.
    ///   - completion: Completion handler with a ``ServiceCompletion`` result type.
    public static func updatePassword(oldPassword: String, newPassword: String, completion: @escaping ServiceCompletion) {

        guard let accessToken = accessToken else {
            completion(.failure(SubscriptionsError.userAccountError(reason: .noAccessTokenAvailable)))
            return
        }

        guard validateAccessToken(accessToken: accessToken) else {
            extendUserSession { result in
                switch result {
                case .success:
                    updatePassword(oldPassword: oldPassword, newPassword: newPassword, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            return
        }

        let endpoint = IdentityEndpoint.updateLoginPassword(request: UpdatePasswordRequest(oldPassword: oldPassword, newPassword: newPassword))

        NetworkManager.requestForCodable(from: endpoint) { (result: Result<PasswordResetResponse, Error>) in
            switch result {
            case .success(_):
                completion(.success)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Returns the current access token.
    /// - parameter completion: Completion handler, returning a JWT token if successfuly.
    public static func getAccessToken(completion: @escaping (Result<JWT, Error>) -> Void) {

        guard let accessToken = accessToken else {
            completion(.failure(SubscriptionsError.userAccountError(reason: .noAccessTokenAvailable)))
            return
        }

        guard validateAccessToken(accessToken: accessToken) else {
            extendUserSession { result in
                switch result {
                case .success:
                    getAccessToken(completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            return
        }

        do {
            let token = try DecodedJWT(jwt: accessToken)
            completion(.success(token))
        } catch {
            completion(.failure(error))
        }
    }

    /// Fetch tentant configuration.
    /// - Parameter completion: Completion handler returning config options if successful.
    public static func getConfig(completion: @escaping (Result<ConfigOptions, Error>) -> Void) {
        let endpoint = IdentityEndpoint.config
        NetworkManager.requestForCodable(from: endpoint) { (result: Result<ConfigOptions, Error>) in
            switch result {
            case .success(let configOptions):
                Subscriptions.configOptions = configOptions
                completion(.success(configOptions))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Fetch the current user based on the user's saved access token. If no access token is available, a failure will be returned.
    /// If the user's access token has expired, and "Remember Me" was turned on, the user's session will be refreshed.
    /// If the user's access token has expired, and "Remember Me" was turned off, a failure will be returned.
    /// When a failure is returned, the user must manually log in again.
    /// - parameter completion: Reports whether the user login was successful or not, and if not, provides an error description.
    public static func fetchUserProfile(completion: UserCompletion?) {
        guard let accessToken = accessToken else {
            completion?(.failure(SubscriptionsError.userAccountError(reason: .noAccessTokenAvailable)))
            return
        }
        guard validateAccessToken(accessToken: accessToken) else {
            extendUserSession { result in
                switch result {
                case .success:
                    fetchUserProfile(completion: completion)
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            return
        }

        NetworkManager.requestForCodable(from: IdentityEndpoint.profile) { (result: Result<UserProfile, Error>) in
            switch result {
            case .success(let userProfile):
                saveUserProfileData(userProfile)
                guard let currentUser = Subscriptions.cachedUserProfile else {
                    completion?(.failure(SubscriptionsError.userAccountError(reason: .currentUserNotAvailable)))
                    return
                }
                completion?(.success(currentUser))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    /// Extend user session using the cached refresh token and update the access token with the latest ones received from server.
    ///   - parameter completion: Completion handler with a ``ServiceCompletion`` result type.
    public static func extendUserSession(completion: @escaping ServiceCompletion) {
        guard let refreshToken = refreshToken else {
            completion(.failure(SubscriptionsError.userAccountError(reason: .currentUserNotAvailable)))
            return
        }

        let endpoint = IdentityEndpoint.extendUserSession(request: ExtendSessionRequest(token: refreshToken))

        NetworkManager.requestForCodable(from: endpoint) { (result: Result<ExtendedUserSessionResponse, Error>) in
            switch result {
            case .success(let extendedUserSession):
                storeTokens(accessToken: extendedUserSession.accessToken, refreshToken: extendedUserSession.refreshToken)
                completion(.success)
            case .failure(let error):
                Subscriptions.logOut()
                completion(.failure(error))
            }
        }
    }

    /// Request deletion of the current user's account.
    ///   - parameter completion: Completion handler with a ``ServiceCompletion`` result type
    public static func requestDeleteAccount(completion: @escaping ServiceCompletion) {
        NetworkManager.requestForCodable(from: IdentityEndpoint.requestDeleteAccount) { (result: Result<AccountDeletionResponse, Error>) in
            handleAccountDeletionResult(result, completion)
        }
    }

    /// Redeems the nonce provided by the account deletion request, and confirms the deletion action.
    /// - Parameters:
    ///   - nonce: The nonce provided by the account deletion request.
    ///   - completion: Completion handler with a ``ServiceCompletion`` result type.
    public static func approveDeleteAccount(_ nonce: String, completion: @escaping ServiceCompletion) {
        let accountDeletionApproveEndpoint = IdentityEndpoint.approveDeleteAccount(nonce: nonce)
        NetworkManager.requestForCodable(from: accountDeletionApproveEndpoint) { (result: Result<AccountDeletionResponse, Error>) in
            handleAccountDeletionResult(result, completion)
        }
    }

    /// Redeems the nonce provided by the account deletion request, and cancels/declines the account deletion access.
    /// - Parameters:
    ///   - nonce: nonce that was communicated to the user
    ///   - reason: ``DeletionDeclineReason`` object mentioning the details of the reason to decline
    ///   - completion: Completion handler with a ``ServiceCompletion`` Result type
    public static func declineDeleteAccount(_ nonce: String, _ reason: DeletionDeclineReason, completion: @escaping ServiceCompletion) {
        let request = DeclineDeleteAccountRequest(reason: reason.rawValue, notes: reason.notes)
        let accountDeletionDeclineEndpoint = IdentityEndpoint.declineDeleteAccount(nonce: nonce, request: request)
        NetworkManager.requestForCodable(from: accountDeletionDeclineEndpoint) { (result: Result<AccountDeletionResponse, Error>) in
            handleAccountDeletionResult(result, completion)
        }
    }
}

extension Subscriptions.Identity {

    /// Stores the provided user data.
    /// - Parameters:
    ///     - userSignupResponse: The data structure containing the user data to be stored.
    private static func storeUserData(_ userSignupResponse: UserAuthResponse, completion: UserCompletion? = nil) {

        // Store Commerce web API tokens.
        storeTokens(accessToken: userSignupResponse.accessToken, refreshToken: userSignupResponse.refreshToken)
        // Setup paywall rules and entitlements.
        PaywallManager.setup()

        // Fetch the user profile from the backend if available.
        fetchUserProfile { userResult in
            let userProfile: UserProfile
            switch userResult {
            case .success(let backendUserProfile):
                userProfile = backendUserProfile
            case .failure:
                // No backend profile available, but this may be a common scenario after sign up.
                // Continue as normal with a locally created version.
                userProfile = UserProfile()
            }

            // Store related details along with user profile.
            userProfile.uuid = userSignupResponse.uuid
            userProfile.identities = userSignupResponse.identities
            userProfile.accessToken = userSignupResponse.accessToken // are these two lines of code necessary?
            userProfile.refreshToken = userSignupResponse.refreshToken
            Subscriptions.cachedUserProfile = userProfile

            completion?(.success(userProfile))
        }
    }

    /// Saves the user profile data to the ``currentUser``.
    /// - parameter userProfile: The user profile data to be saved.
    private static func saveUserProfileData(_ userProfile: UserProfile) {
        Subscriptions.cachedUserProfile = userProfile
    }

    /// Handles account deletion using the provided result and completion handler.
    /// - Parameters:
    ///     - result: The result containing the ``AccountDeletionResponse``.
    ///     - completion: The completion handler which will handle both successful and failed results.
    private static func handleAccountDeletionResult(_ result: Result<AccountDeletionResponse, Error>, _ completion: ServiceCompletion) {
        switch result {
        case .success(let response):
            guard response.valid else {
                completion(.failure(SubscriptionsError.userAccountError(reason: .unexpectedResult)))
                return
            }
            completion(.success)
        case .failure(let error):
            completion(.failure(error))
        }
    }

}

// MARK: - Access Token

extension Subscriptions.Identity {
    /// Checks if the user access token is valid.
    /// - returns: True if it is valid, false otherwise.
    static func validateAccessToken(accessToken: String) -> Bool {
        if Subscriptions.mock.mockNetworkResponseEnabled { return true }

        do {
            let token = try DecodedJWT(jwt: accessToken)
            return !token.expired
        } catch {
            devPrint("Commerce: Error occured while validating access token. Error: \(error)")
            return false
        }
    }
}

// MARK: - Convenience Methods

extension Subscriptions.Identity {
    /// Stores the provided access and refresh tokens.
    /// - Parameters:
    ///    - accessToken: The access token to store.
    ///    - refreshToken: The refresh token to store.
    private static func storeTokens(accessToken: String?, refreshToken: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
// swiftlint: enable file_length
