//
//  SignUpViewController.swift
//  ArcXPSDKSample
//
//  Created by Cassandra Balbuena on 7/31/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import UIKit
import ArcXP

/// A view that displays the sign up flow.
class SignUpViewController: LogInViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var rememberMeSwitch: UISwitch!

    var userSignUpModel = UserProfile()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sign Up"
    }

    /// Once the sign up button is tapped, the information the user entered is used to sign up.
    @IBAction func signUpButtonTapped(_ sender: Any) {
        guard let username = usernameTextField.text, !username.isEmpty,
              let emailAddress = emailTextField.text, !emailAddress.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            presentAlert(title: "Sign Up Error", message: "Please fill in each text field.")
            return
        }

        userSignUpModel.setUp(withRequiredFields: username, password: password, email: emailAddress)

        Subscriptions.Identity.signUp(user: userSignUpModel, rememberMe: rememberMeSwitch.isOn) { [weak self] result in
            switch result {
            case .success:
                self?.dismiss(animated: true) { self?.logInDelegate?.didCompleteLogIn() }
                self?.logInDelegate?.didCompleteLogIn()
            case .failure(let error):
                print("An error occured during sign up. Error: \(error)")
                self?.logInDelegate?.didFailLogIn(error)
                self?.presentAlert(title: "Sign Up Error", message: error.localizedDescription)
            }
        }
    }
}
