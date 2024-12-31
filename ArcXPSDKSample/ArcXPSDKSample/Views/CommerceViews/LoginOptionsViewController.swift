//
//  ViewController.swift
//  Example
//
//  Created by Seitz, David on 6/30/20.
//  Copyright © 2020 The Washington Post Company. All rights reserved.
//

import UIKit
import ArcXP

protocol LogInDelegate: AnyObject {
    func didCompleteLogIn()
    func didFailLogIn(_ error: Error)
}

extension LogInDelegate {
    func didFailLogIn(_ error: Error) { return }
}

/// A view that displays the different options a user can choose from once the application is running.
/// A user can choose to login via Commerce or a third party, or they can sign up if they do not have
/// an account.
class LogInOptionsViewController: LogInViewController {

    @IBOutlet weak var baseUrlTextField: UITextField!
    @IBOutlet weak var organizationTextField: UITextField!
    @IBOutlet weak var siteTextField: UITextField!
    @IBOutlet weak var environmentTextField: UITextField!

    var attemptCount = 0
    var loginCompletion: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Arc Commerce Example"
    }

    @IBAction func didTapUserProfileButton(_ sender: Any) {
        navigationController?.dismiss(animated: true)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // Check if alternative configuration values have been provided.
        let confirugationFields = [baseUrlTextField, organizationTextField, siteTextField, environmentTextField]
        var filledConfigurationFields = 0
        for field in confirugationFields {
            if (field?.text != nil) && (field?.text != "") { filledConfigurationFields += 1 }
        }

        if filledConfigurationFields > 0 && filledConfigurationFields < 4 {
            // Some configuration values have been provided, but not all. Display an alert requiring all configuration values.
            let missingFieldsAlert = UIAlertController(title: "Missing Configuration Values",
                                                       message: "The configuration values you provided are incomplete. Please fill in all fields, or make all fields empty for default test values.",
                                                       preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            missingFieldsAlert.addAction(okAction)
            present(missingFieldsAlert, animated: true)
            return false
        } else if filledConfigurationFields == 4, let serverEnv = ServerEnvironment(
            rawValue: environmentTextField.text!) {
            // The appropriate number of configuration values have been provided. Set up configuration with the provided values.
            // Note: Force-upwrap is being allowed here because the values have already been validated above.
            let arcConfiguration = SubscriptionsConfiguration(baseUrl: baseUrlTextField.text!,
                                                              organization: organizationTextField.text!,
                                                              environment: serverEnv,
                                                              site: siteTextField.text!)
            Services.configure(service: .subscriptions(arcConfiguration))
        }

        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "SignUpViewController", "LogInSegue", "ThirdPartyLoginSegue":
            if let loginVC = segue.destination as? LogInViewController { loginVC.logInDelegate = logInDelegate }
        default:
            print("Segue identifier isn't recognized.")
        }
    }
}
