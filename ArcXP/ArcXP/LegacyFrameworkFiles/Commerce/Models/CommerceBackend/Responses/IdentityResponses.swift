//
//  IdentityResponses.swift
//  Commerce
//
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.

import Foundation
// swiftlint: disable file_length nesting
/// The user model that is fetched from the Commerce backend.
public struct UserAuthResponse: Codable {
    public let uuid: String
    public let identities: [ProfileIdentity]?
    public var profile: UserProfile?
    public let accessToken, refreshToken: String?
    public let existingSocialLogin: Bool?
}

public struct ProfileIdentity: Codable {
    public let userName: String
    public let passwordReset: Bool
    public let type: String
    let lastLoginDate: Int?
    public let locked: Bool
}

/// Describes a user's data, analogous to how it exists on the Commerce backend.
public class UserProfile: Codable {

    public var userName: String?
    public var password: String? // Passed in with Identity
    public var email: String? // required
    public var uuid: String? // Pased in response
    public var createdOn, modifiedOn, deletedOn: Int?
    public var firstName, lastName, secondLastName, displayName: String?
    public var gender: UserProfile.Gender?
    public var unverifiedEmail: String?
    public var imageUrlString: String?
    public var birthYear, birthMonth, birthDay: String?
    public var emailVerified: Bool?
    public var contacts: [UserProfile.Contact]?
    public var addresses: [UserProfile.Address]?
    public var attributes: [UserProfile.Attribute]?
    public var legacyID: String?
    public var status: String?
    public var identities: [ProfileIdentity]? {
        didSet {
            userName = identities?.first?.userName
        }
    }
    public var deletionRule: Int?
    public var accessToken: String?
    public var refreshToken: String?

    // swiftlint: disable line_length
    enum CodingKeys: String, CodingKey {
        case createdOn, modifiedOn, deletedOn, firstName, lastName, secondLastName, displayName, gender, email, unverifiedEmail, birthYear, birthMonth, birthDay, emailVerified, contacts, addresses, attributes, identities, status, deletionRule, uuid, userName, password
        case imageUrlString = "picture"
        case legacyID = "legacyId"
    }
    // swiftlint: enable line_length

    public enum Gender: String, Codable, CaseIterable {
        case male = "MALE"
        case female = "FEMALE"
        case nonConforming = "NON_CONFORMING"
        case preferNotToSay = "PREFER_NOT_TO_SAY"

        /// A user interface friendly string description of this gender.
        public var string: String {
            switch self {
            case .male:
                return "Male"
            case .female:
                return "Female"
            case .nonConforming:
                return "Non-conforming"
            case .preferNotToSay:
                return "Prefer-not-to-say"
            }
        }
    }

    /// A contact attached to a user profile.
    public struct Contact: Codable, Equatable {

        /**
         A contact has a type that can be:
         - Work
         - Home
         - Primary
         - Other
         */
        public enum ContactType: String, Codable {
            case work = "WORK"
            case home = "HOME"
            case primary = "PRIMARY"
            case other = "OTHER"
        }

        enum CodingKeys: String, CodingKey {
            case phoneNumber = "phone"
            case type
        }

        /// The phone number associated with the contact.
        public let phoneNumber: String
        /// The type of the contact.
        public var type: UserProfile.Contact.ContactType?

        public init(phoneNumber: String, type: UserProfile.Contact.ContactType? = .other) {
            self.phoneNumber = phoneNumber
            self.type = type
        }

        public static func == (lhs: UserProfile.Contact, rhs: UserProfile.Contact) -> Bool {
            guard lhs.type == rhs.type,
                  lhs.phoneNumber == rhs.phoneNumber else {
                return false
            }
            return true
        }
    }

    /// A key value object that the user can create and store in a user profile.
    public struct Attribute: Codable, Equatable {

        /**
         An attribute has a type that can be:
         - String
         - Number
         - ``Date``
         - Boolean
        */
        public enum AttributeType: String, Codable {
            case string = "String"
            case number = "Number"
            case date = "Date"
            case boolean = "Boolean"

            public init(from decoder: Decoder) throws {
                self = try AttributeType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .string
            }
        }

        /// The key property of the attribute.
        public let name: String
        /// The value property of the attribute.
        public let value: String
        /// The type of the attribute.
        public let type: AttributeType?

        public init(name: String, value: String, type: String) {
            self.name = name
            self.value = value
            self.type = AttributeType(rawValue: type) ?? .string
        }

        public static func == (lhs: UserProfile.Attribute, rhs: UserProfile.Attribute) -> Bool {
            guard lhs.name == rhs.name,
                  lhs.value == rhs.value,
                  lhs.type == rhs.type else {
                return false
            }
            return true
        }
    }

    /// An address attached to a user profile.
    public struct Address: Codable, Equatable {

        /**
         An address has a type that can be:
         - Work
         - Home
         - Primary
         - Other
        */
        public enum AddressType: String, Codable {
            case work = "WORK"
            case home = "HOME"
            case primary = "PRIMARY"
            case other = "OTHER"
        }

        enum CodingKeys: String, CodingKey {
            case city = "locality"
            case state = "region"
            case zip = "postal"

