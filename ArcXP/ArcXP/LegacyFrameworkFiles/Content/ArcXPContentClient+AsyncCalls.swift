//
//  ArcXPContentClient+RawJson.swift
//  ArcXP
//
//  Created by Mahesh Venkateswarlu on 2/26/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import Foundation

extension ArcXPContentClient {

    /// Retrieves the raw JSON content using the provided identifier and delivers the data asynchronously.
    /// - Parameters:
    ///   - requestType: Request type ``RequestType`` of the json
    ///   - aliasId: `alias` or `Identifier`
    ///   - shouldIgnoreCache: ``Bool`` to determine if the response should be cached
    ///   - index: Index of the results (Ex: (0..9) -> index = 0, (10..20) -> index = 10). Only for `collection` request
    ///   - size: size of the collections result.  Only for `collection` request
    /// - Returns: An asynchronously-delivered object that contains the raw json as a ``String`` instance
    public func getRawJsonContent(requestType: RequestType,
                                  aliasId: String,
                                  shouldIgnoreCache: Bool = false,
                                  index: Int = PaginationDefaults.startIndex,
                                  size: Int = PaginationDefaults.maxResults) async throws -> String {
        guard !shouldIgnoreCache else {
            return try await withCheckedThrowingContinuation { continuation in
                getRawJsonContent(requestType: requestType, identifierOrAlias: aliasId) { result in
                    continuation.resume(with: result)
                }
            }
        }

        do {
            let cachedResonse: Codable
            switch requestType {
            case .sectionList:
                cachedResonse = try await getSectionList(aliasId: aliasId)
            case .collection:
                cachedResonse = try await getCollection(aliasId: aliasId)
            case .content:
                cachedResonse = try await getStoryContent(aliasId: aliasId)
            }
            return encodeToString(cachedResonse) ?? ""
        } catch {
            // If caching fails for any reason, fallback option to get the data directly.
            return try await withCheckedThrowingContinuation { continuation in
                getRawJsonContent(requestType: requestType, identifierOrAlias: aliasId) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    /// Retrieves the contents of the section list for the given alias  and delivers the data asynchronously.
    /// - Parameter aliasId: ``String`` alias of the section list
    /// - Returns: An asynchronously-delivered object that contains the response as a ``[SectionListElement]`` instance
    public func getSectionList(aliasId: String) async throws -> [SectionListElement] {
        return try await withCheckedThrowingContinuation { continuation in
            getSectionList(siteHierarchy: aliasId) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Retrieves the contents of the collection for the given alias  and delivers the response asynchronously.
    /// - Parameters:
    ///   - aliasId: ``String`` alias of the collection
    ///   - shouldIgnoreCache: ``Bool`` to determine if the response should be cached
    ///   - index:  Index of the results (Ex: (0..9) -> index = 0, (10..20) -> index = 10).
    ///   - size: size of the collections result.
    /// - Returns: An asynchronously-delivered object that contains the response as a  ``ArcXPContentList`` instance
    public func getCollection(aliasId: String,
                              shouldIgnoreCache: Bool = false,
                              index: Int = PaginationDefaults.startIndex,
                              size: Int = PaginationDefaults.maxResults) async throws -> ArcXPContentList {
        return try await withCheckedThrowingContinuation { continuation in
            getCollection(alias: aliasId, index: index, size: size) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Retrieves the contents of a story for the given  identifier  and delivers the response asynchronously.
    /// - Parameter aliasId:  ``String`` identifier of the story.
    /// - Parameter shouldIgnoreCache: ``Bool`` to determine if the response should be cached
    /// - Returns: An asynchronously-delivered object that contains the response as a  ``ArcXPContent`` instance
    public func getStoryContent(aliasId: String, shouldIgnoreCache: Bool = false) async throws -> ArcXPContent {
        return try await withCheckedThrowingContinuation { continuation in
            getStoryContent(identifier: aliasId) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Retrieves content by keywords
    /// - Parameters:
    ///   - keywords: An array of`String` objects that are keywords
    ///   - index: Index of the search results (Ex: (0..9) -> index = 0, (10..20) -> index = 10)
    ///   - size: Size of the results to return
    /// - Returns:  An asynchronously-delivered object that contains the response as an array of ``ArcXPContent``
    public func search(by keywords: [String],
                       index: Int = PaginationDefaults.startIndex,
                       size: Int = PaginationDefaults.maxResults) async throws -> ArcXPContentList {
        return try await withCheckedThrowingContinuation { continuation in
            search(by: keywords.map { word in
                word.alphanumericWithSpaces
            }, index: index, size: size ) { result in
                continuation.resume(with: result)
            }
        }
    }
}
