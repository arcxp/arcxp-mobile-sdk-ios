//
//  FeedsEndpoint.swift
//  ArcXPContent
//
//  Created by Davis, Tyler on 1/18/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation

public struct PaginationDefaults {
    public static let maxResults = 20
    public static let startIndex = 0
}

/// An enum of ContentEndpoints for fetching the content data.
/// It holds all the necessary information such as baseURl, path, headers, body i.e., required for interacting with each service.
enum FeedsEndpoint: Endpoint {

    /// For articles and gallery
    case contentById(_ identifier: String)
    /// For collections
    case collection(_ alias: String, index: Int, size: Int)
    /// For search requests
    case search(_ keywords: [String], fromIndex: Int, listSize: Int)
    /// For site service
    case sectionList(_ siteHierarchy: String)
    /// For search requests that return only video content
    case searchVideo(_ keywords: [String], fromIndex: Int, listSize: Int)

    var baseUrl: String {
        let config = ArcXPContentManager.client.configuration
        return config.hostDomain+"/arc/outboundfeeds"
    }

    var path: String {
        switch self {
        case .contentById:
            return "/article/"
        case .collection(var alias, _, _):
            let collectionPath = ArcXPContentManager.client.cacheConfiguration.shouldPreloadCache ? "/collection-full/" : "/collection/"
            if alias.hasPrefix("/") {
                alias.removeFirst()
            }
            return collectionPath + alias
        case .search(let keywords, _, _):
            // Space is the only allowed special character for search keywords
            let joinedKeywords = keywords.joined(separator: ",%20").replacingOccurrences(of: " ", with: "%20")
            return "/search/\(joinedKeywords)"
        case .sectionList(let siteHierarchy):
            return "/navigation/\(siteHierarchy)"
        case .searchVideo(let keywords, _, _):
            let joinedKeywords = keywords.joined(separator: ",%20").replacingOccurrences(of: " ", with: "%20")
            return "/searchVideo/\(joinedKeywords)"
        }
    }

    var method: String {
        switch self {
        default:
            return "GET"
        }
    }

    var headers: [String: String]? {
        let standardHeaders = ["Content-Type": ArcXPConstants.contentTypeHeader,
                               "User-Agent": ArcXPConstants.userAgentHeader]
        switch self {
        default:
            break
        }
        return standardHeaders
    }

    var urlParameters: [String: String]? {
        switch self {
        case .contentById(let identifier):
            return ["_id": identifier]
        case .collection(_, let fromIndex, let listSize):
            let size = listSize > PaginationDefaults.maxResults ? PaginationDefaults.maxResults : listSize
            return ["from": String(fromIndex),
                    "size": String(size)]
        case .search(_, let fromIndex, let listSize), .searchVideo(_, let fromIndex, let listSize):
            let size = listSize > PaginationDefaults.maxResults ? PaginationDefaults.maxResults : listSize
            return ["from": String(fromIndex),
                    "size": String(size)]
        default:
            break
        }
        return nil
    }

    /// The body data to be attached with the relevant Identity request.
    var body: Data? {
        switch self {
        default:
            return nil
        }
    }
}
