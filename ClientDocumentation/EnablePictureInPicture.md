# Enable Picture in Picture

## Native Video Players

Enabling Picture-in-Picture for native AVPlayers (the iOS provided AVPlayer, not a customized one) can be done with two simple steps.

First, go to your application project's "**Signing & Capabilities**" view. There, if you don't already have "**Background Modes**" available, click the "+" button to add that section. Under "Background Modes", add a checkmark to "**Audio, Airplay, and Picture in Picture**".

Next, call the following function to enable a background session. Doing so will automatically start a Picture in Picture session when your application is backgrounded.

```
PictureInPictureManager.activatePictureInPictureSession()
```

After following the steps above, picture-in-Picture is now available in your application for native AVPlayers.

If you're only wanting picture-in-picture functionality for native video players, that's all you have to do! However, if you're managing your own custom video player, you'll need to do a few more steps.

## Custom Players

Locate where your custom player is being managed, call `PictureInPictureManager`'s setup function, and provide the associated `AVPlayer` and `UIViewController` instances with it, like this:

```
PictureInPictureManager.setUp(with: AVPlayer, for: viewController)
```

From there, you'll be able to dismiss the app, and see your video player enter picture-in-picture mode, the same way it does for the native player.
