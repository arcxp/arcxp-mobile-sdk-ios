//
//  PromoItems.swift
//  ArcXPContent
//
//  Created by Davis, Tyler on 1/20/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation

public struct PromoItems: Codable {
// swiftlint: disable nesting
    public struct LeadArt: Codable {

        enum CodingKeys: String, CodingKey {
            case additionalProperties
            case createdDate
            case id = "_id"
            case lastUpdatedDate
            case auth
            case caption
            case credits
            case height
            case licensable
            case url
            case owner
            case taxonomy
            case source
            case subtitle
            case type
            case version
            case width
        }

        public var additionalProperties: ImageAdditionalProperties?
        private let auth: [String: String]?
        public var caption: String?
        public var createdDate: String?
        public var credits: Credits?
        public var height: Int?
        public var id: String?
        public var lastUpdatedDate: String?
        public var licensable: Bool?
        public var owner: Owner?
        public var source: Source?
        public var taxonomy: Taxonomy?
        public var subtitle: String?
        public var type: String? // TODO: can this be anything other than image?
        public var url: String?
        public var version: String?
        public var width: Int?

        public var resizedImageUrl: String? {
            return ArcXPImageResizer.resizedImageUrl(originalImageSize: CGSize(width: width ?? 0,
                                                                                 height: height ?? 0),
                                                       originalUrl: url,
                                                       auth: auth)
        }
    }
// swiftlint: enable nesting
    enum CodingKeys: String, CodingKey {
        case content = "basic"
        case leadArt
    }

    public var content: ContentElement?
    public var leadArt: LeadArt?

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(leadArt, forKey: .leadArt)

        if let content = content {
            try container.encodeIfPresent(AnyContentElement(content), forKey: .content)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        leadArt = try container.decodeIfPresent(LeadArt.self, forKey: .leadArt)
        content = try container.decodeIfPresent(AnyContentElement.self, forKey: .content)?.contentElement
    }

}
