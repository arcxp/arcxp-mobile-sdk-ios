//
//  SectionList.swift
//  ArcXPContent
//
//  Created by Cassandra Balbuena on 1/24/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation

/// A list of ``SectionListElement``s.
public typealias SectionList = [SectionListElement]

/// An object that represents a section.
public struct SectionListElement: Codable {
    public let id, name, website: String?
    public let parent: SectionListParent?
    public let ancestors: Ancestors?
    public let admin: Admin?
    public let inactive: Bool?
    public let nodeType: String?
    public let order: Order?
    public let children: [SectionListElement]?
    public let navigation: Navigation?
    public var title: String? {
        return navigation?.title ?? name
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case website = "_website"
        case parent, ancestors
        case admin = "_admin"
        case inactive
        case nodeType
        case navigation
        case order, children
    }
}

public struct Admin: Codable {
    public let aliasIDS: [String]?

    enum CodingKeys: String, CodingKey {
        case aliasIDS = "alias_ids"
    }
}

public struct Navigation: Codable {
    public let title: String?

    enum CodingKeys: String, CodingKey {
        case title = "navTitle"
    }
}

public struct Ancestors: Codable {
    public let defaultAncestors: [String]?
    public let mobile: [String]?

    enum CodingKeys: String, CodingKey {
        case defaultAncestors = "default"
        case mobile
    }
}

public struct Order: Codable {
    public let mobile: Int?
}

public struct SectionListParent: Codable {
    public let parentDefault, mobile: String?

    enum CodingKeys: String, CodingKey {
        case parentDefault = "default"
        case mobile
    }
}
