//
//  StoryContentElements.swift
//  ArcXPContent
//
//  Created by Mahesh Venkateswarlu on 2/2/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation
// swiftlint: disable file_length nesting
/// All the content elements for a Story are defined here and the ANS schemes are referred from - \
///  https://github.com/washingtonpost/ans-schema/tree/master/src/main/resources/schema/ans/0.10.9/story_elements
public struct TextContentElement: ContentElement {

    public static var contentType = ContentType.text

    public enum CodingKeys: String, CodingKey {
        case id = "_id"
        case content
        case type
        case subtype
        case channels
        case alignment
    }

    public var id: String?
    public var content: String?
    public var type: String?
    public let subtype: String?
    public let channels: [String]?
    public let alignment: String?
}

public struct OembedResponseContentElement: ContentElement {

    public static var contentType = ContentType.oembed_response

    public enum CodingKeys: String, CodingKey {
        case content
        case type
        case id = "_id"
        case rawOembed
        case subtype
        case referent
    }

    public var id: String?
    public var content: String?
    public var type: String?
    public let rawOembed: RawOembed?
    public let subtype: String?
    public let referent: Referent?

    public struct Referent: Codable {
        public let id: String?
        public let provider: String?
        public let service: String?
        public let type: String?
    }
}

public struct RawOembed: Codable {
    public let id: String?
    public let title: String?
    public let authorName: String?
    public let authorUrl: String?
    public let type: String?
    public let providerName: String?
    public let providerUrl: String?
    public let version: String?
    public let height: Int?
    public let width: Int?
    public let thumbnailHeight: Int?
    public let thumbnailWidth: Int?
    public let thumbnailUrl: String?
    public let html: String?

    public enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title
        case authorName
        case authorUrl
        case type
        case providerName
        case providerUrl
        case version
        case height
        case width
        case thumbnailHeight
        case thumbnailWidth
        case thumbnailUrl
        case html
    }
}

public struct QuoteContentElement: ContentElement {

    public static var contentType = ContentType.quote

    public enum CodingKeys: String, CodingKey {
        case id = "_id"
        case content
        case type
        case subtype
        case channels
        case alignment
        case citation
        case contentElements
    }

    public var id: String?
    public var content: String?
    public var type: String?
    public var subtype: String?
    public var channels: [String]?
    public var alignment: String?
    public var citation: TextContentElement?
    public var contentElements: [TextContentElement]?

}

public struct CodeContentElement: ContentElement {

    public static var contentType = ContentType.code

    public enum CodingKeys: String, CodingKey {
        case content
        case type
        case id = "_id"
        case subtype
        case channels
        case alignment
        case language
    }

    public var id: String?
    public var content: String?
    public var type: String?
    public let subtype: String?
    public let channels: [String]?
    public let alignment: String?
    public let language: String

}

public struct CustomEmbedContentElement: ContentElement {

    public static var contentType = ContentType.custom_embed

    public enum CodingKeys: String, CodingKey {
        case content
        case type
        case id = "_id"
        case subtype
        case channels
        case alignment
        case embed
        case additionalProperties
    }

    public var id: String?
    public var content: String?
    public var type: String?
    public let subtype: String?
    public let channels: [String]?
    public let alignment: String?
    public let embed: Embed?
    public let additionalProperties: CustomEmbedAdditionalProperties?

    public struct Embed: Codable {
        public let id: String
        public let url: String
        public let config: Config?

        public struct Config: Codable {
            public let contentType: String?
            public let created: String?
            public let duration: Int?
            public let isLiveContent: Bool?
            public let m3u8: String?
            public let mp4: String?
            public let resolution: String?
            public let thumbnail: String?
            public let title: String?
        }
    }

    public struct CustomEmbedAdditionalProperties: Codable {
        public var title: String?
        public var showTitle: Bool?
        public let assets: [Asset]?

        public struct Asset: Codable {
            public let id: String?
            public let newsType: String?
            public let favorite: Bool?
            public let assetType: String?
            public let reproducible: Bool?
            public let shareUrl: String?
            public let title: String?
            public let imageUrl: String?
            public let website: String?
            public let idArc: String?
            public let subtitle: String?
        }

    }
}

public struct CorrectionContentElement: ContentElement {

    public static var contentType = ContentType.correction

