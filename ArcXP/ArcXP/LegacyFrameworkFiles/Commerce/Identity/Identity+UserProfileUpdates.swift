//
//  Identity+UserProfileUpdates.swift
//  Commerce
//
//  Created by Davis, Tyler on 5/28/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation
// swiftlint: disable nesting
public extension Subscriptions.Identity {

    /// Fields in the user's profile that are allowed to be edited, as opposed to those managed by the Commerce backend.
    enum EditableUserProfileField {
        case firstName(_ value: String?)
        case lastName(_ value: String?)
        case secondLastName(_ value: String?)
        case displayName(_ value: String?)
        case gender(_ value: UserProfile.Gender?)
        case email(_ value: String?)
        case picture(_ value: URL?)
        case birthYear(_ value: Int?)
        case birthMonth(_ value: Int?)
        case birthDay(_ value: Int?)
        case contacts(_ value: [UserProfile.Contact]?)
        case addresses(_ value: [UserProfile.Address]?)
        case attributes(_ value: [UserProfile.Attribute]?)

        fileprivate var dataKey: String {
            switch self {
            case .firstName: return "firstName"
            case .lastName: return "lastName"
            case .secondLastName: return "secondLastName"
            case .displayName: return "displayName"
            case .gender: return "gender"
            case .email: return "email"
            case .picture: return "picture"
            case .birthYear: return "birthYear"
            case .birthMonth: return "birthMonth"
            case .birthDay: return "birthDay"
            case .contacts: return "contacts"
            case .addresses: return "addresses"
            case .attributes: return "attributes"
            }
        }

        fileprivate var associatedValue: Encodable {
            switch self {
            case .firstName(let firstName):
                return firstName

            case .lastName(let lastName):
                return lastName

            case .secondLastName(let secondLastName):
                return secondLastName

            case .displayName(let displayName):
                return displayName

            case .email(let email):
                return email

            case .birthDay(let birthDay):
                return birthDay

            case .birthYear(let birthYear):
                return birthYear

            case .birthMonth(let birthMonth):
                return birthMonth

            case .gender(let gender):
                return gender

            case .picture(let imageURL):
                return imageURL?.absoluteURL

            case .addresses(let addresses):
                return addresses

            case .contacts(let contacts):
                return contacts

            case .attributes(let attributes):
                return attributes
            }
        }

        public struct Address {
            public enum AddressType: String { case work, home, primary, other }
            public let lineOne: String
            public let lineTwo: String = ""
            public let city: String // Locality
            public let state: String // Region
            public let zipCode: String // Postal
            public let country: String
            public let type: AddressType = .other
        }

        public struct Contact {

            public enum ContactType: String { case work, home, primary, other }

            public let phone: String
            public var type: ContactType = .other

            public init(phone: String, type: ContactType = .other) {
                self.phone = phone
                self.type = type
            }
        }
    }

    /// Queue up a new value to update on the current user's User Profile.
    /// - parameter newValue: The new values that should be updated in the user profile.
    /// - returns: A collection of the currently queued user profile updates.
    @discardableResult static func queueUserProfileUpdate(_ newValue: EditableUserProfileField) -> [String: Any] {
        queuedUserProfileUpdates[newValue.dataKey] = newValue.associatedValue
        return queuedUserProfileUpdates
    }

    /// Clears the queued user profile updates.
    static func clearQueuedUserUpdates() {
        queuedUserProfileUpdates = [String: Encodable]()
    }
}
// swiftlint: enable nesting
