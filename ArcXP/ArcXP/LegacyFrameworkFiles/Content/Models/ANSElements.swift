//
//  ANSElements.swift
//  ArcXPContent
//
//  Created by Mahesh Venkateswarlu on 2/1/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation

/// Base url for ans ref link - https://github.com/washingtonpost/ans-schema/blob/master/src/main/resources/schema/ans/0.10.9/

/// Path --> traits/trait_description.json
public struct Description: Codable {
    public let basic: String
}

/// Path --> traits/trait_headlines.json
public struct Headlines: Codable {
    public let basic: String?
    public let mobile: String?
    public let web: String?
    public let native: String?
    public let tablet: String?
}

/// Path --> traits/trait_subheadlines.json
public struct Subheadlines: Codable {
    public let basic: String?
}

/// Path --> traits/trait_address.json
public struct Address: Codable {
    public var postOfficeBox: String?
    public var extendedAddress: String?
    public var streetAdress: String?
    public var locality: String?
    public var region: String?
    public var postalCode: String?
    public var countryName: String?
}

/// Path --> traits/trait_comments.json
public struct Comments: Codable {
    public var commentsPeriod: Int?
    public var allowComments: Bool?
    public var displayComments: Bool?
    public var moderationRequired: Bool?
}

/// Path --> traits/trait_content_restrictions.json
public struct ContentRestrictions: Codable {
    public var contentCode: String?
}

/// Path --> traits/trait_contributors.json
public struct Contributor: Codable {
    public var userId: String?
    public var displayName: String?
}

/// Path --> traits/trait_distributor.json
public struct Distributor: Codable {
    public var name: String?
    public var category: String?
    public var subcategory: String?
    public var mode: String?
    public var referenceId: String?
}

/// Path --> traits/trait_geo.json
public struct Geo: Codable {
    public var latitude: Double?
    public var longitude: Double?
}

/// Path --> traits/trait_label.json
public struct Label: Codable {
    public var text: String?
    public var url: String?
    public var display: Bool?
}

public struct PromoImage: Codable {
    public let type: String?
    public let version: String?
    public let credits: Credits?
    public let caption: String?
    public let url: String?
    public let width: Int?
    public let height: Int?
    private let auth: [String: String]?
    /// Resized Image url that fits the device size
    public var resizedImageUrl: String? {
        return ArcXPImageResizer.resizedImageUrl(originalImageSize: CGSize(width: width ?? 0,
                                                                             height: height ?? 0),
                                                   originalUrl: url,
                                                   auth: auth)
    }
}

/// Path --> traits/trait_owner.json
public struct Owner: Codable {
    public var id: String?
    public var name: String?
    public var sponsored: Bool?
}

/// Path --> traits/trait_rendering_guides.json
public struct RenderingGuide: Codable {
    public var preferredMethod: [String]?
}

/// Path --> traits/trait_revision.json
public struct Revision: Codable {
    public var published: Bool?
    public var userId: String?
}

/// Path --> traits/trait_source.json
public struct Source: Codable {

    public enum CodingKeys: String, CodingKey {
        case system
        case editUrl
        case name
        case sourceType
        case sourceId
        case additionalProperties
    }

    public var system: String?
    public var editUrl: String?
    public var name: String?
    public var sourceType: String?
    public var sourceId: String?
    public var additionalProperties: [String: String]?
}

/// Path --> traits/trait_syndication.json
public struct Syndication: Codable {
    public var externalDistribution: Bool?
    public var search: Bool?
}

/// Path --> traits/trait_taxonomy.json
public struct Taxonomy: Codable {
    public var primarySection: ANSSection?
    public var sections: [ANSSection]?
    public var seoKeywords: [String]?
    public var tags: [Tag]?

    public struct Tag: Codable {
        public var description: String?
        public var slug: String?
        public var text: String?
    }
}

// Path --> traits/trait_comments.json
// ToDo - Add references to the author data
public struct VanityCredits: Codable {

    enum CodingKeys: String, CodingKey {
        case primaryAuthors = "by"
        case photographers = "photos_by"
    }

    public var primaryAuthors: [AuthorData]?
    public var photographers: [AuthorData]?
}

/// Path --> traits/trait_voice_transcripts.json.json
public struct VoiceTranscript: Codable {

    public enum CodingKeys: String, CodingKey {
        case id = "_id"
        case type
        case subtype
        case options
        case optionsUsed
    }

    public var id: String?
    public var type: String?
    public var subtype: String?
    public var options: Options?
    public var optionsUsed: Options?

    public struct Options: Codable {
        public var enabled: Bool?
        public var voiceId: String?
    }
}

/// Path --> traits/trait_websites.json
public struct Website: Codable {
    public var websiteSection: ANSSection?
    public var websiteUrl: String?
}

/// Path --> traits/trait_workflow.json
public struct Workflow: Codable {
    public var statusCode: Int?
    public var note: String?
}

public struct MediaStream: Codable {
    public let height: Int?
    public let width: Int?
    public let filesize: Int?
    public let streamType: String?
    public let url: String?
    public let bitrate: Int?
    public let provider: String?
}

public struct Subtitles: Codable {
    struct SubtitleFormat: Codable {
        /// The type of subtitle. The only one that we use right now is `WEB_VTT`.
        var format: String

        /// The URL of the associated `.VTT` file.
        var url: String

    }
    var urls: [SubtitleFormat]?
}
