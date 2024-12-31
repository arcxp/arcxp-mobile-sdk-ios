//
//  ArcXPContent.swift
//  ArcXPContent
//
//  Created by Davis, Tyler on 1/18/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation

/// The type of the ``ArcXPContent``.
public enum ArcXPContentType: String, Codable {
    case gallery
    case story
    case video
}

public typealias ArcXPContentList = [ArcXPContent]

/// This ANSObject (for now) is based on
/// https://github.com/washingtonpost/ans-schema/blob/master/src/main/resources/schema/ans/0.10.9/story.json
/// We will have to make it conform to video and gallery or create children types
public struct ArcXPContent: Codable {

    enum CodingKeys: String, CodingKey {
        case identifier = "_id"
        case address
        case alignment
        case canonicalUrl
        case canonicalWebsite
        case channels
        case comments
        case contentAliases
        case contentElements
        case contentRestrictions
        case contributors
        case copyright
        case createdDate
        case credits
        case description
        case displayDate
        case distributor
        case editorNote
        case firstPublishDate
        case geo
        case headlines
        case label
        case language
        case lastUpdatedDate
        case location
        case owner
        case promoItems
        case publishDate
        case renderingGuides
        case revision
        case shortUrl
        case slug
        case source
        case status
        case subheadlines
        case subtype
        case syndication
        case taxonomy
        case type
        case vanityCredits
        case version
        case voiceTranscripts
        case workflow
        case websites
        case websiteUrl
        case streams
        case subtitles
        case videoType
    }

