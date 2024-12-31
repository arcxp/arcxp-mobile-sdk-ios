//
//  LoginViewController.swift
//  ArcXPSDKSample
//
//  Created by Cassandra Balbuena on 7/29/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import UIKit
import ArcXP
import ReCaptcha

public class LogInViewController: UIViewController {
    weak var logInDelegate: LogInDelegate?
}

/// A view that displays the login flow for Commerce.
class CommerceLogInViewController: LogInViewController {
    var recaptcha: ReCaptcha?

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var rememberSwitch: UISwitch!
    var configOptions: ConfigOptions?

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        Subscriptions.Identity.getConfig { result in
            switch result {
            case .success(let configOptions):
                DispatchQueue.main.async {
                    self.configOptions = configOptions
                    self.initializeRecaptcha(siteKey: configOptions.recaptchaSiteKey)
                }
            case .failure(let error):
                print("Error while fetching the tenant configuration = \(error.localizedDescription)")
            }
        }
    }

    // MARK: - User Interaction

    /// Once the button is pressed, the information the user entered is used to login.
    @IBAction func didTapLogInButton(_ sender: Any) {

        guard let username = usernameTextField.text,
              let password = passwordTextField.text,
              username != "" && password != "" else {
            presentAlert(title: "Missing Details", message: "Please enter a username and password.")
            return
        }

        if let configOptions = configOptions, configOptions.signinRecaptcha {
            recaptcha?.validate(on: view) { [weak self] (result: ReCaptchaResult) in
                guard let token = try? result.dematerialize() else { return }
                self?.logIn(with: username, password: password, reCaptchaToken: token)
            }
        } else {
            logIn(with: username, password: password)
        }
    }

    // MARK: - Convenience Methods

    /// Creates the ``recaptcha`` from the provided ``siteKey``.
    /// - Parameters:
    ///     - siteKey: The api key used to create the ``recaptcha``.
    func initializeRecaptcha(siteKey: String) {
        // This key is derived from Mahesh's account only for temp.
        // Use the org recaptachaSiteKey and domain(RECAPTCHA_SITE_KEY_DOMAIN) used to create the reCAPTCHA
        recaptcha = try? ReCaptcha(apiKey: siteKey,
                                   baseURL: URL(string: "https://RECAPTCHA_SITE_KEY_DOMAIN"))
        self.recaptcha?.configureWebView { [weak self] webview in
            webview.frame = self?.view.bounds ?? CGRect.zero
        }
    }

    /// Logs into Commerce using the provided information.
    /// - Parameters:
    ///     - username: The username to login with.
    ///     - password: The password to login with.
    func logIn(with username: String, password: String, reCaptchaToken: String? = nil) {

        Subscriptions.Identity.logIn(username: username,
                                password: password,
                                rememberMe: rememberSwitch.isOn,
                                reCaptchaToken: reCaptchaToken) { [weak self] result in
            switch result {

            case .success:
                DispatchQueue.main.async {
                    self?.dismiss(animated: true) {
                        self?.logInDelegate?.didCompleteLogIn()
                    }
                }

            case .failure(let error):
                var errorMessage = "Failed login attempt."
                if let urlRequestError = (error as? SubscriptionsError) {
                    if case let .URLRequestError( .unauthorizedError(_, _, message)) = urlRequestError {
                        errorMessage = message
                    }
                }
                self?.presentAlert(title: "Failed to Log In", message: errorMessage)
            }
        }
    }
}

extension Date {
    /// The time interval in milliseconds.
    var currentMilliseconds: Int64 {
        return Int64((self.timeIntervalSince1970 * 1000).rounded())
    }
}
