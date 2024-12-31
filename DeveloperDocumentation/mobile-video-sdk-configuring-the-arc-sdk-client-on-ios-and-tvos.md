# Mobile Video SDK - Configuring the Arc SDK Client on iOS and tvOS

The `ArcMediaClient` protocol provides `ArcVideo` objects that can be played in the media player. The `ArcMediaRealClient` is an implementation that gets video-on-demand and streaming content from the Arc XP Video Center.

## Steps
1. Initialize the client with the `organizationID`, which is a *String* that will be assigned to you when you sign up for Arc XP. It may look something like `<name>-prod` or `<name>-staging`.

```swift
let client = ArcMediaRealClient(organizationID: “arc-staging”)
```

The initializer also two optional arguments:

| **Argument** | **Type** | **Description** |
|----|---|---|
| `enableLivestreamAds` | Boolean | True if livestream videos should show ad breaks during the stream. The default value is `true`. |
| `useGeoRestrictions` | Boolean | True if the user’s general location should be used to check whether videos may be played there. The default is `false`. <br />Note that this does **not** use iOS location services, and thus doesn't require the user to grant Location Services access to your app. Instead, it checks the **general** location from where the request was sent. |

2. The client has a single function to get a video:
```swift
video(forOrganizationName:mediaID:adSettings:accessToken:handleResult:)
```

Its arguments are:

* `forOrganizationName`: This is a `String` that will be assigned to you when you sign up for Arc services. It may look something like `“<name>-prod”` or `“<name>-staging”`.
* `mediaID`: An `ArcMediaID` object (currently just a `typealias` for `String`). This may look something like `“67b34cf2-cd6a-4b46-a40b-1e6437ae0c64”`.
* `adSettings`: An optional `AdSettings` object. This is outlined in greater detail in the [Ad Configuration Documentation](mobile-video-module-configuring-ads-with-the-ios-sdk.md).
* `accessToken`: Its type is `ArcAccessToken`, which is another `typealias` for `String`. **This is currently unused, so just pass in an empty string.**
* `handleResult`: A completion block or a function whose signature is `(Result<ArcVideo, Error>) -> Void`. This result will either contain the requested `ArcVideo`, or an error explaining what went wrong.

```swift
let orgName = <your-org-name>
let mediaId = <media-UUID>
client.video(forOrganizationName: orgName,
                mediaID:
                mediaID,
                adSettings: mediaTailorSettings,
                accessToken: accessToken,
                handleResult: { [weak self] (videoResult) in
                    switch videoResult {
                    case .success(let video):
                        // ArcVideo is a subclass of AVFoundation’s AVAsset, so it has to be
                        // wrapped in an AVAssetItem before it can be passed to the player.
                        let playerItem = AVPlayerItem(asset: video)
                        ...
                    case .failure(let error):
                        // Handle the error by logging it or popping up a dialog, as needed.
                    }
                })
```
    
>The `video()` function doesn’t *return* a video. The `handleResult()` block will provide a video object result. The block is invoked asynchronously on the main thread.

3. Play the video by wrapping it in an `AVFoundationAVPlayerItem` and passing it to the player.


## Using a Sample Client

`ArcMediaClient` is also implemented by the `ArcMediaSampleClient`, which may be useful for testing or demonstration purposes. It always returns the same sample video. It’s used the exact same way as the `ArcMediaRealClient`:

```swift
let orgName = <your-org-name>
let mediaId = <media-UUID>
let client = ArcMediaSampleClient()
```

```swift
client.video(forOrganizationName: orgName,
            mediaID: mediaId,
            adSettings: nil,
            accessToken: "",
            handleResult: { [weak self] (videoResult) in
    switch videoResult {
        ...
    }
})
```

The class also has two properties that may be useful for testing:

* `alwaysThrows`: Always returns an error result from the `video()` call’s completion handler.
* `sampleMediaUrl`: The URL for the sample video. This can be set to any media URL you want, including `file:///` URLs for assets bundled with your app.

If you want to support both client types in your app, the SDK provides a static `ArcMediaClientManager.client` property that can be assigned to the desired instance. Your app can then call the client via this static property. Your view controller’s `viewDidLoad()` is a good place to set this up:

```swift
#if DEBUG
ArcMediaClientManager.client = ArcMediaSampleClient()
#else
ArcMediaClientManager.client = ArcMediaRealClient()
#endif
```

Then just call:

```swift
ArcMediaClientManager.client.video(forOrganizationName: orgName,
                        mediaID: mediaID,
                        adSettings: mediaTailorSettings,
                        accessToken: accessToken,
                        handleResult: { [weak self] (videoResult) in

})
```