            case country
            case line1
            case line2
            case type
        }

        public let line1: String
        public let line2: String?
        /// Corresponds to locality in the Idenity backend.
        public let city: String
        /// Corresponds to region  in the Identity backend.
        public let state: String?
        /// Corresponds to postal in the Identity backend.
        public let zip: String?
        public let country: String?
        public var type: UserProfile.Address.AddressType

        public init(line1: String,
                    line2: String? = nil,
                    city: String,
                    state: String? = nil,
                    zip: String? = nil,
                    country: String? = nil,
                    type: AddressType? = nil) {
            self.line1 = line1
            self.line2 = line2 ?? " "
            self.city = city
            self.state = state
            self.zip = zip
            self.country = country
            self.type = type ?? .other
        }

        public static func == (lhs: UserProfile.Address, rhs: UserProfile.Address) -> Bool {
            guard lhs.line1 == rhs.line1,
                  lhs.line2 == rhs.line2,
                  lhs.city == rhs.city,
                  lhs.state == rhs.state,
                  lhs.zip == rhs.zip,
                  lhs.country == rhs.country,
                  lhs.type == rhs.type else {
                return false
            }
            return true
        }
    }

    public init(userName: String? = nil,
                password: String? = nil,
                email: String? = nil,
                uuid: String? = nil,
                createdOn: Int? = nil,
                modifiedOn: Int? = nil,
                deletedOn: Int? = nil,
                firstName: String? = nil,
                lastName: String? = nil,
                secondLastName: String? = nil,
                displayName: String? = nil,
                gender: UserProfile.Gender? = nil,
                unverifiedEmail: String? = nil,
                imageUrlString: String? = nil,
                birthYear: String? = nil,
                birthMonth: String? = nil,
                birthDay: String? = nil,
                emailVerified: Bool? = nil,
                contacts: [UserProfile.Contact]? = nil,
                addresses: [UserProfile.Address]? = nil,
                attributes: [UserProfile.Attribute]? = nil,
                legacyID: String? = nil,
                status: String? = nil,
                identities: [ProfileIdentity]? = nil,
                deletionRule: Int? = nil,
                accessToken: String? = nil,
                refreshToken: String? = nil) {
        self.userName = userName
        self.password = password
        self.email = email
        self.uuid = uuid
        self.createdOn = createdOn
        self.modifiedOn = modifiedOn
        self.deletedOn = deletedOn
        self.firstName = firstName
        self.lastName = lastName
        self.secondLastName = secondLastName
        self.displayName = displayName
        self.gender = gender
        self.unverifiedEmail = unverifiedEmail
        self.imageUrlString = imageUrlString
        self.birthYear = birthYear
        self.birthMonth = birthMonth
        self.birthDay = birthDay
        self.emailVerified = emailVerified
        self.contacts = contacts
        self.addresses = addresses
        self.attributes = attributes
        self.legacyID = legacyID
        self.status = status
        self.identities = identities
        self.deletionRule = deletionRule
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    /// Sets the required fields with the provided fields.
    /// - Parameters:
    ///     - username: The username the user will attempt to sign up with.
    ///     - password: The password the user will attempt to sign up with.
    ///     - email: The email the user will attempt to sign up with.
    public func setUp(withRequiredFields username: String, password: String, email: String) {
        self.userName = username
        self.password = password
        self.email = email
    }

    /// Adds a contact to the user profile's list of contacts.
    /// - Parameters:
    ///     - newContact: The contact to be added to the user profile.
    public func addContact(newContact: UserProfile.Contact) {
        if contacts == nil {
            contacts = [UserProfile.Contact]()
        }
        contacts?.append(newContact)
    }

    /// Adds an address to the user profile's list of addresses.
    /// - Parameters:
    ///     - newAddress: The address to be added to the user profile.
    public func addAddress(newAddress: UserProfile.Address) {
        if addresses == nil {
            addresses = [UserProfile.Address]()
        }
        addresses?.append(newAddress)
    }

    /// Adds an attribute to the user profile's list of attributes.
    /// - Parameters:
    ///     - newAttribute: The attribute to be added to the user profile,
    public func addAttribute(newAttribute: UserProfile.Attribute) {
        if attributes == nil {
            attributes = [UserProfile.Attribute]()
        }
        attributes?.append(newAttribute)
    }
}

/// Extend user session response.
struct ExtendedUserSessionResponse: Codable {
    let accessToken: String
    let refreshToken: String
}

/// One time access link response.
struct OTALinkResponse: Codable {
    let accessToken: String
}

/// Password reset response.
struct PasswordResetResponse: Codable {
    let userName: String
    let passwordReset: Bool
    let type: String
    let locked: Bool
    let lastLoginDate: Int?
}

/// User account deletion response.
struct AccountDeletionResponse: Codable {
    let valid: Bool
}

/// Email sent response.
struct EmailSentSuccessResponse: Codable {
    let success: Bool
}

/// Identity error response.
struct ErrorResponse: Codable {
    let httpStatus: Int
    let code: String
    let message: String
}

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }

    public func hash(into hasher: inout Hasher) {
        // required for Hashable
    }

}
// swiftlint: enable file_length nesting
