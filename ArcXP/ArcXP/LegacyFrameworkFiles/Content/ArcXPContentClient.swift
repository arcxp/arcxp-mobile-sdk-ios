//
//  ArcContentClient.swift
//  ArcXPContent
//
//  Created by Cassandra Balbuena on 1/12/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation

/// The client that fetches content from the ArcXP content feeds.
public class ArcXPContentClient {

    // swiftlint: disable nesting
    /// Represents configurations for testing purposes.
    struct Mock {
        /// Determines whether the test will mock a success or failure.
        enum MockType {
            case success
            case failure
        }

        /// The type of  the mock test to be executed.
        var mockType: MockType = .success
        /// Determines if the tests will use mock responses or not.
        var useMocks = false
    }
    // swiftlint: enable nesting

    /// The type of the request made from the ``ArcXPContentClient``.
    public enum RequestType {
        case sectionList
        case collection
        case content
    }
    /// The mock property used for testing purposes.
    var mock: Mock = Mock()

    // MARK: - Properties

    /// The content client's configuration which includes the ``organizationName``
    /// the ``serverEnvironment`` and the ``site``.
    var configuration = ArcXPContentConfig(organizationName: "",
                                           serverEnvironment: .sandbox,
                                           site: "",
                                           hostDomain: "") {
        didSet {
            // Override the hostDomain if missing with https
            configuration.hostDomain = configuration.hostDomain.hasPrefix("https://") ? configuration.hostDomain : "https://\(configuration.hostDomain)"
            if configuration.hostDomain.hasSuffix("/") {
                configuration.hostDomain.removeLast()
            }
        }
    }

    /// The content client's cache configuration.
    public var cacheConfiguration = ArcXPCacheConfig()

    // MARK: - ContentCacheManagers
    /// When ContentCacheManager is initialized, \
    /// the cache index will be loaded with all the file names that were cached earlier.\
    /// and so we initialize it every time we interact with the cache
    var sectionListContentCacheManager: ContentCacheManager<SectionListResponse>?
    var collectionContentCacheManager: ContentCacheManager<ContentListResponse>?
    var storyContentCacheManager: ContentCacheManager<ArcXPContent>?

    // MARK: - ArcContentClient Functions

    /// Retrieves the contents of a story based on the specified identifier and calls a handler upon completion.
    /// - Parameters:
    ///   - identifier: A `String` object that represents the story id
    ///   - shouldIgnoreCache: A boolean to indicate whether the call should bypass the cache or not.
    ///   - handleResult: The completion handler to call when the request is complete.
    ///   It contains the `Result` type with a content data object ``ArcXPContent`` \
    ///   if available else the descriptive error object detailing the failure.
    public func getStoryContent(identifier: ArcXPContentID,
                                shouldIgnoreCache: Bool = false,
                                handleResult: @escaping ArcXPStoryResultHandler) {
        getContentById(identifier: identifier, shouldIgnoreCache: shouldIgnoreCache, handleResult: handleResult)
    }

    /// Retrieves the contents of a gallery based on the specified identifier and calls a handler upon completion.
    /// - Parameters:
    ///   - identifier: A `String` object that represents the gallery id
    ///   - shouldIgnoreCache: A boolean to indicate whether the call should bypass the cache or not.
    ///   - handleResult: The completion handler to call when the request is complete.
    ///   It contains the `Result` type with a content data object ``ArcXPContent`` \
    ///   if available else the descriptive error object detailing the failure.
    public func getGalleryContent(identifier: ArcXPContentID,
                                  shouldIgnoreCache: Bool = false,
                                  handleResult: @escaping ArcXPStoryResultHandler) {
        getContentById(identifier: identifier, shouldIgnoreCache: shouldIgnoreCache, handleResult: handleResult)
    }