    public enum CodingKeys: String, CodingKey {
        case content
        case type
        case id = "_id"
        case subtype
        case channels
        case alignment
        case correctionType
        case text
    }

    public var id: String?
    public var content: String?
    public var type: String?
    public let subtype: String?
    public let channels: [String]?
    public let alignment: String?
    public let correctionType: String
    public let text: String
}

public struct EndorsementContentElement: ContentElement {

    public static var contentType = ContentType.endorsement

    public enum CodingKeys: String, CodingKey {
        case content
        case type
        case id = "_id"
        case subtype
        case channels
        case alignment
        case endorsement
    }

    public var id: String?
    public var content: String?
    public var type: String?
    public let subtype: String?
    public let channels: [String]?
    public let alignment: String?
    public let endorsement: String?
}

public struct HeaderContentElement: ContentElement {

    public static var contentType = ContentType.header

    public enum CodingKeys: String, CodingKey {
        case content
        case type
        case id = "_id"
        case subtype
        case channels
        case alignment
        case level
    }

    public var id: String?
    public var content: String?
    public var type: String?
    public let subtype: String?
    public let channels: [String]?
    public let alignment: String?
    public let level: Int?
}

public struct InterstitialLinkContentElement: ContentElement {

    public static var contentType = ContentType.interstitial_link

    public enum CodingKeys: String, CodingKey {
        case content
        case type
        case id = "_id"
        case subtype
        case channels
        case alignment
        case url
        case description
    }

    public var id: String?
    public var content: String?
    public var type: String?
    public let subtype: String?
    public let channels: [String]?
    public let alignment: String?
    public let url: String?
    public let description: String?
}

public struct ListContentElement: ContentElement {

    public static var contentType = ContentType.list

    public enum CodingKeys: String, CodingKey {
        case content
        case type
        case id = "_id"
        case subtype
        case channels
        case alignment
        case listType
        case items
    }

    public var id: String?
    public var content: String?
    public var type: String?
    public let subtype: String?
    public let channels: [String]?
    public let alignment: String?
    public let listType: String?
    public let items: [ListContentElement]?
}

public struct NumericRatingContentElement: ContentElement {

    public static var contentType = ContentType.numeric_rating

    public enum CodingKeys: String, CodingKey {
        case content
        case type
        case id = "_id"
        case subtype
        case channels
        case alignment
        case numericRating
        case min
        case max
        case units
    }

    public var id: String?
    public var content: String?
    public var type: String?
    public let subtype: String?
    public let channels: [String]?
    public let alignment: String?
    public let numericRating: Int?
    public let min: Int?
    public let max: Int?
    public let units: String?
}

public struct HtmlContentElement: ContentElement {

    public static var contentType = ContentType.html

    public enum CodingKeys: String, CodingKey {
        case id = "_id"
        case content
        case type
        case subtype
        case channels
        case alignment
    }

    public var id: String?
    public var content: String?
    public var type: String?
    public let subtype: String?
    public let channels: [String]?
    public let alignment: String?
}

public struct TableContentElement: ContentElement {

    public static var contentType = ContentType.quote

    public enum CodingKeys: String, CodingKey {
        case content
        case type
        case id = "_id"
        case subtype
        case channels
        case alignment
        case header
        case rows
    }

    public var id: String?
    public var content: String?
    public var type: String?
    public let subtype: String?
    public let channels: [String]?
    public let alignment: String?
    public let header: [TextContentElement]?
    public let rows: [[TextContentElement]]?
}

public struct GalleryContentElement: ContentElement {
    public static var contentType = ContentType.gallery

    public enum CodingKeys: String, CodingKey {
        case id = "_id"
        case type
        case content
        case additionalProperties
        case canonicalUrl
        case canonicalWebsite
        case createdDate
        case contentElements
        case description
        case displayDate
        case firstPublishDate
        case headlines
        case label
        case lastUpdatedDate
        case owner
        case promoItems
        case publishDate
        case source
        case taxonomy
        case websites
        case workflow
    }

    public var id: String?
    public var content: String?
    public var type: String?
    public let additionalProperties: ImageAdditionalProperties?
    public let canonicalUrl: String?
    public let canonicalWebsite: String?
    public let contentElements: [ImageContentElement]?
    public let createdDate: String?
    public let description: Description?
    public let displayDate: String?
    public let firstPublishDate: String?
    public let headlines: Headlines?
    public let label: [String: Label]?
    public let lastUpdatedDate: String?
    public let owner: Owner?
    public let promoItems: PromoItems?
    public let publishDate: String?
    public let source: Source?
    public let taxonomy: Taxonomy?
    public let websites: [String: Website]?
    public let workflow: Workflow?

