//
//  DetailedFieldViewController.swift
//  ArcXPSDKSample
//
//  Created by Cassandra Balbuena on 7/31/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import UIKit
import ArcXP

typealias CommerceContact = UserProfile.Contact
typealias CommerceAddress = UserProfile.Address
typealias CommerceAttribute = UserProfile.Attribute

protocol DetailedFieldViewControllerDelegate: AnyObject {
    func didCompleteUpdate()
    func didAddDetailedField(_ detailedField: DetailedField)
}

extension DetailedFieldViewControllerDelegate {
    func didAddDetailedField(_ detailedField: DetailedField) {
        return
    }

    func didCompleteUpdate() { return }
}

/// Represents either a ``CommerceContact``, ``CommerceAddress``, or a ``CommerceAttribute``.
enum DetailedField {
    case contact(_ contact: CommerceContact? = nil)
    case address(_ address: CommerceAddress? = nil)
    case attribute(_ attribute: CommerceAttribute? = nil)
}

/// A view that displays editible fields part of a ``DetailedField``.
class DetailedFieldViewController: UIViewController {

    // MARK: Properties

    var detailedField: DetailedField!
    var doneButton: UIBarButtonItem!
    weak var delegate: DetailedFieldViewControllerDelegate?

    var excessContactFields: [UITextField] {
        return [textField3,
                textField4,
                textField5,
                textField6,
                textField7]
    }

    // MARK: IBOutlets

    @IBOutlet weak var textField1: UITextField!
    @IBOutlet weak var textField2: UITextField!
    @IBOutlet weak var textField3: UITextField!
    @IBOutlet weak var textField4: UITextField!
    @IBOutlet weak var textField5: UITextField!
    @IBOutlet weak var textField6: UITextField!
    @IBOutlet weak var textField7: UITextField!

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up done button.
        self.doneButton = UIBarButtonItem(title: "Done",
                                          style: .done,
                                          target: self,
                                          action: #selector(finishedEditingField))
        navigationItem.rightBarButtonItem = doneButton

        // Update for specific field.
        switch detailedField {

        case .address(let address):
            setUpForAddress(address)

        case .contact(let contact):
            setUpForContact(contact)

        case .attribute(let attribute):
            setUpForAttribute(attribute)

        case .none:
            break
        }
    }

    // MARK: - Convenience Methods

    /// Sets up the view if the user chose a ``CommerceContact`` to edit.
    private func setUpForContact(_ contact: CommerceContact?) {
        title = contact == nil ? "New Contact" : "Update Contact"

        // Hide text fields that won't be used for contacts.
        for excessField in excessContactFields {
            excessField.isHidden = true
        }

        // Set up for new contact.
        textField1.placeholder = "Phone number"
        textField2.placeholder = "WORK, HOME, PRIMARY, OTHER"

        if let contact = contact {
            // Set up for existing contact.
            textField1.text = contact.phoneNumber
            textField2.text = contact.type?.rawValue ?? ""
            doneButton.title = "Update"
        } else {
            doneButton.title = "Save"
        }
    }

    /// Sets up the view if the user chose a ``CommerceAddress`` to edit.
    private func setUpForAddress(_ address: CommerceAddress?) {
        title = address == nil ? "New Address" : "Update Address"

        textField1.placeholder = "Address line 1"
        textField2.placeholder = "Address line 2"
        textField3.placeholder = "City"
        textField4.placeholder = "State"
        textField5.placeholder = "Zip code"
        textField6.placeholder = "Country"
        textField7.placeholder = "Type: WORK, HOME, PRIMARY, OTHER"

        if let address = address {
            // Set up for existing address.
            textField1.text = address.line1
            textField2.text = address.line2
            textField3.text = address.city
            textField4.text = address.state
            textField5.text = address.zip
            textField6.text = address.country
            textField7.text = address.type.rawValue
            doneButton.title = "Update"
        } else {
            doneButton.title = "Save"
        }
    }

    /// Sets up the view if the user chose a ``CommerceAttribute`` to edit.
    private func setUpForAttribute(_ attribute: CommerceAttribute?) {
        title = attribute == nil ? "New Attribute" : "Update Attribute"

        // Hide text fields that won't be used for attributes.
        for excessField in excessContactFields {
            if excessField == textField3 {
                continue
            }
            excessField.isHidden = true
        }

        textField1.placeholder = "Name or 'key'"
        textField2.placeholder = "Value"
        textField3.placeholder = "Type (String, Number, Date, Boolean)"

        if let attribute = attribute {
            // Set up for existing address.
            textField1.text = attribute.name
            textField2.text = attribute.value
            textField3.text = attribute.type?.rawValue
            doneButton.title = "Update"
        } else {
            doneButton.title = "Save"
        }
    }

