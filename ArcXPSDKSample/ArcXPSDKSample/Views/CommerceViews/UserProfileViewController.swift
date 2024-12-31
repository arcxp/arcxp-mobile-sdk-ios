//
//  UserProfileViewController.swift
//  ArcXPSDKSample
//
//  Created by Cassandra Balbuena on 7/31/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import UIKit
import ArcXP
import GoogleSignIn

/// A view that displays the ``currentUser``'s ``UserProfile``.
class UserProfileViewController: UIViewController {

    // MARK: Properties

    private let userProfileTableViewCellID = "UserProfileTableViewCell"
    /// The flag to determine if editing is enabled or not.
    private var editingEnabled = false
    private var cancelButton: UIBarButtonItem! // Initialized in viewDidLoad()

    /// A value provided by an outside source, with deep linking,
    var nonce: Nonce?

    // MARK: IBOutlets

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private var editButton: UIBarButtonItem!

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "User Profile"
        tableView.delegate = self
        tableView.dataSource = self
        registerTableViewCells()

        // Set up Cancel button
        let cancelButton = UIBarButtonItem(title: "Cancel",
                                           style: .plain,
                                           target: self,
                                           action: #selector(cancelButtonPressed))
        cancelButton.tintColor = .red
        self.cancelButton = cancelButton
    }

    override func viewDidAppear(_ animated: Bool) {
        if Subscriptions.cachedUserProfile == nil {
            // nonce will have a only when accessed from external links
            // such as onetime access email/password reset email

            if let nonce = nonce {
                // The app was launched with a nonce.
                switch nonce.type {
                case .oneTimeAccess:
                    redeemOneTimeAccessNonceUsingMagicLink(nonceValue: nonce.value)
                case .resetPassword:
                    redeemPasswordResetNonce(nonceValue: nonce.value)
                case .deleteAccount:
                    promptAccountDeletion(nonceValue: nonce.value)
                }
            } else {
                Subscriptions.isLoggedIn { [weak self] isLoggedIn in
                    if isLoggedIn {
                        self?.fetchCurrentUserDetails()
                    } else {
                        self?.showLoginFlow()
                    }
                }
            }

        } else {
            // Also check for account deletion while the user is logged in and the current user is available.
            if let nonce = nonce, case .deleteAccount = nonce.type {
                promptAccountDeletion(nonceValue: nonce.value)
            } else {
                fetchCurrentUserDetails()
            }
        }
    }

    // MARK: - Button Actions

    /// Once the ``editButton`` is tapped, if editing is enabled, the profile updates are committed.
    @IBAction func editButtonTapped(_ sender: Any) {

        if editingEnabled {
            // Done button pressed.
            commitUserProfileUpdates()
            navigationItem.leftBarButtonItem = nil

        } else {
            // Edit button pressed.
            navigationItem.leftBarButtonItem = cancelButton
        }

        editingEnabled = editingEnabled ? false : true
        editButton.title = editingEnabled ? "Done" : "Edit"
        tableView.reloadData()
    }

    /// Once the ``cancelButton`` is pressed, the queue that holds the updates is cleared.
    @objc private func cancelButtonPressed() {
        Subscriptions.Identity.clearQueuedUserUpdates()
        editingEnabled = editingEnabled ? false : true
        editButton.title = editingEnabled ? "Done" : "Edit"
        navigationItem.leftBarButtonItem = nil
        tableView.reloadData()
    }

