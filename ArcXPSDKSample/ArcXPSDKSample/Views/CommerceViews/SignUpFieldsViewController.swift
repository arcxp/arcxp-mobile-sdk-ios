//
//  SignUpFieldsViewController.swift
//  ArcXPSDKSample
//
//  Created by Cassandra Balbuena on 7/31/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import UIKit
import ArcXP

/// A view that displays the additional fields a user can sign up with that are not required for the sign up process.
class SignUpFieldsViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var secondLastNameTextField: UITextField!
    @IBOutlet weak var displayNameTextField: UITextField!
    @IBOutlet weak var genderPicker: UIPickerView!
    @IBOutlet weak var pictureURLTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var legacyIDTextField: UITextField!
    @IBOutlet weak var deletionRuleTextField: UITextField!
    var genderPickerData = [String]()
    var genderPickerSelection: String?
    var userGender: UserProfile.Gender?
    var birthday: [String]?
    var userSignUpModel: UserProfile?

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM d y"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        genderPickerData = ["Male", "Female", "Non Conforming", "Prefer not to say"]
        genderPicker.delegate = self
        genderPicker.dataSource = self

        NotificationCenter.default.addObserver(self,
                                                selector: #selector(keyboardWillShow(notification:)),
                                                name: UIResponder.keyboardWillShowNotification,
                                                object: nil)
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(keyboardWillHide(notification:)),
                                                name: UIResponder.keyboardWillHideNotification,
                                                object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateView()
    }

    /// Updates the view by populating the fields with data from the ``userSignUpModel``.
    func updateView() {
        guard let userModel = userSignUpModel else { return }

        firstNameTextField.text = userModel.firstName
        lastNameTextField.text = userModel.lastName
        secondLastNameTextField.text = userModel.secondLastName
        displayNameTextField.text = userModel.displayName

        genderPickerSelection = userModel.gender?.rawValue

        if let selection = genderPickerData.firstIndex(of: genderPickerSelection?.capitalized ?? "Male") {
            genderPicker.selectRow(selection, inComponent: 0, animated: false)
        }

        pictureURLTextField.text = userModel.imageUrlString

        if let birthMonth = userModel.birthMonth,
           let birthDay = userModel.birthDay,
           let birthYear = userModel.birthYear {
            birthday = []
            birthday?.append(birthMonth)
            birthday?.append(birthDay)
            birthday?.append(birthYear)

            if let birth = birthday?.joined(separator: " "),
                let date = SignUpFieldsViewController.dateFormatter.date(from: birth) {
                datePicker.setDate(date, animated: false)
            }
        }

        legacyIDTextField.text = userModel.legacyID

        if let deletionRule = userModel.deletionRule {
            deletionRuleTextField.text = "\(deletionRule)"
        }
    }

    /// Once the button is tapped, the data the user entered into the fields is saved and the user is directed back to the sign up view.
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        saveData()
        navigationController?.popViewController(animated: true)
    }

    /// Once the button is tapped, the data the user entered into the fields is saved to the ``userSignUpModel``.
    private func saveData() {
        guard let userModel = userSignUpModel else {
            return
        }

        if let firstname = firstNameTextField.optionalText() {
            userModel.firstName = firstname
        }

        if let lastname = lastNameTextField.optionalText() {
            userModel.lastName = lastname
        }

        if let secondLastName = secondLastNameTextField.optionalText() {
            userModel.secondLastName = secondLastName
        }

        if let displayName = displayNameTextField.optionalText() {
            userModel.displayName = displayName
        }

        userModel.gender = userGender

        if let pictureUrl = pictureURLTextField.optionalText() {
            userModel.imageUrlString = pictureUrl
        }

        userModel.birthYear = birthday?[2]
        userModel.birthMonth = birthday?[0]
        userModel.birthDay = birthday?[1]

        if let legacyId = legacyIDTextField.optionalText() {
            userModel.legacyID = legacyId
        }

        if let deletionRule = deletionRuleTextField.optionalText() {
            userModel.deletionRule = Int(deletionRule)
        }
    }

    @IBAction func dateSelected(_ sender: UIDatePicker) {
        let selectedDate = datePicker.date
        birthday = SignUpFieldsViewController.dateFormatter.string(from: selectedDate).components(separatedBy: " ")
    }

    /// Depending on what the user would like to add, they are presented with a view corresponding to their choice of
    /// adding a contact, address, or attribute.
    @IBAction func addContactAddressAttributeButtonPressed(_ sender: UIButton) {
        if sender.tag == 1 {
            performSegue(withIdentifier: "DetailedFieldSegue", sender: "Add Contact")
        } else if sender.tag == 2 {
            performSegue(withIdentifier: "DetailedFieldSegue", sender: "Add Address")
        } else if sender.tag == 3 {
            performSegue(withIdentifier: "DetailedFieldSegue", sender: "Add Attribute")
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        saveData()
        if let detailedFieldViewController = segue.destination as? DetailedFieldViewController {
            detailedFieldViewController.delegate = self

            if let id = sender as? String, id == "Add Contact" {
                detailedFieldViewController.detailedField = .contact(Subscriptions.cachedUserProfile?.contacts?.first)
            } else if let id = sender as? String, id == "Add Address" {
                detailedFieldViewController.detailedField = .address(Subscriptions.cachedUserProfile?.addresses?.first)
            } else if let id = sender as? String, id == "Add Attribute" {
                detailedFieldViewController.detailedField = .attribute(Subscriptions.cachedUserProfile?.attributes?.first)
            }
        }
    }
}

extension SignUpFieldsViewController {

    @objc func keyboardWillShow(notification: Notification) {
        let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue

        let kbSize = value?.cgRectValue ?? CGRect.zero

        let insets = UIEdgeInsets(top: 0, left: 0, bottom: kbSize.height, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }

    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
}

extension SignUpFieldsViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1

        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }

        return true
    }

}

// MARK: - UIPickerView Delegate/Datasource

extension SignUpFieldsViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return genderPickerData.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return genderPickerData[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let genderPickerSelection = genderPickerData[row].replacingOccurrences(of: " ", with: "_").uppercased()
        userGender = UserProfile.Gender(rawValue: genderPickerSelection)
    }
}

// MARK: - Detailed Field View Controller Delegate

extension SignUpFieldsViewController: DetailedFieldViewControllerDelegate {
    func didAddDetailedField(_ detailedField: DetailedField) {
        switch detailedField {
        case .address(let newAddress):
            if let address = newAddress {
                userSignUpModel?.addAddress(newAddress: address)
            }
        case .contact(let newContact):
            if let contact = newContact {
                userSignUpModel?.addContact(newContact: contact)
            }
        case .attribute(let newAttribute):
            if let attribute = newAttribute {
                userSignUpModel?.addAttribute(newAttribute: attribute)
            }
        }
        navigationController?.popViewController(animated: true)
    }
}

extension UITextField {
    func optionalText() -> String? {
        if let someText = text, !someText.isEmpty {
            return someText
        }

        return nil
    }
}
