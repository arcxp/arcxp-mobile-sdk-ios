//
//  SectionListResponse.swift
//  ArcXPContent
//
//  Created by Mahesh Venkateswarlu on 2/10/22.
//  Copyright © 2022 Arc XP. All rights reserved.
//

import Foundation

/// A response object that contains a list of ``SectionListElement``s. I.e. a ``SectionList``.
public struct SectionListResponse: Codable {
    public var sectionList: SectionList = []
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let sectionListObject = (SectionListElement.self as Decodable.Type)
        while !container.isAtEnd {
            let subDecoder = try container.superDecoder()
            if let decodedContent = try sectionListObject.init(from: subDecoder) as? SectionListElement {
                sectionList.append(decodedContent)
            }
        }
    }
}

extension SectionListResponse: CacheValue {
    /// The cache key for the ``SectionListResponse``.
    public static let cacheKey = "com.arcxp.content.sectionList"

    public typealias Hint = DefaultCacheHint
    public typealias Value = SectionListResponse
}
