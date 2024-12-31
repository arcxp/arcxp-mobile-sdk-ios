//
//  ContentElement.swift
//  ArcXPContent
//
//  Created by Davis, Tyler on 1/18/22.
//

import Foundation

/// Interface for all elements held in the story's content_elements array
/// See ANS: https://github.com/washingtonpost/ans-schema/blob/master/src/main/resources/schema/ans/0.10.9/content.json
public protocol ContentElement: Codable {
    /// The type of content the element represents.
    static var contentType: ContentType { get }
    
    /// The unique identifier for the content element.
    var id: String? { get set }
    var content: String? { get set }
    
    /// The type of content the element represents.
    var type: String? { get set }
}
// swiftlint: disable identifier_name
/// Enumeration of all types of elements that can be served in a story/gallery/video
public enum ContentType: String, Codable {

    case gallery
    case image
    case text
    case video
    case code
    case correction
    case embed
    case endorsement
    case html
    case header
    case interstitial_link
    case list
    case quote
    case numeric_rating
    case custom_embed
    case oembed_response
    case unknown

    /// enables the initialization of each object from decoding
    var metatype: ContentElement.Type? {
        switch self {
        case .image: return ImageContentElement.self
        case .text: return TextContentElement.self
        case .gallery: return GalleryContentElement.self
        case .video: return VideoContentElement.self
        case .code: return CodeContentElement.self
        case .correction: return CorrectionContentElement.self
        case .embed: return CustomEmbedContentElement.self
        case .html: return HtmlContentElement.self
        case .header: return HeaderContentElement.self
        case .interstitial_link: return InterstitialLinkContentElement.self
        case .list: return ListContentElement.self
        case .numeric_rating: return NumericRatingContentElement.self
        case .quote: return QuoteContentElement.self
        case .oembed_response: return OembedResponseContentElement.self
        case .custom_embed: return CustomEmbedContentElement.self
        default:
            return UnknownContentElement.self
        }
    }

    public init(from decoder: Decoder) throws {
        self = try ContentType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}
// swiftlint: enable identifier_name

/// Allows encoding/decoding for the mapping of all content types in an array
public struct AnyContentElement: Codable {

    var contentElement: ContentElement?

    init(_ contentElement: ContentElement) {
        self.contentElement = contentElement
    }

    private enum CodingKeys: CodingKey {
        case type
        case item
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let contentElement = contentElement {
            try container.encode(type(of: contentElement).contentType, forKey: .type)
        }
        try contentElement?.encode(to: encoder)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(ContentType.self, forKey: .type)
        if let metaType = type.metatype {
            self.contentElement = try metaType.init(from: decoder)
        }
    }

}
