# Using Content Features with Arc XP iOS SDK

The Content service in the Arc XP iOS SDK enables you to fetch and display various types of content within your application. The content can range from articles, including their full texts, to links for media, such as images and videos. This document will provide you with an understanding of how to utilize the Content service effectively.

If you haven't already downloaded and installed the Arc XP iOS SDK, please refer to our [Getting Started with Arc XP iOS SDK](getting-started-initialization.md) guide, which includes step-by-step instructions for downloading, installing, and configuring the framework.

To access content from your ArcXP Content backend, you'll primarily interact with the `ArcXPContentClient` class. A shared instance of this class is available as the `ArcXPContentManager.client` property. By invoking the methods of `ArcXPContentClient` on this shared instance, you can seamlessly access any available content.

Results are returned in a completion block with varying `Result` types, meaning you'll either receive a specific type of value, or you'll receive an error.

## How to Fetch Content

The following example demonstrates how to fetch a story using a provided ID:

```swift
ArcXPContentManager.client.getStoryContent(identifier: <#ID#>) { result in

    // Check the result for a success or failure.
    switch result {
    case .succcess(let result):
        // Handle the result
    case .failture(let error):  
        // Handle the error 
    }  
}
```  
  
Below is an overview of the various fetching methods available with `ArcXPContentClient`.

## Fetching Content

### Get Story Content

Fetches the content of a story based on its unique identifier, with an optional parameter to bypass the cache.

```swift
func getStoryContent(
    identifier: ArcXPContentID,
    shouldIgnoreCache: Bool = false,
    handleResult: @escaping ArcXPStoryResultHandler)
```

### Get Gallery Content

Retrieves a gallery's content using its identifier, with an option to ignore the cache.

```swift
func getGalleryContent(
    identifier: ArcXPContentID,
    shouldIgnoreCache: Bool = false,
    handleResult: @escaping ArcXPStoryResultHandler)
```

### Get Raw JSON Content

Fetches raw JSON content based on the request type and an optional identifier or alias.

```swift
func getRawJsonContent(  
    requestType: RequestType,
    identifierOrAlias: ArcXPContentID? = nil,
    handleResult: @escaping (Result<String, Error>) -> Void)
```

## Collections and Sections

### Get Collection

Obtains a content collection based on its alias, with optional pagination and cache control parameters.

```swift
func getCollection(
    alias: ArcXPContentID, 
    index: Int = PaginationDefaults.startIndex,
    size: Int = PaginationDefaults.maxResults,  
    shouldIgnoreCache: Bool = false, 
    handleResult: @escaping ArcXPCollectionResultHandler)
```

### Get Section List

Fetches a list of sections based on the site hierarchy, with an optional parameter to bypass the cache.

```swift
func getSectionList(
    siteHierarchy: String,
    shouldIgnoreCache: Bool = false,
    handleResult: @escaping ArcXPSectionListHandler)
```

## Searching for Content

### Search

Performs a general content search using an array of keywords, with optional pagination parameters.
  
```swift
func search(  
    by keywords: [String],
    index: Int = PaginationDefaults.startIndex,
    size: Int = PaginationDefaults.maxResults,
    handleResult: @escaping ArcXPCollectionResultHandler) 
```

### Search (Async/Await version)

(Async/Await version) Performs a general content search using an array of keywords and optional pagination parameters, returning an ArcXPContentList asynchronously.

```swift 
func search(
    by keywords: [String],  
    index: Int = PaginationDefaults.startIndex,
    size: Int = PaginationDefaults.maxResults) async throws -> ArcXPContentList
```

### Search Videos

Searches for videos using an array of keywords, with optional pagination parameters. The completion block processes the resulting video content list.

```swift
func searchVideos(
    by keywords: [String],
    index: Int = PaginationDefaults.startIndex,
    size: Int = PaginationDefaults.maxResults, 
    handleResult: @escaping ArcXPCollectionResultHandler)
```
  
## Additional information regarding SDK functionality

### Caching

Content fetched using the SDK is automatically cached. When attempting to fetch content again, the cache is checked first. However, you can bypass the cache to ensure the latest data is retrieved from the backend by passing `true` as the `ignoreCache` parameter in the fetch method.

### Preloading

The SDK can preload all elements returned in a collection when it is fetched, with the default value set to `true`. This feature stores articles fetched with each collection call in the cache for offline usage, but it does not download images and videos of preloaded articles.

### Pagination

To prevent excessive data retrieval at once, the SDK returns paginated data. All methods, except `getSectionList()`, have optional parameters to specify a starting value and a page size. You can set the from parameter to indicate the starting record and the size parameter to define the number of records to return from that point. Paginated data is returned as a map rather than a list, with the key value representing the index of the result. This approach allows client code to determine the index of the last value returned and set a starting index for the next query.