    /// Resized Image url that fits the device size
    public var resizedImageUrl: String? {
        return (promoItems?.content as? ImageContentElement)?.resizedImageUrl
    }

    /// Resized Image url with thumbnail size
    public var resizedThumbnailImageUrl: String? {
        return (promoItems?.content as? ImageContentElement)?.resizedThumbnailImageUrl
    }
}

public struct VideoContentElement: ContentElement {
    public static var contentType = ContentType.video

    public enum CodingKeys: String, CodingKey {
        case id = "_id"
        case type
        case content
        case additionalProperties
        case canonicalUrl
        case canonicalWebsite
        case createdDate
        case credits
        case displayDate
        case distributor
        case duration
        case firstPublishDate
        case headlines
        case language
        case lastUpdatedDate
        case owner
        case promoItems
        case promoImage
        case publishDate
        case revision
        case shortUrl
        case source
        case streams
        case subtype
        case syndication
        case taxonomy
        case tracking
        case version
        case videoType
        case websites
        case workflow
    }

    public var id: String?
    public var content: String?
    public var type: String?
    public let additionalProperties: VideoAdditionalProperties?
    public let canonicalUrl: String?
    public let canonicalWebsite: String?
    public let createdDate: String?
    public let credits: Credits
    public let displayDate: String?
    public let distributor: Distributor?
    public let duration: Int
    public let firstPublishDate: String?
    public let headlines: Headlines?
    public let language: String?
    public let lastUpdatedDate: String?
    public let owner: Owner?
    public let promoItems: PromoItems?
    public let promoImage: PromoImage?
    public let publishDate: String?
    public let revision: Revision?
    public let shortUrl: String?
    public let source: Source?
    public let streams: [Stream]?
    public let subtype: String?
    public let syndication: Syndication?
    public let taxonomy: Taxonomy?
    public let tracking: [String: String]?
    public let version: String?
    public let videoType: String?
    public let websites: [String: Website]?
    public let workflow: Workflow?
}

public struct VideoAdditionalProperties: Codable {

    public enum CodingKeys: String, CodingKey {
        case id = "_id"
        case advertising
        case anglerfishArcId
        case disableUpNext
        case doNotShowTranscripts
        case embedContinuousPlay
        case firstPublishedBy
        case forceClosedCaptionsOn
        case gifAsThumbnail
        case isWire
        case lastPublishedBy
        case permalinkUrl
        case platform
        case playlist
        case playVideoAds
        case published
        case subsection
        case useVariants
        case vertical
        case videoAdZone
        case videoCategory
        case videoId
        case workflowStatus
    }
    public let id: String?
    public let advertising: Advertising?
    public let anglerfishArcId: String?
    public let disableUpNext: Bool?
    public let doNotShowTranscripts: Bool?
    public let embedContinuousPlay: Bool?
    public let firstPublishedBy: [String: String]?
    public let forceClosedCaptionsOn: Bool?
    public let gifAsThumbnail: Bool?
    public let isWire: Bool?
    public let lastPublishedBy: [String: String]?
    public let permalinkUrl: String?
    public let platform: String?
    public let playlist: String?
    public let playVideoAds: Bool?
    public let published: Bool?
    public let subsection: String?
    public let useVariants: Bool?
    public let vertical: Bool?
    public let videoAdZone: String?
    public let videoCategory: String?
    public let videoId: String?
    public let workflowStatus: String?

    public struct Advertising: Codable {
        public let allowPrerollOnDomain: Bool?
        public let autoPlayPreroll: Bool?
        public let commercialAdNode: String?
        public let enableAdInsertion: Bool?
        public let enableAutoPreview: Bool?
        public let forceAd: Bool?
        public let playAds: Bool?
        public let videoAdZone: String?
    }
}

public struct UnknownContentElement: ContentElement {
    public static var contentType = ContentType.unknown
    public enum CodingKeys: String, CodingKey {
        case id = "_id"
        case content
        case type
    }

    public var id: String?
    public var content: String?
    public var type: String?
}
// swiftlint: enable file_length nesting
