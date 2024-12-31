# Mobile Video SDK - Controlling Video Playback with the iOS SDK

As noted in the [Player Configuration Instructions](getting-started-with-the-video-module.md), you will use the player view controller's `playerController`, *not the player view controller* or *`AVPlayer`* *itself*, to interact with `ArcVideo` objects. Using the player controller will ensure that the player UI's state will stay in sync with the video's playback state, and will allow you to receive callbacks.

## Loading and Playing Videos

After you've configured a player view controller and Video Center client, you're ready to load or play videos.

Look back at the example from the [Client Configuration](mobile-video-sdk-configuring-the-arc-sdk-client-on-ios-and-tvos.md) instructions:

```swift
let orgName = <your-org-name> 
let mediaId = <media-UUID> 
client.video(forOrganizationName: orgName,
            mediaID: mediaID,
            adSettings: mediaTailorSettings,  
            accessToken: accessToken,  
            handleResult: { [weak self] (videoResult) in  
                switch videoResult { 
                case .success(let video): 
                    // ArcVideo is a subclass of AVFoundation's AVAsset, so it has to be  
                    // wrapped in an AVAssetItem before it can be passed to the player.  
                    let playerItem = AVPlayerItem(asset: video)  
                    ...  
                case .failure(let error):
                    // Handle the error by logging it or popping up a dialog, as needed.  
                } 
            }) 
```

In the `case .success(let video)`, pass the `video` object to the player controller, you can either load the video and play it later:

```swift
     case .success(let video): 
    let playerItem = AVPlayerItem(asset: video) 
    playerController.load(playerItem: playerItem)  
    
    // Call playerController.play() directly at some future point, or let the user play 
    // it by tapping the player view's play button. 
```

or load and play it immediately:

```swift
     case .success(let video): 
    let playerItem = AVPlayerItem(asset: video)  
    playerController.play(playerItem: playerItem) 
```

Loading calls `AVPlayerDelegate.player(_,currentItemChangedFrom:)`. Playing calls `AVPlayerDelegate.player(_:resumed:)`.

## Pausing and unpausing videos

You can programmatically pause the video, or toggle between play and pause. The latter takes care of remembering the current state, so you don't have to keep track of it yourself. `isPlaying` lets you check the current playback state.

Pausing calls `AVPlayerDelegate.player(_:paused:)`, and toggling back to playing calls `AVPlayerDelegate.player(_:resumed:)`.

## Other functions

| Function | Description |
| --- | --- |
| `mute()` and `unmute()` | These call AVPlayerDelegate.playerMuted() and AVPlayerDelegate.playerUnmuted().<br /> Note that unlike togglePlayAndPause(), there is not currently a toggleMuteAndUnmute(). |
| `jumpToBeginning()` and `jumpToEnd()` | Sets the playhead to the beginning or end of the video.  <br /> Both functions call AVPlayerDelegate.player(`_:item:skippedTo:`). |
| `seek(to:)` | There are two versions of this function: one takes a Float playback percentage (from 0.0 to 1.0, inclusive), and the other takes a specific CMTime: <br /> * `PlayerController.Seek(to: 0.6)` // jump to 60% <br /> * `PlayerController.Seek(to: CMTime(value: 16.0, timescale: 1))` // jump to the 16-second mark. <br /> Both functions call AVPlayerDelegate.player(`_:item:skippedTo:`). |
| `skipBackward(interval:)` and `skipForward(interval:)` | Skips backward or forward the specific time interval, but never past the beginning or end of the video, respectively. <br /> Both functions call AVPlayerDelegate.player(`_:item:skippedTo:`). |
