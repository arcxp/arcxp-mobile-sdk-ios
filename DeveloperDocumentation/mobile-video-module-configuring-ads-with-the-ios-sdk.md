# Mobile Video Module - Configuring Ads with the iOS SDK

The ArcMediaPlayer module currently supports two kinds of ads:

* [Google Interactive Media Ads](https://developers.google.com/interactive-media-ads) (hereafter “Google IMA”).** Offers pre-roll ads for on-demand videos (VODs) and livestreams, plus mid-roll and post-roll ads for VODs
* **Arc Server-side Dynamic Ad Insertion (hereafter “Arc DAI”).** Inserts mid-roll ads into livestream videos.

|   | iOS VOD | tvOS VOD\* | iOS Livestream | tvOS Livestream\* |
| --- | --- | --- | --- | --- |
| Google IMA | ✅ | ✅ | pre-roll only | pre-roll only |
| Arc DAI |   |   | ✅ | ✅ |


>Google IMA ads are supported on tvOS apps, but there's a bug that will prevent the TV remote control's play/pause button from working during a video **if the video's Google pre-roll ad was paused and resumed**. We've reported this to Google, and we'll incorporate any fix they provide, when available.

For both types of ads, the Mobile Video SDK handles all of the reporting and tracking for you.

## Google IMA Ads

Google IMA ads are handled by the SDK's `GoogleIMAAdController` class. `GoogleIMAAdController` implements `AdController`, and is already instantiated and assigned to the `AVPlayerController.adController` property for you when you get the player controller from the player **view** controller.

Default IMA ads for your application are configured by passing an **ad tag URL** to the `GoogleIMAAdController`'s `configure(adTagUrl:)` function before playing an ad. Google has sample tag guides for [iOS](https://developers.google.com/interactive-media-ads/docs/sdks/ios/client-side/tags) and [tvOS](https://developers.google.com/interactive-media-ads/docs/sdks/tvos/client-side/tags). Consult your Google ad campaign settings to create ad tags that are specific to your organization and application(s).

```swift
let playerController: AVPlayerController = <...> 

if let adController = playerController.adController as? GoogleIMAAdController {
    adController.configure(adTagUrl: URL(string: “https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=”)!)
}
```

IMA ads can also be customized on a per-video basis by setting the `adTagURL` property on each `ArcVideo` that you load from the module client:

```swift
client.video(forOrganizationName: orgName, 
            mediaID: mediaID, 
            adSettings: mediaTailorSettings,
            accessToken: accessToken,  
            handleResult: { [weak self] (videoResult) in
                switch videoResult {  
                case .success(let video):  
                    video.adTagUrl = URL(string: “https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=”)! 
                    
                    ...  
                } 
            })
```

The `GoogleIMAAdController` class has numerous other public functions and properties, but almost all of them are simply implementations of the various IMA SDK protocols, so you shouldn’t need to change or override any of them.

## Configuring Your App for Arc DAI

Server-side ads do not have an SDK-wide configuration, so there is no corresponding `AdController` implementation for them. Instead, all server-side ads are configured on a per-video basis by passing a `MediaTailorSettings` object to the `ArcMediaClient.video(forOrganizationName:mediaID:adSettings:accessToken:handleResult:)` call.

`MediaTailorSettings` has a number of properties:

*   `adParams`: A `MediaTailorAdParams` object that contains any number of [parameters](https://docs.aws.amazon.com/mediatailor/latest/ug/variables.html), and the SDK passes them to the ad decision server immediately after a video starts. Work with your ad team and/or consult the linked documentation for recommended values.
*   `beaconHeaders`: Advertisement lifecycle and user interaction events during livestream ads are called **tracking events**. Each tracking event fires a **beacon** back to the ad server for reporting and monetization, and `beaconHeaders` are the HTTP headers that are passed with these beacon requests. Consult the linked documentation for recommended values.
*   `mediaTailorHeaders`: A dictionary of HTTP headers that are sent with requests to the ad decision server. Consult the linked documentation for recommended values.
*   `trackingUrl`: A URL that the SDK polls every few seconds to find out what ads will be coming up during playback. **This is used internally, and you should not change it.**

This is an example from the sample app's `NewVideoViewController`:

```swift

let device = UIDevice.current 
let userAgent = “(\(device.model); \(device.systemName) \(device.systemVersion); Scale/1.00)” 
var mediaTailorSettings = MediaTailorSettings() 

mediaTailorSettings.adParams = MediaTailorAdParams(adsParams: ["deviceType": device.model,  
                                                                “[session.user_agent]”: userAgent]) 
mediaTailorSettings.mediaTailorHeaders = ["User-Agent": userAgent] 
mediaTailorSettings.beaconHeaders = ["User-Agent": userAgent]  

ArcMediaClientManager.client.video(forOrganizationName: orgName,  
                                                        mediaID: mediaID, 
                                                        adSettings: mediaTailorSettings, 
                                                        accessToken: accessToken, 
                                                        handleResult: { [unowned self] (videoResult) in
                                                            .... 
                                                        })
```