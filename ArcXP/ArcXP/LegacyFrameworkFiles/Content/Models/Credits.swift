//
//  Credits.swift
//  ContentExample
//
//  Created by Davis, Tyler on 1/21/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation

/// ANS base url - https://github.com/washingtonpost/ans-schema/blob/master/src/main/resources/schema/ans/0.10.9/

/// Path - traits/trait_credits.json
public struct Credits: Codable {

    enum CodingKeys: String, CodingKey {
        case authors = "by"
    }

    public var authors: [Author]?

}

/// Object representing an author of the content.
public struct Author: Codable {
// swiftlint: disable nesting
    public struct AdditionalProperties: Codable {
        enum CodingKeys: String, CodingKey {
            case authorData = "original"
        }
        public var authorData: AuthorData?
    }
// swiftlint: enable nesting
    enum CodingKeys: String, CodingKey {
        case additionalProperties
        case id = "_id"
        case socialLinks

        case description
        case name
        case org
        case slug
        case type
        case url
    }

    public var additionalProperties: Author.AdditionalProperties?
    public var id: String?
    public var type: String?
    public var name: String?
    public var org: String?
    public var description: String?
    public var url: String?
    public var slug: String?
    public var socialLinks: [Social]?

}

/// Object to represent the metadata associated with the author.
public struct AuthorData: Codable {
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case bioPage
        case lastUpdated
        case lastUpdatedDate

        case bio
        case byline
        case firstName
        case lastName
        case email
        case role
        case location
        case image
        case division
        case slug
        case expertise
        case books
        case education
        case awards
        case longBio
        case podcasts
        case contributor
    }

    public var id: String?
    public var bio: String?
    public var bioPage: String?
    public var byline: String?
    public var firstName: String?
    public var lastName: String?
    public var email: String?
    public var role: String?
    public var location: String?
    public var image: String?
    public var division: String?
    public var slug: String?
    public var expertise: String?
    public var books: [Book]?
    public var education: [Education]?
    public var awards: [Award]?
    public var longBio: String?
    public var podcasts: [Podcast]?
    public var lastUpdated: String?
    public var lastUpdatedDate: String?
    public var contributor: Bool?
}

/// Object representing the education data of the author.
public struct Education: Codable {
    public var schoolName: String?
    public var name: String?
}

/// Object representing the award data of the author.
public struct Award: Codable {
    public var awardName: String?
    public var name: String?
}

/// Object representing the book data of the author.
public struct Book: Codable {
    public var bookTitle: String?
    public var bookUrl: String?
}

/// Object representing the podcast data of the author.
public struct Podcast: Codable {
    public var name: String?
    public var url: String?
    public var downloadUrl: String?
}

/// Object representing the social media data of the author.
public struct Social: Codable {
    public var site: String?
    public var url: String?
}
