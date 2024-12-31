# Mobile Video Module - Getting started


## The `ArcMediaPlayer` Module Architecture

The `ArcMediaPlayer` is a module that allows you to play Arc Video Center content in your iOS or tvOS app. The module consists of two main components:

* **The client:** Downloads video content (`ArcVideo`s) from the Arc Video Center server.
* **The video player:** Plays the `ArcVideo`. There are two players to choose from, and both support ads and captions.

This guide explains how to integrate the module into your app. You can also download a sample Xcode project that demonstrates how to do this.

### Prerequisites

* Xcode 12/Swift 5.x
* iOS/tvOS 12.0+
* (Optional) [CocoaPods 1.7](https://cocoapods.org/) and up. This will also require `ruby` and RubyGems. Refer to the CocoaPods installation link for instructions. If you choose not to use CocoaPods, you will have to download and install the Google IMA Ad SDK for iOS & tvOS manually.

## Installation & Setup

Follow the installation and setup instructions in [Getting Started with Arc XP iOS SDK](getting-started-initialization.md)

### Usage

Import the Arc XP iOS SDK by adding this line of code in your source files:
```swift
import ArcXPVideo
```

## Choose and Configure the Player Controller

### 1. Choose the player UI

The `ArcMediaPlayer` module supports two player UIs:

* `ArcMediaPlayerViewController`
* `AVPlayerViewController`

Most of the features apply to both player UIs, unless otherwise stated.

Both player UIs can be added either to a storyboard, or programmatically. The next step shows how to do this with the `ArcMediaPlayerView`. If you choose to use an `AVPlayerViewController`, set it up as you would any other view controller, then skip to step 3, **Get the Player Controller**.

### 2. Add the `ArcMediaPlayerView`

#### To a storyboard

The `ArcMediaPlayerViewController` can be used either as a standalone view controller, or embedded in a container view in another view controller. These instructions are for the latter.


>Never use the `ArcMediaPlayerView` without its view controller, because on its own, it will not respond to many user interactions or make callbacks to the delegate (see below).


##### Steps
1. Show the UI component library by selecting **View > Show Library** in the menu bar or pressing `shift + command + L`.
2. Drag a **Container View** into your view controller. This will automatically add an empty view controller and an **embed segue** from the container to the empty view controller. Add whatever constraints you wish; this will set the size of the player.
3. Delete the empty view controller (this will also delete the embed segue).
4. Drag a **Storyboard Reference** into your storyboard.
5. `control` + drag a segue from the container view to the storyboard reference.
6. Give the segue a unique identifier. This example uses `embedPlayer`.
7. In the storyboard reference's **Attributes Inspector**, set the **Storyboard** name to `ArcMediaPlayerViewController`, and the **Bundle** to `com.washingtonpost.arc.ArcMediaPlayer`.
8. In your view controller, add a property for the `ArcMediaPlayerViewController`: `var playerViewController: ArcMediaPlayerViewController?`
9. In the view controller's `prepareForSegue(for:sender:)`, check for the embed segue and use the segue to assign a value to your `ArcMediaPlayerViewController` property:


```swift
public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let segueId = segue.identifier,  
        let playerVC = segue.destination as? ArcMediaPlayerViewController,  
        segueId == “embedPlayer” {  
            playerViewController = playerVC  
    }
}
```

After you've completed the previous steps, continue to step [3. Get the AVPlayerController](#3-get-the-avplayercontroller).

#### Programmatically

##### Steps
1. In your view controller, add a property for the `ArcMediaPlayerViewController`: `var playerViewController: ArcMediaPlayerViewController?`
2. In your view controller's `viewDidLoad()` function, load the `ArcMediaPlayerViewController` from its storyboard (`ArcMediaPlayerViewController.storyboard`) in the SDK bundle: 
```swift
let storyboard = UIStoryboard(name: “ArcMediaPlayerViewController”, bundle: ArcMediaPlayerSDK.bundle) playerViewController = storyboard.instantiateInitialViewController() as! ArcMediaPlayerViewController
```
3. Add the `ArcMediaPlayerViewController` as a child view controller: `self.addChild(mediaPlayerVC) mediaPlayerVC.didMove(toParent: self) // DON'T FORGET THIS!` 

</br>
    
>You may also need to implement the other functions listed in the [Managing Child View Controllers In A Custom Container](https://developer.apple.com/documentation/uikit/uiviewcontroller) section of Apple’s `UIViewController` documentation.
    

4. Add the `ArcMediaPlayerView` to your view hierarchy: `let mediaPlayerView = mediaPlayerVC.playerView self.view.addSubview(mediaPlayerView) // Set up the mediaPlayerView's constraints. // Manual positioning (i.e. non-autolayout) is not supported.`
5. Removing the `ArcMediaPlayerViewController` If you need to remove the view controller, call its `removeFromParent()` function.
6. Continue to step [3. Get the AVPlayerController](#3-get-the-avplayercontroller).


### 3. Get the `AVPlayerController`

Both the `ArcMediaPlayerViewController` and the `AVPlayerViewController` have a `playerController` property, whose type is `AVPlayerController`. After the initial setup of the view controllers, almost all of your interactions with the player (such as playing, pausing, loading, skipping, and muting) should be via this `playerController`, _not_ through the player view controller.

The `playerController` instance _must_ be assigned to a class property so that it won't be destroyed when it goes out of scope. **This is especially important if you're using an `AVPlayerViewController`, which does not retain its `playerView` property**. This should be done in your view controller's `viewDidLoad()` or `viewWillAppear()`.

Pay careful attention to the names:

* The `AVPlayerController` _controls_ an `AVPlayer`.
* The `ArcMediaPlayerViewController` and `AVPlayerViewController` control _player views_.

#### In a storyboard

In `prepare(for:sender:)`, assign the player view controller to an instance property.

```swift

var playerViewController: ArcMediaPlayerViewController? 

public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    guard let segueId = segue.identifier else {
       return
    }
    
    if segueId == “embedPlayer” { 
        playerViewController = segue.destination as? ArcMediaPlayerViewController  
    }
}
```

If you want to decide _at runtime_ which player view controller type to use, your instance property can be of type `AVPlayerControllerContainer`, which both `ArcMediaPlayerViewController` and `AVPlayerViewController` implement.

```swift

var playerViewController: AVPlayerControllerContainer? 

public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segueId == “embedAVPlayerViewController” {
        playerViewController = segue.destination as? AVPlayerViewController  
    } else if segueId == “embedArcMediaPlayerViewController” {
        playerViewController = segue.destination as? ArcMediaPlayerViewController  
    }
}
```

Skip the “Programmatically” step and go to the `viewDidLoad()` step.

#### Programmatically

Assign the player view controller to an instance property.

#### In `viewDidLoad()`

Get the `playerController` from the player view controller and assign it to an instance property.

This is especially important if you're using an `AVPlayerViewController`, because it does not retain its own `playerController`. If you don't assign it to an instance property, it will be destroyed as soon as it goes out of scope.

```swift
var playerController: AVPlayerController?
public override func viewDidLoad() {
    super.viewDidLoad() 
    playerController = playerControllerContainer?.playerController
}
```

<Aside type='note'>
Why do this in `viewDidLoad()` instead of in `prepareForSegue()`? The `AVPlayerController` can't be initialized until the root view of the view controller that contains it has been initialized. `prepareForSegue()` is called _before_ `viewDidLoad()`, so the root view is still `nil` at that point.
</Aside>

### Note for tvOS when embedding a player view controller

In order for the video player to receive play/pause events from the TV remote, you must do the following in the view controller that embeds the player view controller:

* Override the `preferredFocusEnvironments` property (from `UIFocusEnvironment`) to return an array that contains the player view controller or its `view` (aka `playerView` in the `ArcMediaPlayerViewController`). You may want additional logic to do so only if a video is playing, such as in this example from the sample app:

```swift
public override var preferredFocusEnvironments: [UIFocusEnvironment] {
    if isPlaying {
        return [playerViewController]  
    } else {
        return super.preferredFocusEnvironments
    }
}
```

* After the video is loaded, to call `setNeedsFocusUpdate()` on your view controller. This will call `preferredFocusEnvironments` to set the focus on the player view.

If you have multiple players embedded in the same view controller, it's up to you to manage which one has focus at any given time.
