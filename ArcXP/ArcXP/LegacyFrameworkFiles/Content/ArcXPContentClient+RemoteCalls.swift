//
//  ArcXPContentClient+BulkLoad.swift
//  ArcXP
//
//  Created by Mahesh Venkateswarlu on 5/2/22.
//  Copyright © 2022 Arc XP. All rights reserved.
//

import Foundation

extension ArcXPContentClient {

    /// Retrieves the contents of a ``SectionList`` remotely instead of using the cache. Once the contents are retrieved,
    /// it is loaded into the cache.
    /// - Parameters:
    ///   - siteHierarchy: A `String`  that represents the site hierarchy name
    ///   - shouldSaveIntoCache: A boolean to indicate whether the fetched results should save into cache
    ///   - handleResult: The completion handler to call when the request is complete.
    ///   It contains the `Result` type with an array of content data objects ``SectionListElement``
    ///   if available else the descriptive error object detailing the failure.
    func fetchRemoteSectionList(siteHierarchy: String,
                                shouldSaveIntoCache: Bool,
                                handleResult: @escaping ArcXPSectionListHandler) {

        let endpoint = FeedsEndpoint.sectionList(siteHierarchy)
        guard let request = URLRequest(endpoint: endpoint) else {
            return handleResult(.failure(NetworkError.URLRequestError(reason: .endpointMalformed)))
        }

        request.callForCodable { (result: Result<SectionListResponse, Error>) in
            switch result {
            case .success(let sections):
                if shouldSaveIntoCache {
                    self.sectionListContentCacheManager = ContentCacheManager<SectionListResponse>()
                    self.sectionListContentCacheManager?.saveContentToCache(sections.sectionList, key: SectionListResponse.cacheKey)
                }
                handleResult(.success(sections.sectionList))
            case .failure(let error):
                handleResult(.failure(error))
            }
        }
    }

    /// Retrieves Arc Collection feeds by alias remotely instead of using the cache. Once the collection is retrieved,
    /// it is loaded into the cache.
    /// - Parameters:
    ///   - alias: A `String` object that brings down a feeds collection
    ///   - index: Index of the search results (Ex: (0..9) -> index = 0, (10..20) -> index = 10)
    ///   - size: size of the collections result
    ///   - shouldSaveIntoCache: A boolean to indicate whether the fetched results should save into cache
    ///   - handleResult: The completion handler to call when the request is complete.
    ///   It contains the `Result` type with an array of content data objects ``ArcXPContentList`` \
    ///   if available else the descriptive error object detailing the failure.
    func fetchRemoteCollectionResults(alias: ArcXPContentID,
                                      index: Int,
                                      size: Int,
                                      shouldSaveIntoCache: Bool,
                                      completion: (ArcXPCollectionResultHandler)? = nil) {
        let endpoint = FeedsEndpoint.collection(alias, index: index, size: size)
        guard let request = URLRequest(endpoint: endpoint) else {
            if let completion = completion {
                completion(.failure(NetworkError.URLRequestError(reason: .endpointMalformed)))
            }
            return
        }

        request.callForCodable { [weak self] (result: Result<ContentListResponse, Error>) in
            switch result {
            case .success(let collections):
                if shouldSaveIntoCache, !collections.contentList.isEmpty {
                    self?.saveCollectionsToCache(alias: alias, collectionsList: collections.contentList, index: index, size: size)
                }
                completion?(.success(collections.contentList))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    /// Retrives the content by Id remotely instead of using the cache. Once the content is retrieved, it is loaded into the cache.
    /// Story and Gallery content uses the same API to get data by id. For better readability two functions are provided
    /// for story and Gallery, but internally they call the same method below.
    /// - Parameters:
    ///   - identifier: A `String` object that represents the content's id
    ///   - shouldSaveIntoCache: A boolean to indicate whether the fetched results should save into cache
    ///   - handleResult: The completion handler to call when the request is complete.
    ///   It contains the `Result` type with a content ``ArcXPContent``object \
    ///   if available else the descriptive error object detailing the failure.
    func fetchRemoteContentById(identifier: ArcXPContentID,
                                shouldSaveIntoCache: Bool,
                                handleResult: (ArcXPStoryResultHandler)? = nil) {
        let endpoint = FeedsEndpoint.contentById(identifier)
        guard let request = URLRequest(endpoint: endpoint) else {
            if let handleResult = handleResult {
                handleResult(.failure(NetworkError.URLRequestError(reason: .endpointMalformed)))
            }
            return
        }

        request.callForCodable { (result: Result<ArcXPContent, Error>) in
            switch result {
            case .success(let storyContent):
                if shouldSaveIntoCache {
                    let cacheKey = ArcXPContent.cacheKey + ".\(identifier)"
                    self.storyContentCacheManager = ContentCacheManager<ArcXPContent>()
                    self.storyContentCacheManager?.saveContentToCache(storyContent, key: cacheKey)
                    LoggingManager.log("Saving story into cache", level: .debug)
                }
                handleResult?(.success(storyContent))
            case .failure(let error):
                handleResult?(.failure(error))
            }
        }
    }
}

// MARK: - Bulkloading Functions
extension ArcXPContentClient {

    /// Save collections  to the cache for a given alias. Paginated collecitons would append to the existing items in the cache and saved.
    /// - Parameters:
    ///   - alias: A string object to represent the alias
    ///   - collectionsList: A list of `ArcXPContent` items to be saved in the cache
    ///   - index: Start index of the requested collection results.
    ///   - size: Size of the collections requested
    func saveCollectionsToCache(alias: String, collectionsList: ArcXPContentList, index: Int, size: Int) {
        collectionContentCacheManager = ContentCacheManager<ContentListResponse>()
        let cacheKey = ContentListResponse.cacheKey + ".\(alias)"
        // Append the paginated list for the existing cache to save.
        // Request (index 0: size 5), Existing cache: 5  => Override the cached content with the server result as the index is 0
        // Request (index 5: size 5), Existing cache: 5 => Append items to the existing cache list and save to cache, total now->10 elements
        collectionContentCacheManager?.fetchContentFromCache(key: cacheKey) { cacheResult in

            let value = cacheResult.value?.value
            var contentList = collectionsList
            if let cachedAnsContent = value,
               !cachedAnsContent.contentList.isEmpty,
               index > 0 {
                contentList = cachedAnsContent.contentList
                let endIndex = index+size
                if endIndex > contentList.count {
                    contentList.append(contentsOf: collectionsList)
                }
                // The else case will not happen, since the range is within the array size and \
                // so, it will be returned from cache avoiding to reach here.
            }
            self.collectionContentCacheManager?.saveContentToCache(contentList, key: cacheKey)
            LoggingManager.log("Saving collections into cache", level: .debug)
        }
    }
}
