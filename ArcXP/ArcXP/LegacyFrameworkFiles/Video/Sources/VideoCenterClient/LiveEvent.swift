//
//  LiveVideoResponse.swift
//  ArcXPVideo
//
//  Created by Mahesh Venkateswarlu on 10/17/22.
//  Copyright © 2022 The Washington Post. All rights reserved.
//

import Foundation

/// Live Event response that will be read when any event goes live
public struct LiveEvent: Decodable {

    /// The `JSONDecoder` that's configured for `LiveEventResponse`s.
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    public let id: String
    public let contentConfig: ContentConfig
    public let metaConfig: MetaConfig
    public let promoImage: PromoImage
    public let liveEventConfig: LiveEventConfig

    /// Content data of the live stream
    public struct ContentConfig: Decodable {
        // blurb of the event
        public let blurb: String?
        // uuid of the Event
        // This should be passed to videoSDK for getting the live stream url
        public let uuid: String
        // Title of the event
        public let title: String
        // Type of the event
        public let type: String
    }
    /// Meta data of the live stream
    public struct MetaConfig: Decodable {
        public let section: String?
        public let subsection: String?
        public let primarySiteNode: String?
        public let sectionDisplayName: String?
    }
    ///  Live Stream data  of the event
    public struct LiveEventConfig: Decodable {
        public let streams: [Stream]?
    }
    /*
     "promoImage": {
         "image": {
             "url": "https://d30tdlpyqi4wi2.cloudfront.net/10-17-2022/c84f0b27_538b_4e9a_9abf_f11343f49fe2_thumbnail.jpeg",
         }
     },
     */
// swiftlint: disable nesting
    /// Promo Image of the live stream
    public struct PromoImage: Decodable {
        public let imageUrl: URL?

        enum CodingKeys: String, CodingKey {
            case image
        }
        enum ImageKeys: String, CodingKey {
            case url
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do {
                let imageContainer = try container.nestedContainer(keyedBy: ImageKeys.self, forKey: .image)
                let urlString = try imageContainer.decode(String.self, forKey: .url)
                imageUrl = URL(string: urlString)
            } catch {
                imageUrl = nil
            }
        }
    }
// swiftlint: enable nesting
}
