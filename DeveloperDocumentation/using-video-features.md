# Using Video Features with Arc XP iOS SDK

The Arc XP SDK Video service enables developers to add video fetching, playback, streaming, and customized player views to iOS apps. This guide presents a list of delegate methods for responding to video player related events, facilitating seamless integration and an enhanced user experience. By incorporating the Video service, businesses and media organizations can boost user engagement with high-quality video content.

Notable components include `ArcMediaClientManager` for fetching videos, and `ArcMediaPlayerViewController` for displaying them. Additionally, we list some of the recommended `PlayerDelegate` and `ArcMediaPlayerViewDelegate` methods to manage video behavior and player bar interactions.

For more information on the new `ArcMediaPlayer`, see [Mobile Video Module - Getting started with the iOS SDK](/video-center/developer-docs/mobile-video-module-getting-started-with-the-ios-sdk/).

## Configuration

To use Arc XP iOS SDK Video service, you'll need to set up Video service configuration. Refer to "Getting Started with Arc XP iOS SDK" for guidance on Video service configuration, as well as setting up other Arc XP services.

## Loading and Displaying a Video

To load and display a video, you need to interact with two primary Video service objects: `ArcMediaPlayerViewController` and `ArcMediaClientManager`.

### ArcMediaPlayerViewController

This view controller contains all the necessary views for displaying a video, controlling playback, and managing other player-related features.

### ArcMediaClientManager

This manager is responsible for fetching video content to use with the video player. It communicates with a backend service where the video is stored and provides an `ArcVideo` object. This object can then be passed to an `ArcMediaPlayerViewController` instance for playback.

## Set Up the Video Player View Controller

Create an `ArcMediaPlayerViewController` instance, and set a `delegate` to listen to any player related events that might be reported.

```swift
let playerController = ArcMediaPlayerViewController.loadFromStoryboard()
playerController.playerView.delegate = self
UIViewController().addChild(playerController)
// Set constraints to make sure the the view controller is displayed as desired.
```

In the example above, we referred to the `ArcMediaPlayerViewController` as `playerController`. To play video content using the `playerController`, you must first fetch a video using the `ArcMediaClientManager`. To do this, you need to provide two pieces of information as parameters:

- Media ID
- Access token

With those two parameters, you're ready to fetch the video, as seen in the following example.

```swift
// Load the video content

ArcMediaClientManager.client.video(
    mediaID: <#ID#>,
    adSettings: nil,  
    accessToken: <#TOKEN#>) { [weak self] result in
      
    switch result {
        case .success(let video):
            let playerItem = AVPlayerItem(asset: video) 
            playerController.play(playerItem: playerItem)
        case .failure:  
            // Handle error
        }  
}
```  
  
## Delegate Events

When setting up the `ArcMediaPlayerViewController`, we recommended setting a `delegate` property, which can be seen above, when we set the `ArcMediaPlayerViewController().playerView.delegate` property. Whatever is set to that property is what will be responsible for responding to any player related events. Below is a list of unique events we've provided with Arc XP iOS SDK.

### PlayerDelegate

This is a list of AVPlayer delegate methods for video behavior, separate from Arc XP player views. These functions inform on player states during playback, including completion, progress percentage, mute/unmute, pause/resume, time skipping, user start, and full-screen presentation start/end.

* Player Completed Item \
    - `func player(_ player: AVPlayer, completed item: AVPlayerItem?)`  
* Player Played 25% Video \
    - `func player(_ player: AVPlayer, played25Percent video: AVPlayerItem?)`  
* Player Played 50% Video \
    - `func player(_ player: AVPlayer, played50Percent video: AVPlayerItem?)`  
* Player Played 75% Video \
    - `func player(_ player: AVPlayer, played75Percent video: AVPlayerItem?)`  
* Player Muted \
    - `func playerMuted(_ player: AVPlayer)`  
* Player Unmuted \
    - `func playerUnmuted(_ player: AVPlayer)`  
* Player Paused Video \
    - `func player(_ player: AVPlayer, paused video: AVPlayerItem?)`  
* Player Resumed Item \
    - `func player(_ player: AVPlayer, resumed item: AVPlayerItem?)`  
* Player Skipped Item to Time \
    - `func player(_ player: AVPlayer, skipped item: AVPlayerItem?, to time: CMTime)`  
* Player Started Video by User \
    - `func player(_ player: AVPlayer, started video: AVPlayerItem?, byUser: Bool)`  
* Player Tapped Item \
    - `func playerTapped(_ player: AVPlayer, item: AVPlayerItem?)`  
* Player Began Full-Screen Presentation \
    - `func playerBeganFullScreenPresentation(_ player: AVPlayer, item: AVPlayerItem?)`  
* Player Ended Full-Screen Presentation \
    - `func playerEndedFullScreenPresentation(_ player: AVPlayer, item: AVPlayerItem?)`

### ArcMediaPlayerViewDelegate

This list contains Arc XP player view delegate methods, separate from the `AVPlayer`. These functions inform on control bar behavior, such as appearance and disappearance, enabling the ability to respond to changes in the player interface.

* Player View Control Bar Did Appear \
    - `func playerViewControlBarDidAppear(_ playerView: ArcMediaPlayerView)`  
* Player View Control Bar Will Appear \
    - `func playerViewControlBarWillAppear(_ playerView: ArcMediaPlayerView)`  
* Player View Control Bar Did Disappear \
    - `func playerViewControlBarDidDisappear(_ playerView: ArcMediaPlayerView)`  
* Player View Control Bar Will Disappear \
    - `func playerViewControlBarWillDisappear(_ playerView: ArcMediaPlayerView)`
