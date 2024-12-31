//
//  Taxonomy.swift
//  ArcXPContent
//
//  Created by Davis, Tyler on 1/21/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation
// swiftlint: disable nesting
public struct ANSSection: Codable {

    public struct Parent: Codable {
        enum CodingKeys: String, CodingKey {
            case name = "default"
        }
        public var name: String?
    }

    public struct Ancestors: Codable {
        enum CodingKeys: String, CodingKey {
            case ancestors = "default"
            case mobile
        }
        public var ancestors: [String]?
        public var mobile: [String]?
    }

    public struct AdditionalProperties: Codable {
        enum CodingKeys: String, CodingKey {
            case sectionData = "original"
        }
        public var sectionData: SectionData?
    }

    public struct SectionData: Codable {

        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case nodeType
            case website = "_website"

            case ancestors
            case inactive
            case name
        }

        public var ancestors: Ancestors?
        public var id: String?
        public var inactive: Bool?
        public var name: String?
        public var nodeType: String?
        public var parent: Parent?
        public var website: String?
    }

    enum CodingKeys: String, CodingKey {
        case additionalProperties
        case id = "_id"
        case parentId
        case website = "_website"
        case websiteSectionId = "_website_section_id"

        case description
        case name
        case parent
        case path
        case primary
        case type
        case version
    }

    public var additionalProperties: ANSSection.AdditionalProperties?
    public let description: String?
    public var id: String?
    public var name: String?
    public var parent: Parent?
    public var parentId: String?
    public var path: String?
    public var primary: Bool?
    public let type: String?
    public var version: String?
    public var website: String?
    public var websiteSectionId: String?
}
// swiftlint: enable nesting
