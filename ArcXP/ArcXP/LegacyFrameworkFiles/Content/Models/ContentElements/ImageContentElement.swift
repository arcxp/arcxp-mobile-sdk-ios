//
//  ImageContentElement.swift
//  ArcXPContent
//
//  Created by Davis, Tyler on 1/19/22.
//

import Foundation

/// A content elemement representing an image.
public struct ImageContentElement: ContentElement {

    public static var contentType = ContentType.image

    public enum CodingKeys: String, CodingKey {
        case id = "_id"

        case additionalProperties
        case address
        case auth
        case caption
        case content
        case createdDate
        case credits
        case geo
        case height
        case imageType = "mime_type"
        case licensable
        case owner
        case relatedContent
        case source
        case subtitle
        case type
        case url
        case width
        case promoItems
    }

    public var id: String?
    public var content: String?
    public var type: String?

    private let auth: [String: String]?
    public var additionalProperties: ImageAdditionalProperties?
    public var address: Address?
    public var caption: String?
    public var createdDate: String?
    public var credits: Credits?
    public var geo: Geo?
    public var height: Int?
    public var imageType: String?
    public var licensable: Bool?
    public var owner: Owner?
    public var relatedContent: [String: [ImageContentElement]]?
    public var source: Source?
    public var subtitle: String?
    public var url: String?
    public var width: Int?
    public var promoItems: PromoItems?

    /// Resized Image url that fits the device size
    public var resizedImageUrl: String? {
        return ArcXPImageResizer.resizedImageUrl(originalImageSize: CGSize(width: width ?? 0,
                                                                             height: height ?? 0),
                                                   originalUrl: url,
                                                   auth: auth)
    }

    /// Resized Image url with thumbnail size.
    public var resizedThumbnailImageUrl: String? {
        if let thumbnailUrl = additionalProperties?.thumbnailResizeUrl {
            return ArcXPContentUtils.prefixOrgDomain(relativePath: thumbnailUrl)
        }
        // This happens mostly for video type where there are no additional properties, so use `url` for resize
        return  ArcXPImageResizer.resizedThumbnailUrl(originalUrl: url, auth: auth)
    }
}

/// Additional metadata associated with the image element.
public struct ImageAdditionalProperties: Codable {

    public enum CodingKeys: String, CodingKey {
        case fullSizeResizeUrl
        case proxyUrl
        case published
        case resizeUrl
        case restricted
        case thumbnailResizeUrl
        case version
        case galleries
        case galleryOrder
        case ingestionMethod
        case keywords
        case mimeType
        case originalName
        case originalUrl
        case owner
        case hasPublishedCopy
    }

    public var fullSizeResizeUrl: String?
    public var galleries: [ImageGallery]?
    public var galleryOrder: Int?
    public var ingestionMethod: String?
    public var keywords: [String]?
    public var mimeType: String?
    public var originalName: String?
    public var originalUrl: String?
    public var owner: String?
    public var proxyUrl: String?
    public var published: Bool?
    public var resizeUrl: String?
    public var restricted: Bool?
    public var thumbnailResizeUrl: String?
    public var version: Int?
    public let hasPublishedCopy: Bool?

    public struct ImageGallery: Codable {
        public let headlines: Headlines?
    }
}