    // MARK: - Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        // Set up view controller for contact or address updates.
        if let detailedFieldViewController = segue.destination as? DetailedFieldViewController {
            detailedFieldViewController.delegate = self

            switch sender as? String {
            case "Contact":
                detailedFieldViewController.detailedField = .contact(Subscriptions.cachedUserProfile?.contacts?.first)
            case "Address":
                detailedFieldViewController.detailedField = .address(Subscriptions.cachedUserProfile?.addresses?.first)
            case "Attribute":
                detailedFieldViewController.detailedField = .attribute(
                    Subscriptions.cachedUserProfile?.attributes?.first)
            default:
                return
            }
        }
    }

    // MARK: - Convenience Methods

    /// Makes the queued user profile updates permament by making a network call to send them to the Commerce backend.
    private func commitUserProfileUpdates() {
        let commitFailure: ((Error) -> Void) = { [weak self] error in
            var errorMessage = error.localizedDescription
            if let error = error as? SubscriptionsError,
               case let .URLRequestError(reason: reason) = error,
               case let .badRequest( _, _, message) = reason {
                errorMessage = message
            }

            self?.presentAlert(title: "Failed to update User Profile",
                         message: errorMessage,
                         affirmativeActonTitle: "OK") { _ in
                self?.fetchCurrentUserDetails()
            }
        }

        Subscriptions.Identity.commitUserProfileUpdates { [weak self] result in
            if case let .failure(error) = result {
                // Failed to commit user profile updates.
                commitFailure(error)
            } else {
                // Successfully saved user profile updates.
                self?.tableView.reloadData()
                self?.presentAlert(title: "User Profile Updated",
                                   message: "Successfully updated this user's profile!")
            }
        }
    }

    /// Fetches the ``UserProfile`` of the ``currentUser``
    private func fetchCurrentUserDetails() {
        // Current user not loaded in yet. Get the current user if possible.
        Subscriptions.Identity.fetchUserProfile { [weak self] result in
            switch result {
            case .success:
                self?.tableView.reloadData()
            case .failure(let error):
                if Subscriptions.cachedUserProfile == nil {
                    // Could not fetch user profile, and no profile exists in the local cache. Force user to login.
                    print("There was an error while attempting to get user profile. Error:\(error.localizedDescription)")
                    self?.showLoginFlow()
                }
            }
        }
    }

    /// Redeems the one time access link ``nonce`` from the external links.
    /// - Parameters:
    ///     - nonceValue: The string form of the ``nonce``.
    private func redeemOneTimeAccessNonceUsingMagicLink(nonceValue: String) {
        Subscriptions.Identity.redeemOneTimeAccessLink(nonce: nonceValue) { [weak self] result in
            self?.nonce = nil
            switch result {
            case .success:
                self?.fetchCurrentUserDetails()
            case .failure(let error):
                print("Error while redeeming nonce. Error: \(String(describing: error))")
                self?.showLoginFlow()
            }
        }
    }

    /// Redeems the password reset ``nonce`` from the external links.
    /// - Parameters:
    ///     - nonceValue: The string form of the ``nonce``.
    private func redeemPasswordResetNonce(nonceValue: String) {
        let alert = UIAlertController(title: "Password Reset", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Enter your new password"
        }
        let sendEmail = UIAlertAction(title: "Reset", style: .default) { _ in
            let textField = alert.textFields![0] as UITextField
            guard let newPassword = textField.text, !newPassword.isEmpty else {
                return
            }
            Subscriptions.Identity.resetPassword(nonce: nonceValue, newPassword: newPassword) { [weak self] result in
                self?.nonce = nil
                switch result {
                case .success:
                    self?.presentAlert(title: "Reset success", message: "Your password has been succesfully reset")
                case .failure(let error):
                    var errorMessage = error.localizedDescription
                    if let urlRequestError = error as? SubscriptionsError {
                        switch urlRequestError {
                        case .URLRequestError(reason: .unauthorizedError( _, _, let message)),
                             .URLRequestError(reason: .badRequest( _, _, let message)):
                            errorMessage = message
                        default:
                            break
                        }
                    }
                    self?.presentAlert(title: "Reset Failure", message: errorMessage)
                }
            }
        }

        alert.addAction(sendEmail)
        present(alert, animated: true)
    }

    /// Displays prompts to the user for the account deletion process. If they choose to delete their account
    /// , the ``nonceValue`` is used to redeem the ``nonce`` for account deletion.
    /// - Parameters:
    ///     - nonceValue: The string form of the ``nonce``.
    private func promptAccountDeletion(nonceValue: String) {

        let deleteAccountAlert = UIAlertController(title: "Confirm Account Deletion",
                                                   message: "Would you like to delete your account?",
                                                   preferredStyle: .alert)

        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            self?.redeemAccountDeletion(nonceValue, approved: true)
            self?.nonce = nil
        }

        let noAction = UIAlertAction(title: "No", style: .cancel) { [weak self] _ in
            let deletionDeclineReasonsActionSheet = UIAlertController(title: "Pick a reason",
                                                               message: "Why are you not deleting your account?",
                                                               preferredStyle: .actionSheet)
            deletionDeclineReasonsActionSheet.addAction(UIAlertAction(title: "Mistake", style: .default) { _ in
                self?.redeemAccountDeletion(nonceValue, reason: .mistake, approved: false)
                self?.nonce = nil
            })

            deletionDeclineReasonsActionSheet.addAction(UIAlertAction(title: "Changed Mind", style: .default) { _ in
                self?.redeemAccountDeletion(nonceValue, reason: .changedMind, approved: false)
                self?.nonce = nil
            })

            deletionDeclineReasonsActionSheet.addAction(UIAlertAction(title: "Other", style: .default) { _ in
                self?.redeemAccountDeletion(nonceValue, reason: .other, approved: false)
                self?.nonce = nil
            })

            self?.present(deletionDeclineReasonsActionSheet, animated: true)
        }

        deleteAccountAlert.addAction(yesAction)
        deleteAccountAlert.addAction(noAction)

        present(deleteAccountAlert, animated: true)
    }

    /// Redeems the account deletion ``nonce`` from the external links.
    /// - Parameters:
    ///     - nonceValue: The string form of the ``nonce``.
    private func redeemAccountDeletion(_ nonce: String, reason: DeletionDeclineReason? = nil, approved: Bool) {

        if approved {
            Subscriptions.Identity.approveDeleteAccount(nonce) { [weak self] result in
                switch result {
                case .success:
                    print("Successfully approved account deletion.")
                    self?.nonce = nil
                    Subscriptions.logOut()
                    self?.tableView.reloadData()
                case .failure(let error):
                    print("There was a problem while redeeming account deletion nonce with approval. Error: \(error)")
                }
            }

        } else {
            guard let reason = reason else {
                presentAlert(title: "Account deletion error.",
                             message: "There was a problem getting the reason for account deletion cancellation.")
                return
            }

            Subscriptions.Identity.declineDeleteAccount(nonce, reason) { [weak self] result in
                switch result {
                case .success:
                    print("Successfully declined account deletion.")
                    self?.nonce = nil
                case .failure(let error):
                    print("There was a problem while redeeming account deletion nonce with decline. Error: \(error)")
                }
            }
        }
    }

    private func registerTableViewCells() {
        let userProfileTableViewCell = UINib(nibName: userProfileTableViewCellID, bundle: nil)
        tableView.register(userProfileTableViewCell, forCellReuseIdentifier: userProfileTableViewCellID)
    }

    /// Presents the user with the user login interface.
    private func showLoginFlow() {
        let storyboard = UIStoryboard(name: "Commerce", bundle: nil)
        let loginOptionsViewController = storyboard.instantiateViewController(
            identifier: "LogInFlow") as LogInOptionsViewController
        loginOptionsViewController.logInDelegate = self

        loginOptionsViewController.loginCompletion = {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }

//        let navigationController = UINavigationController(rootViewController: loginOptionsViewController)
//        navigationController.modalPresentationStyle = .fullScreen
//
//        present(navigationController, animated: true)
        self.navigationController?.pushViewController(loginOptionsViewController, animated: true)
    }

    /// Presents the user a user interface to enter any edits they choose to make to the ``UserProfile``.
    /// - Parameters:
    ///     - field: The field that is being edited in the ``UserProfile``.
    private func showEditStringFieldAlert(_ field: String, completion: @escaping (_ newValue: String) -> Void) {

        let editStringAlert = UIAlertController(title: "Edit \(field)",
                                                message: "Enter a new value for \(field)",
                                                preferredStyle: .alert)
        var textField: UITextField?

        editStringAlert.addTextField {
            $0.placeholder = "Enter new \(field)"
            textField = $0
        }

        let doneAction = UIAlertAction(title: "Done", style: .default) { [textField] _ in
            guard let newValue = textField?.text, newValue != "" else { print("No text was entered."); return }
            completion(newValue)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        editStringAlert.addAction(doneAction)
        editStringAlert.addAction(cancelAction)

        present(editStringAlert, animated: true)
    }
}