    /// Retrieves the raw JSON content using the provided identifier and calls a handler upon completion.
    /// - Parameters:
    ///   - requestType: The type of the request that is being made by the client.
    ///   - identifierOrAlias: the identifier of the content being requested.
    ///   - handleResult: The completion handler to call when the request is complete.
    ///   It contains the `Result` type with a content JSON String object \
    ///   if available else the descriptive error object detailing the failure.
    public func getRawJsonContent(requestType: RequestType,
                                  identifierOrAlias: ArcXPContentID,
                                  index: Int = PaginationDefaults.startIndex,
                                  size: Int = PaginationDefaults.maxResults,
                                  handleResult: @escaping (Result<String, Error>) -> Void) {
        var endpoint: Endpoint
        switch requestType {
        case .content:
            endpoint = FeedsEndpoint.contentById(identifierOrAlias)
        case .collection:
            endpoint = FeedsEndpoint.collection(identifierOrAlias, index: index, size: size)
        case .sectionList:
            endpoint = FeedsEndpoint.sectionList(identifierOrAlias)
        }

        guard let request = URLRequest(endpoint: endpoint) else {
            return handleResult(.failure(NetworkError.URLRequestError(reason: .endpointMalformed)))
        }
        request.callForData { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                if let stringData = String(data: data, encoding: .utf8) {
                    handleResult(.success(stringData))
                } else {
                    handleResult(.failure(NetworkError.URLRequestError(reason: .noDataError)))
                }
            case .failure(let error):
                handleResult(.failure(error))
            }
        }
    }

    /// Retrives the content by Id. Story and Gallery content uses the same API to get data by id.
    /// For better readability two functions are provided for story and Gallery, but internally they call the same method below.
    /// - Parameters:
    ///   - identifier: A `String` object that represents the content's id
    ///   - shouldIgnoreCache: A boolean to indicate whether the call should bypass the cache or not.
    ///   - handleResult: The completion handler to call when the request is complete.
    ///   It contains the `Result` type with a content ``ArcXPContent``object \
    ///   if available else the descriptive error object detailing the failure.
    private func getContentById(identifier: ArcXPContentID,
                                shouldIgnoreCache: Bool,
                                handleResult: @escaping ArcXPStoryResultHandler) {
        guard !shouldIgnoreCache else {
            fetchRemoteContentById(identifier: identifier,
                                   shouldSaveIntoCache: false,
                                   handleResult: handleResult)
            return
        }

        storyContentCacheManager = ContentCacheManager<ArcXPContent>()
        let cacheKey = ArcXPContent.cacheKey + ".\(identifier)"
        storyContentCacheManager?.fetchContentFromCache(key: cacheKey) { cacheResult in
            let value = cacheResult.value?.value
            if let cachedAnsContent = value,
               let lastModifiedTime = cacheResult.value?.entry.modified,
               let storyContentCacheManager = self.storyContentCacheManager,
               storyContentCacheManager.shouldAllowCached(lastModified: lastModifiedTime,
                                                          timeToConsider: self.cacheConfiguration.cacheTimeUntilUpdate) {
                LoggingManager.log("Rendered article response from cache", level: .debug)
                deliverToMainThread {
                    handleResult(.success(cachedAnsContent))
                }
                return
            }
            self.storyContentCacheManager?.removeFromCache(cacheKey: cacheKey)
            self.fetchRemoteContentById(identifier: identifier, shouldSaveIntoCache: true) { storyResult in
                switch storyResult {
                case .success(let storyContent):
                    LoggingManager.log("Rendered article response from server", level: .debug)
                    handleResult(.success(storyContent))
                case .failure(let error):
                    guard let contentError = error as? NetworkError else {
                        handleResult(.failure(error))
                        return
                    }
                    let cachedContentError = contentError.feedCacheContentIntoErrorObject(cachedContent: value)
                    LoggingManager.log("Rendered article response from cache", level: .debug)
                    handleResult(.failure(cachedContentError))
                }
            }
        }
    }

    /// Retrieves Arc Collection feeds by alias.
    /// - Parameters:
    ///   - alias: A `String` object that brings down a feeds collection
    ///   - index: Index of the search results (Ex: (0..9) -> index = 0, (10..20) -> index = 10)
    ///   - size: size of the collections result
    ///   - shouldIgnoreCache: A boolean to indicate whether the call should bypass the cache or not.
    ///   - handleResult: The completion handler to call when the request is complete.
    ///   It contains the `Result` type with an array of content data objects ``ArcXPContentList`` \
    ///   if available else the descriptive error object detailing the failure.
    public func getCollection(alias: ArcXPContentID,
                              index: Int = PaginationDefaults.startIndex,
                              size: Int = PaginationDefaults.maxResults,
                              shouldIgnoreCache: Bool = false,
                              handleResult: @escaping ArcXPCollectionResultHandler) {
        guard !shouldIgnoreCache else {
            fetchRemoteCollectionResults(alias: alias,
                                         index: index,
                                         size: size,
                                         shouldSaveIntoCache: !shouldIgnoreCache,
                                         completion: handleResult)
            return
        }
        collectionContentCacheManager = ContentCacheManager<ContentListResponse>()
        let cacheKey = ContentListResponse.cacheKey + ".\(alias)"
        // LOGIC: Fetch contents from the cache
        // Request (index 0: size 5), Existing cache: 5 => Return 5 elements from cache
        // Request (index 5: size 10), Existing cache: 5 => Fetch remote collection results and save to cache
        // Request (index 8: size 5), Existing cache: 10 => Fetch 8,9 elements from cache
        collectionContentCacheManager?.fetchContentFromCache(key: cacheKey) { cacheResult in
            let cacheValue = cacheResult.value?.value
            let endIndex = index+size
            let cachedCollectionList = self.sortContentByPagination(startIndex: index,
                                                                    endIndex: endIndex,
                                                                    collectionList: cacheValue?.contentList ?? [])
            if !cachedCollectionList.isEmpty,
               index < cachedCollectionList.count,
               let lastModifiedTime = cacheResult.value?.entry.modified,
               let collectionContentCacheManager = self.collectionContentCacheManager,
               collectionContentCacheManager.shouldAllowCached(lastModified: lastModifiedTime,
                                                               timeToConsider: self.cacheConfiguration.cacheTimeUntilUpdate) {
                deliverToMainThread {
                    handleResult(.success(cachedCollectionList))
                }
                return
            }
            self.collectionContentCacheManager?.removeFromCache(cacheKey: cacheKey)
            self.fetchRemoteCollectionResults(alias: alias,
                                              index: index,
                                              size: size,
                                              shouldSaveIntoCache: !shouldIgnoreCache) { collectionResult in
                switch collectionResult {
                case .success(let collectionList):
                    LoggingManager.log("Rendered collection response from server", level: .debug)
                    handleResult(.success(collectionList))
                case .failure(let error):
                    guard let contentError = error as? NetworkError else {
                        handleResult(.failure(error))
                        return
                    }
                    LoggingManager.log("Rendered collection response from cache", level: .debug)
                    let cachedContentError = contentError.feedCacheContentIntoErrorObject(cachedContent: cachedCollectionList)
                    handleResult(.failure(cachedContentError))
                }
            }
        }
    }

    /// Sorts a collection list by pagination.
    /// - Parameters:
    ///  - startIndex: The start index of the collection list.
    ///  - endIndex: The end index of the collection list.
    ///  - collectionList: The collection list to be sorted.
    private func sortContentByPagination(startIndex: Int, endIndex: Int, collectionList: ArcXPContentList) -> ArcXPContentList {
        if startIndex < collectionList.count {
            if endIndex <= collectionList.count {
                return Array(collectionList[startIndex..<endIndex])
            } else {
                return Array(collectionList[startIndex..<collectionList.count])
            }
        } else {
            return collectionList
        }
    }

    /// Retrieves the contents of a ``SectionList``.
    /// - Parameters:
    ///   - siteHierarchy: A `String`  that represents the site hierarchy name
    ///   - shouldIgnoreCache: A boolean to indicate whether the call should bypass the cache or not.
    ///   - handleResult: The completion handler to call when the request is complete.
    ///   It contains the `Result` type with an array of content data objects ``SectionListElement``
    ///   if available else the descriptive error object detailing the failure.
    public func getSectionList(siteHierarchy: String,
                               shouldIgnoreCache: Bool = false,
                               handleResult: @escaping ArcXPSectionListHandler) {
        guard !shouldIgnoreCache else {
            fetchRemoteSectionList(siteHierarchy: siteHierarchy,
                                   shouldSaveIntoCache: false,
                                   handleResult: handleResult)
            return
        }
        sectionListContentCacheManager = ContentCacheManager<SectionListResponse>()
        sectionListContentCacheManager?.fetchContentFromCache(key: SectionListResponse.cacheKey) { cacheResult in
            let value = cacheResult.value?.value
            if let cachedSectionContent = value,
               let lastModifiedTime = cacheResult.value?.entry.modified,
               let sectionListContentCacheManager = self.sectionListContentCacheManager,
               sectionListContentCacheManager.shouldAllowCached(lastModified: lastModifiedTime,
                                                                timeToConsider: self.cacheConfiguration.cacheTimeUntilUpdate) {
                LoggingManager.log("Rendered sectionList response from cache", level: .debug)
                deliverToMainThread {
                    handleResult(.success(cachedSectionContent.sectionList))
                }
                return
            }
            self.sectionListContentCacheManager?.removeFromCache(cacheKey: SectionListResponse.cacheKey)
            self.fetchRemoteSectionList(siteHierarchy: siteHierarchy,
                                        shouldSaveIntoCache: true) { sectionListResult in
                switch sectionListResult {
                case .success(let sectionList):
                    LoggingManager.log("Rendered sectionList response from server", level: .debug)
                    handleResult(.success(sectionList))
                case .failure(let error):
                    guard let contentError = error as? NetworkError else {
                        handleResult(.failure(error))
                        return
                    }
                    let cachedContentError = contentError.feedCacheContentIntoErrorObject(cachedContent: value)
                    LoggingManager.log("Rendered sectionList response from cache", level: .debug)
                    handleResult(.failure(cachedContentError))
                }
            }
        }
    }

    /// Retrieves content by keywords
    /// - Parameters:
    ///   - keywords: An array of`String` objects that are keywords
    ///   - index: Index of the search results (Ex: (0..9) -> index = 0, (10..20) -> index = 10)
    ///   - size: Size of the results to return
    ///   - handleResult: The completion handler to call when the request is complete.
    ///   It contains the `Result` type with an array of content data objects ``ArcXPContent`` \
    ///   if available else the descriptive error object detailing the failure.
    @available(*, renamed: "getSearch(by:)")
    public func search(by keywords: [String],
                       index: Int = PaginationDefaults.startIndex,
                       size: Int = PaginationDefaults.maxResults,
                       handleResult: @escaping ArcXPCollectionResultHandler) {
        let endpoint = FeedsEndpoint.search(keywords.map { word in
            word.alphanumericWithSpaces
        }, fromIndex: index, listSize: size)
        guard let request = URLRequest(endpoint: endpoint) else {
            return handleResult(.failure(NetworkError.URLRequestError(reason: .endpointMalformed)))
        }
        request.callForCodable(handleResult: handleResult)
    }

    /// Retrieves video content by keywords
    /// - Parameters:
    ///   - keywords: An array of`String` objects that are keywords
    ///   - index: Index of the search results (Ex: (0..9) -> index = 0, (10..20) -> index = 10)
    ///   - size: Size of the results to return
    ///   - handleResult: The completion handler to call when the request is complete.
    ///   It contains the `Result` type with an array of content data objects ``ArcXPContent``
    public func searchVideos(by keywords: [String],
                             index: Int = PaginationDefaults.startIndex,
                             size: Int = PaginationDefaults.maxResults,
                             handleResult: @escaping ArcXPCollectionResultHandler) {
        let endpoint = FeedsEndpoint.searchVideo(keywords.map { word in
            word.alphanumericWithSpaces
        }, fromIndex: index, listSize: size)
        guard let request = URLRequest(endpoint: endpoint) else {
            return handleResult(.failure(NetworkError.URLRequestError(reason: .endpointMalformed)))
        }
        request.callForCodable(handleResult: handleResult)
    }

    /// Clears the cache for the given alias
    /// - Parameters:
    ///   - requestType: `RequestType` enum of the request.
    ///   - alias: `String` key of the content.
    public func clearCacheForKey(requestType: RequestType, alias: String = "") {
        storyContentCacheManager = ContentCacheManager<ArcXPContent>()
        let cacheKey: String
        switch requestType {
        case .collection:
            cacheKey = ContentListResponse.cacheKey + ".\(alias)"
        case .content:
            cacheKey = ArcXPContent.cacheKey + ".\(alias)"
        case .sectionList:
            cacheKey = SectionListResponse.cacheKey
        }
        storyContentCacheManager?.removeFromCache(cacheKey: cacheKey)
    }

    /// Clears entire cache
    /// - Parameter result: Completion handler called after the cache is cleared.
    public func clearAllCache(result: ((Failable<Void>) -> Void)? = nil) {
        storyContentCacheManager = ContentCacheManager<ArcXPContent>()
        storyContentCacheManager?.clearAllCache(result: result)
    }
}