    public var identifier: String?
    public var type: ArcXPContentType
    public var address: Address?
    public var alignment: String?
    public var canonicalUrl: String?
    public var canonicalWebsite: String?
    public var channels: [String]?
    public var comments: Comments?
    public var contentAliases: [String]?
    public var contentElements: [ContentElement]?
    public var contentRestrictions: ContentRestrictions?
    public var contributors: Contributor?
    public var copyright: String?
    public var createdDate: String?
    public var credits: Credits?
    public var description: Description?
    public var displayDate: String?
    public var distributor: Distributor?
    public var editorNote: String?
    public var firstPublishDate: String?
    public var geo: Geo?
    public var headlines: Headlines?
    public var label: [String: Label]?
    public var language: String?
    public var lastUpdatedDate: String?
    public var location: String?
    public var owner: Owner?
    public var promoItems: PromoItems?
    public var publishDate: String?
    public var renderingGuides: RenderingGuide?
    public var revision: Revision?
    public var shortUrl: String?
    public var slug: String?
    public var source: Source?
    public var status: String?
    public var subheadlines: Subheadlines?
    public var subtype: String?
    public var syndication: Syndication?
    public var taxonomy: Taxonomy?
    public var vanityCredits: VanityCredits?
    public var version: String?
    public var voiceTranscripts: [VoiceTranscript]?
    public var websites: [String: Website]?
    public var websiteUrl: String?
    public var workflow: Workflow?
    public let streams: [MediaStream]?
    public let subtitles: Subtitles?
    public let videoType: String?

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(contentElements?.map({ AnyContentElement($0) }), forKey: .contentElements)
        try container.encodeIfPresent(identifier, forKey: .identifier)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(alignment, forKey: .alignment)
        try container.encodeIfPresent(canonicalUrl, forKey: .canonicalUrl)
        try container.encodeIfPresent(canonicalWebsite, forKey: .canonicalWebsite)
        try container.encodeIfPresent(channels, forKey: .channels)
        try container.encodeIfPresent(comments, forKey: .comments)
        try container.encodeIfPresent(contentAliases, forKey: .contentAliases)
        try container.encodeIfPresent(contentRestrictions, forKey: .contentRestrictions)
        try container.encodeIfPresent(contributors, forKey: .contributors)
        try container.encodeIfPresent(copyright, forKey: .copyright)
        try container.encodeIfPresent(createdDate, forKey: .createdDate)
        try container.encodeIfPresent(credits, forKey: .credits)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(distributor, forKey: .distributor)
        try container.encodeIfPresent(displayDate, forKey: .displayDate)
        try container.encodeIfPresent(editorNote, forKey: .editorNote)
        try container.encodeIfPresent(firstPublishDate, forKey: .firstPublishDate)
        try container.encodeIfPresent(geo, forKey: .geo)
        try container.encodeIfPresent(headlines, forKey: .headlines)
        try container.encodeIfPresent(label, forKey: .label)
        try container.encodeIfPresent(language, forKey: .language)
        try container.encodeIfPresent(lastUpdatedDate, forKey: .lastUpdatedDate)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(owner, forKey: .owner)
        try container.encodeIfPresent(promoItems, forKey: .promoItems)
        try container.encodeIfPresent(publishDate, forKey: .publishDate)
        try container.encodeIfPresent(renderingGuides, forKey: .renderingGuides)
        try container.encodeIfPresent(revision, forKey: .revision)
        try container.encodeIfPresent(shortUrl, forKey: .shortUrl)
        try container.encodeIfPresent(slug, forKey: .slug)
        try container.encodeIfPresent(source, forKey: .source)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(subheadlines, forKey: .subheadlines)
        try container.encodeIfPresent(subtype, forKey: .subtype)
        try container.encodeIfPresent(syndication, forKey: .syndication)
        try container.encodeIfPresent(taxonomy, forKey: .taxonomy)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(vanityCredits, forKey: .vanityCredits)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encodeIfPresent(voiceTranscripts, forKey: .voiceTranscripts)
        try container.encodeIfPresent(websiteUrl, forKey: .websiteUrl)
        try container.encodeIfPresent(websites, forKey: .websites)
        try container.encodeIfPresent(workflow, forKey: .workflow)
        try container.encodeIfPresent(streams, forKey: .streams)
        try container.encodeIfPresent(videoType, forKey: .videoType)
        try container.encodeIfPresent(subtitles, forKey: .subtitles)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        contentElements = try container.decodeIfPresent([AnyContentElement].self,
                                                        forKey: .contentElements)?.compactMap { $0.contentElement }
        identifier = try container.decodeIfPresent(String.self, forKey: .identifier)
        address = try container.decodeIfPresent(Address.self, forKey: .address)
        alignment = try container.decodeIfPresent(String.self, forKey: .alignment)
        canonicalUrl = try container.decodeIfPresent(String.self, forKey: .canonicalUrl)
        canonicalWebsite = try container.decodeIfPresent(String.self, forKey: .canonicalWebsite)
        channels = try container.decodeIfPresent([String].self, forKey: .channels)
        comments = try container.decodeIfPresent(Comments.self, forKey: .comments)
        contentAliases = try container.decodeIfPresent([String].self, forKey: .contentAliases)
        contentRestrictions = try container.decodeIfPresent(ContentRestrictions.self, forKey: .contentRestrictions)
        contributors = try container.decodeIfPresent(Contributor.self, forKey: .contributors)
        copyright = try container.decodeIfPresent(String.self, forKey: .copyright)
        description = try container.decodeIfPresent(Description.self, forKey: .description)
        createdDate = try container.decodeIfPresent(String.self, forKey: .createdDate)
        credits = try container.decodeIfPresent(Credits.self, forKey: .credits)
        displayDate = try container.decodeIfPresent(String.self, forKey: .displayDate)
        distributor = try container.decodeIfPresent(Distributor.self, forKey: .distributor)
        editorNote = try container.decodeIfPresent(String.self, forKey: .editorNote)
        firstPublishDate = try container.decodeIfPresent(String.self, forKey: .firstPublishDate)
        geo = try container.decodeIfPresent(Geo.self, forKey: .geo)
        headlines = try container.decodeIfPresent(Headlines.self, forKey: .headlines)
        label = try container.decodeIfPresent([String: Label].self, forKey: .label)
        language = try container.decodeIfPresent(String.self, forKey: .language)
        lastUpdatedDate = try container.decodeIfPresent(String.self, forKey: .lastUpdatedDate)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        owner = try container.decodeIfPresent(Owner.self, forKey: .owner)
        promoItems = try container.decodeIfPresent(PromoItems.self, forKey: .promoItems)
        publishDate = try container.decodeIfPresent(String.self, forKey: .publishDate)
        renderingGuides = try container.decodeIfPresent(RenderingGuide.self, forKey: .renderingGuides)
        revision = try container.decodeIfPresent(Revision.self, forKey: .revision)
        shortUrl = try container.decodeIfPresent(String.self, forKey: .shortUrl)
        slug = try container.decodeIfPresent(String.self, forKey: .slug)
        source = try container.decodeIfPresent(Source.self, forKey: .source)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        subheadlines = try container.decodeIfPresent(Subheadlines.self, forKey: .subheadlines)
        subtype = try container.decodeIfPresent(String.self, forKey: .subtype)
        syndication = try container.decodeIfPresent(Syndication.self, forKey: .syndication)
        taxonomy = try container.decodeIfPresent(Taxonomy.self, forKey: .taxonomy)
        type = try container.decode(ArcXPContentType.self, forKey: .type)
        vanityCredits = try container.decodeIfPresent(VanityCredits.self, forKey: .vanityCredits)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        voiceTranscripts = try container.decodeIfPresent([VoiceTranscript].self, forKey: .voiceTranscripts)
        websites = try container.decodeIfPresent([String: Website].self, forKey: .websites)
        websiteUrl = try container.decodeIfPresent(String.self, forKey: .websiteUrl)
        workflow = try container.decodeIfPresent(Workflow.self, forKey: .workflow)
        streams = try container.decodeIfPresent([MediaStream].self, forKey: .streams)
        subtitles = try container.decodeIfPresent(Subtitles.self, forKey: .subtitles)
        videoType = try container.decodeIfPresent(String.self, forKey: .videoType)
    }
}

extension ArcXPContent: CacheValue {
    public static let cacheKey = "com.arcxp.content.ansObject"

    public typealias Hint = DefaultCacheHint
    public typealias Value = ArcXPContent
}

extension ArcXPContent {
    // Helper properties

    /// List of author names for the story
    public var authorNames: [String]? {
        return credits?.authors?.compactMap({$0.name})
    }

    /// Formatted published date, Ex: `April 7, 2022 at 8:00 AM EDT`
    public var formattedPublishedDate: String? {
        return ArcXPContentUtils.formattedDate(dateString: publishDate)
    }

    /// Resized Image url with thumbnail size
    public var thumbnailImageUrl: String? {
        return (promoItems?.content as? ImageContentElement)?.resizedThumbnailImageUrl
    }

    /// Resized Image url that fits the device size
    public var imageUrl: String? {
        return (promoItems?.content as? ImageContentElement)?.resizedImageUrl ?? promoItems?.leadArt?.resizedImageUrl
    }
}