// MARK: - Table View Delegation

extension UserProfileViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        // Sections - User profile, Update password, Logout
        return Subscriptions.cachedUserProfile != nil ? 3 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if section == 0 {
            // General user data
            return Subscriptions.cachedUserProfile == nil ? 1 : 10
        } else if section == 1 {
            // // Log out
            return 1
        } else if section == 2 {
            // paywall
            return 1
        } else {
            print("Tableview attempted to poulate with unexpected scope. Section: \(section)")
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let section = indexPath.section

        if section == 0 {
            // User account details section.
            guard let currentUser = Subscriptions.cachedUserProfile else {
                // User must log in.
                let logInCell = UITableViewCell()
                logInCell.textLabel?.text = "Log In"
                navigationItem.rightBarButtonItem = nil
                return logInCell
            }

            navigationItem.rightBarButtonItem = editButton

            guard let userProfileTableViewCell = tableView.dequeueReusableCell(
                withIdentifier: userProfileTableViewCellID) as? UserProfileTableViewCell else {
                print("UserProfileTableViewCell failed to dequeue")
                return UITableViewCell()
            }

            userProfileTableViewCell.prepareForReuse()
            userProfileTableViewCell.backgroundColor = .white

            switch indexPath.row {

            case 0:
                let editedValue = Subscriptions.Identity.queueUserProfileUpdate(.email(nil))
                userProfileTableViewCell.set(description: "Email",
                                             value: editedValue["email"] as? String
                                             ?? (currentUser.email ?? "N/A"))

            case 1:
                let editedValue = Subscriptions.Identity.queueUserProfileUpdate(.firstName(nil))
                userProfileTableViewCell.set(description: "First name",
                                             value: editedValue["firstName"] as? String
                                             ?? (currentUser.firstName ?? "N/A"))

            case 2:
                let editedValue = Subscriptions.Identity.queueUserProfileUpdate(.lastName(nil))
                userProfileTableViewCell.set(description: "Last name",
                                             value: editedValue["lastName"] as? String
                                             ?? (currentUser.lastName ?? "N/A"))

            case 3:
                let editedValue = Subscriptions.Identity.queueUserProfileUpdate(.displayName(nil))
                userProfileTableViewCell.set(description: "Display name",
                                             value: editedValue["displayName"] as? String
                                             ?? (currentUser.displayName ?? "N/A"))

            case 4:
                let editedValue = Subscriptions.Identity.queueUserProfileUpdate(.gender(nil))
                userProfileTableViewCell.set(description: "Gender",
                                             value: editedValue["gender"] as? String ??
                                             (currentUser.gender?.string ?? "N/A"))

            case 5:
                let falseMessage = "False - Logging in again may not be possible"
                let message: String
                if let verified = currentUser.emailVerified {
                    message = verified ? "True" : falseMessage
                    if !verified {
                        userProfileTableViewCell.backgroundColor = UIColor(red: 1, green: 225/255,
                                                                           blue: 225/255, alpha: 1)
                    }
                } else {
                    // No verified value found. Assume the user's email is not verified.
                    message = falseMessage
                    userProfileTableViewCell.backgroundColor = UIColor(red: 1, green: 225/255, blue: 225/255, alpha: 1)
                }
                userProfileTableViewCell.set(description: "Email verified", value: message)

            case 6:
                let cell = UITableViewCell()

                if let contact = currentUser.contacts?.first {
                    // Show first contact number
                    cell.textLabel?.text = "Contact: \(contact.phoneNumber)"
                } else {
                    // Show empty contact, and indicate functionality for adding contact
                    cell.textLabel?.text = editingEnabled ? "Add new contact" : "Contact: N/A"
                }

                cell.accessoryType = .disclosureIndicator
                return cell

            case 7:
                let cell = UITableViewCell()

                if let address = currentUser.addresses?.first {
                    cell.textLabel?.text = "Address: \(address.line1)"
                } else {
                    cell.textLabel?.text = editingEnabled ? "Add new address" : "Address: N/A"
                }

                cell.accessoryType = .disclosureIndicator

                return cell

            case 8:
                let cell = UITableViewCell()

                if let attr = currentUser.attributes?.first {
                    // Show first contact number
                    cell.textLabel?.text = "Attribute: \(attr.name): \(attr.value)"
                } else {
                    // Show empty contact, and indicate functionality for adding contact
                    cell.textLabel?.text = editingEnabled ? "Add attribute" : "Attribute: N/A"
                }

                cell.accessoryType = .disclosureIndicator
                return cell

            case 9:
                // Social accounts
                let cell = UITableViewCell()
                guard let identities = currentUser.identities else {
                cell.textLabel?.text = "Error: Identities not available"; return cell }
                cell.textLabel?.text = "Identities: \(identities.count)"
                cell.accessoryType = .disclosureIndicator
                return cell

            default:
                break
            }

            if indexPath.row != 9, indexPath.row != 5 {
                userProfileTableViewCell.accessoryType = editingEnabled ? .disclosureIndicator : .none }

            return userProfileTableViewCell

        } else if section == 1 {
            let cell = UITableViewCell()

            switch indexPath.row {

            case 0:
                cell.textLabel?.text = "Log Out"
                cell.textLabel?.textColor = .red
                return cell
            default:
                cell.textLabel?.text = "Table view populated with an unexpected range."
                return cell
            }
        } else if section == 2 {
            let cell = UITableViewCell()
            cell.textLabel?.text = "Paywall"
            cell.textLabel?.textColor = .blue
            return cell
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 {

            if indexPath.row == 0 && Subscriptions.cachedUserProfile == nil {
                // Log in selected.
                showLoginFlow()
                return
            }

            guard editingEnabled || indexPath.row >= 6 else { return }

            switch indexPath.row {

            case 0:
                let field = "email"
                showEditStringFieldAlert(field) { newString in
                    Subscriptions.Identity.queueUserProfileUpdate(.email(newString))
                    tableView.reloadData()
                }

            case 1:
                let field = "first name"
                showEditStringFieldAlert(field) { newString in
                    Subscriptions.Identity.queueUserProfileUpdate(.firstName(newString))
                    tableView.reloadData()
                }

            case 2:
                let field = "last name"
                showEditStringFieldAlert(field) { newString in
                    Subscriptions.Identity.queueUserProfileUpdate(.lastName(newString))
                    tableView.reloadData()
                }

            case 3:
                let field = "display name"
                showEditStringFieldAlert(field) { newString in
                    Subscriptions.Identity.queueUserProfileUpdate(.displayName(newString))
                    tableView.reloadData()
                }
            case 4:
                selectGenderWithAlert()

            case 6:
                performSegue(withIdentifier: "DetailedFieldSegue", sender: "Contact")

            case 7:
                performSegue(withIdentifier: "DetailedFieldSegue", sender: "Address")

            case 8:
                performSegue(withIdentifier: "DetailedFieldSegue", sender: "Attribute")

            case 9:
                navigationController?.show(UserIdentitiesViewController(), sender: self)
                return

            default:
                return
            }

        } else if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                Subscriptions.logOut()
                GIDSignIn.sharedInstance.signOut()
                tableView.reloadData()
                showLoginFlow()
            default:
                break
            }
        } else if indexPath.section == 2 {
            let storyboard = UIStoryboard(name: "Paywall", bundle: nil)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "Paywall") as? UINavigationController else {
                fatalError("Unable to instantiate view controller with identifier 'UserProfileViewController'")
            }
            self.show(viewController, sender: self)
        }
    }
    // swiftlint:enable function_body_length
    // swiftlint:enable cyclomatic_complexity

    /// Presents the user with a user interface to select the gender for the ``UserProfile``.
    func selectGenderWithAlert() {
        let width = UIScreen.main.bounds.width - 20
        let height = UIScreen.main.bounds.height/2

        let pickerVC = UIViewController()
        pickerVC .preferredContentSize = CGSize(width: width, height: height)
        let pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        pickerView.dataSource = self
        pickerView.delegate = self

        pickerVC .view.addSubview(pickerView)
        pickerView.centerXAnchor.constraint(equalTo: pickerVC.view.centerXAnchor).isActive = true
        pickerView.centerYAnchor.constraint(equalTo: pickerVC.view.centerYAnchor).isActive = true

        let alert = UIAlertController(title: "Select Gender", message: nil, preferredStyle: .actionSheet)
        alert.setValue(pickerVC, forKey: "contentViewController")

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        let selectAction = UIAlertAction(title: "Select", style: .default) { [weak self] _ in
            let row = pickerView.selectedRow(inComponent: 0)
            let selection = UserProfile.Gender.allCases[row]
            Subscriptions.Identity.queueUserProfileUpdate(.gender(selection))
            self?.tableView.reloadData()
        }
        alert.addAction(selectAction)

        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = self.view
            presenter.sourceRect = CGRect(x: self.view.bounds.minX, y: self.view.bounds.minY, width: 0, height: 0)
        }

        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Log In Delegate

extension UserProfileViewController: LogInDelegate {

    func didCompleteLogIn() {
        // This is happening through a delegate call because
        // the view lifecycle is not triggered when the modal login flow is dismissed.
        self.navigationController?.popToRootViewController(animated: true)
        tableView.reloadData()
    }
}

// MARK: - Detailed Field View Controller Delegate

extension UserProfileViewController: DetailedFieldViewControllerDelegate {

    func didCompleteUpdate() {
        navigationController?.popViewController(animated: true)

        Subscriptions.Identity.fetchUserProfile { [weak self] _ in
            self?.tableView.reloadData()
        }
    }
}

extension UserProfileViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return UserProfile.Gender.allCases.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return UserProfile.Gender.allCases[row].rawValue
    }
}