    /// Commits the update to the ``DetailedField``.
    private func commitProfileUpdate() {
        Subscriptions.Identity.commitUserProfileUpdates { [weak self] result in
            switch result {
            case .success:
                self?.delegate?.didCompleteUpdate()
            case .failure(let error):
                print("There was a problem saving the attribute . Error: \(error.localizedDescription)")
                self?.presentAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }

    // swiftlint:disable function_body_length
    @objc private func finishedEditingField() {
        switch detailedField {

        case .contact:

            guard let phoneNumber = textField1.text,
                  phoneNumber != "" else {
                print("Failed to access phone number while attempting to update contact.")
                return
            }

            let contactTypeString = textField2.text?.uppercased() ?? "OTHER"

            let contactType = UserProfile.Contact.ContactType(rawValue: contactTypeString)
            let contact = UserProfile.Contact(phoneNumber: phoneNumber,
                                               type: contactType)
            if let signUpFieldsViewController = delegate as? SignUpFieldsViewController {
                // if the delegate is the SignUpFieldsVC, pass back the contact then return
                signUpFieldsViewController.didAddDetailedField(DetailedField.contact(contact))
                return
            }

            // Delegate is UserProfileViewController
            presentAlert(title: "Commit Changes?",
                         message: "Are you sure you'd like to save these contact changes? Updates will be saved immediately.",
                         affirmativeActonTitle: "Yes",
                         showCancelAction: true) { _ in
                /*
                 NOTE: While only one contact is being set here, multiple contacts can be saved to the user's account.
                 If you'd like to preserve previously added contacts, they must be provided in this `queueUserProfileUpdate` call as well.
                 */

                Subscriptions.Identity.queueUserProfileUpdate(.contacts([contact]))
                self.commitProfileUpdate()
            }

        case .address:

            // Grab the text field string data
            guard let line1 = textField1.text,
                  let city = textField3.text else {
                print("Missing data from address fields.")
                return
            }

            let line2 = textField2.text == "" ? nil : textField2.text
            let state = textField4.text == "" ? nil : textField4.text
            let postalCode = textField5.text == "" ? nil : textField5.text
            let country = textField6.text == "" ? nil : textField6.text
            let type = textField7.text?.uppercased() ?? "OTHER"
            let addressType = UserProfile.Address.AddressType(rawValue: type)
            let address = UserProfile.Address(line1: line1,
                                              line2: line2,
                                              city: city,
                                              state: state,
                                              zip: postalCode,
                                              country: country,
                                              type: addressType)

            if let signUpFieldsViewController = delegate as? SignUpFieldsViewController {
                // if the delegate is the SignUpFieldsVC, pass back the address then return
                signUpFieldsViewController.didAddDetailedField(DetailedField.address(address))
                return
            }
            
            presentAlert(title: "Commit Changes?",
                         message: "Are you sure you'd like to save these address changes? Updates will be saved immediately.",
                         affirmativeActonTitle: "Yes",
                         showCancelAction: true) { _ in
                Subscriptions.Identity.queueUserProfileUpdate(.addresses([address]))
                self.commitProfileUpdate()
            }

        case .attribute:

            // Grab the text field string data
            guard let name = textField1.text,
                  let value = textField2.text else {
                return
            }

            let attrType = textField3.text?.capitalized ?? "String"
            let attribute = UserProfile.Attribute(name: name, value: value, type: attrType)

            if let signUpFieldsViewController = delegate as? SignUpFieldsViewController {
                // if the delegate is the SignUpFieldsVC, pass back the attribute then return
                signUpFieldsViewController.didAddDetailedField(DetailedField.attribute(attribute))
                return
            }

            presentAlert(title: "Commit Changes?",
                         message: "Are you sure you'd like to save these attribute changes? Updates will be saved immediately.",
                         affirmativeActonTitle: "Yes",
                         showCancelAction: true) { _ in
                Subscriptions.Identity.queueUserProfileUpdate(.attributes([attribute]))
                self.commitProfileUpdate()
            }

        case .none:
            return
        }
    }
    // swiftlint:enable function_body_length
}
