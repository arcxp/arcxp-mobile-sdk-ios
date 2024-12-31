# Getting Started with Arc XP iOS SDK

The Arc XP iOS SDK offers a seamless integration with various Arc XP services such as Subscriptions, Content, and Video for your iOS applications.

## Services Provided with Arc XP iOS SDK

### Subscriptions

Subscriptions handles user management, using Arc XP's Identity features.

### Content

Content provides access to a wide range of content types, including articles, images, and videos. While video links are obtained from Content, the actual video files are delivered via a separate service detailed below, Video.

### Video

Video is responsible for the delivery of video assets and live streams. By utilizing the data fetched from Content, you can easily retrieve specific video and live stream media for your application.

## Configuration Details

To access the services mentioned above, you must first configure the Arc XP iOS SDK with the necessary details. Ensure you have the following information before proceeding:

### Required Configuration Details

- Host domain/base URL  
- Organization  
- Environment  
- Site

If you do not have access to this information, contact your Technical Account Manager, who will be able to provide the necessary details. Keep in mind that some of these details may differ between services, so it is crucial to obtain the correct information for each service.

## Verifying Your Arc XP Backend Configuration

The Arc XP iOS SDK depends on specific backend functionality that needs to be set up separately. To confirm that your backend is properly configured, test your outbound feeds using the URL below:

Add your base URL to this endpoint:  
`{your base URL}/arc/outboundfeeds/navigation/default`

Example:  
`https://arcsales-arcsales-sandbox.web.arc-cdn.net/arc/outboundfeeds/navigation/default`

A JSON response indicates a successful setup. If you don't receive a JSON response, contact your Technical Account Manager to check if the backend is ready for integration. If further backend configuration is necessary, refer to the following resources:

* [Backend Setup For Mobile SDK](back-end-setup-for-mobile-sdk.md)
* [Resolver Setup For Mobile SDK](mobile-sdk-resolver-setup.md)

Once you've verified that your Arc XP backend is functional, you're ready to begin setting up the Arc XP iOS SDK in your application project.

## Dependencies

### Commerce

To utilize certain features in Commerce, such as social login and reCAPTCHA, you need to include specific dependencies in your project. We recommend using CocoaPods for this purpose. To add these dependencies, include the following lines in your Podfile:

```
pod 'ReCaptcha'  
pod 'GoogleSignIn', "~> 5.0.2"  
pod 'FBSDKLoginKit', "~> 7.1.1"
```

## Installation steps

### Swift Package Manager

1. In Xcode, navigate to your project in the hierarchy, and select the **Package Dependencies** tab.
2. Click the **+** button, and add the following URL for iOS applications: `git@github.com:arcxp/arcxpSDK-iOS-package.git`

    :::note
    If you're building a tvOS app, use this URL instead: `git@github.com:arcxp/arcxpSDK-tvOS-package.git`
    :::

3. In any file that you use the Arc XP iOS/tvOS SDK, make sure to `import ArcXP`.

### CocoaPods

1. In the Podfile add these lines for the sources:

    ```
    source 'https://github.com/CocoaPods/Specs.git'
    source 'git@github.com:arcxp/arc-mobile-podspecs.git'
    ```

2. Add this line in the Podfile to add the framework to your project: `pod 'ArcXP'`
3. Lastly, run the `pod install` command to install the Pod.
4. In any file that you use the Arc XP iOS/tvOS SDK, make sure to `import ArcXP`.

## Configuring Arc XP iOS SDK in Your Application

To configure the Arc XP iOS SDK for the services you want to use, fill in the placeholder parameters in the example code below. Call this code early in your application's lifecycle, such as within the AppDelegate's `application(:didFinishLaunchingWithOptions:)` method:

```
// Configure Commerce
let commerceConfiguration = CommerceConfiguration(baseUrl: <#BASE_URL#>, organization: <#ORG#>, environment: <#ENV#>, site: <#SITE#>)
Services.configure(service: .commerce(commerceConfiguration))

// Configure Content
let contentCacheConfig = ArcXPCacheConfig(cacheTimeUntilUpdate: 10, maxCacheSize: 10, shouldPreloadCache: true)

let contentConfiguration = ContentConfiguration(baseUrl: <#BASE_URL#>, organization: <#ORG#>, environment: <#ENV#>, site: <#SITE#>, thumborResizerKey: <#RESIZER_KEY#>, cacheConfiguration: contentCacheConfig)
Services.configure(service: .content(contentConfiguration))

// Configure Video
let videoConfiguration = VideoConfiguration(organization: <#ORG#>, environment: <#ENV#>)
Services.configure(service: .video(videoConfiguration))
```

| Field | Description |
| --- | --- |
| `orgName, siteName, environment` | The three parts of the base URL for the client account. The URL is of the format https://\[orgName\]-\[siteName\]-\[environment\].cdn.arcpublishing.com. These are set through the method setUrlComponents(). These values will be provided by Arc XP. |
| `maxCacheSize` | Maximum size the cache in MB, can occupy on the device. If it exceeds this size then the SDK will purge items to return it to this value. |
| `cacheTimeUntilUpdate` | After this threshold in seconds has been reached, new data is requested from the backend. |
| `shouldPreloadCache` | If this Boolean is true (defaults to true), the SDK will make network requests for ANS ids for each collection result to preload the database. |
| `baseUrl` | The full base URL of the content endpoint. This value is required. |
| `thumborResizerKey` | Resizer key to avoid downloading larger images than necessary on device and thus incurring unnecessary bandwidth costs |
|The `baseURL` can be determined from your cdn url settings. **Delivery > Choose Site > Default domain name** | ![](images/baseurl.png) |

Now you're ready to begin fetching content for use in your iOS application. For details on how to do so, see [Using the Content part of the iOS SDK](getting-started-with-the-content-module.md).

If you have issues with any of the steps, contact your Technical Account Manager.
