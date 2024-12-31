//
//  ContentListResponse.swift
//  ArcXPContent
//
//  Created by Mahesh Venkateswarlu on 2/9/22.
//  Copyright © 2022 Arc XP. All rights reserved.
//

import Foundation

/// A response object that contains a content list of ``ArcXPContent``.
public struct ContentListResponse: Codable {
    public var contentList: ArcXPContentList = []
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let ansObject = (ArcXPContent.self as Decodable.Type)
        while !container.isAtEnd {
            let subDecoder = try container.superDecoder()
            if let decodedContent = try ansObject.init(from: subDecoder) as? ArcXPContent {
                contentList.append(decodedContent)
            }
        }
    }
}

extension ContentListResponse: CacheValue {
    public static let cacheKey = "com.arcxp.content.ansCollection"

    public typealias Hint = DefaultCacheHint
    public typealias Value = ContentListResponse
}
