# Mobile Video Module - Callbacks on iOS and tvOS

The Arc Mobile Video module for iOS and tvOS offers a huge number of different callbacks to hook into the player's behavior. The callbacks are available with both the `ArcMediaPlayerViewController` and the `AVPlayerViewController`, though specific callbacks may only be available for certain view controllers.

By using the `AVPlayerController` to control video playback (as opposed to the player view controller or `AVPlayer` directly), you can register for and receive callbacks for many player and ad lifecycle events. These can be used to update your app's UI, perform analytics, and anything else you can think of.

The tables below are split into four columns, for the two player view controllers (`ArcMediaPlayerViewController` and `AVPlayerViewController`), and the two supported platforms (iOS and tvOS).

**All of the delegate functions have empty default implementations**, so implement only the ones you're interested in. The sample app implements them by adding entries to an event timeline table while a video plays.

## AdDelegate

Implement the **AdDelegate** protocol to receive ad-related callbacks. You **don't** need to implement these in order to report back to the ad service; the module handles that for you. Assign your implementation to the player controller's `adController?.adDelegate` property.

[comment]: # (There was a broken link to MediaTailor.Avail.Ad in the following paragraph. Not clear where this should point to. Removed as a temporary fix)

For all callbacks that take an `adInfo:` parameter, you can cast the value to either a `MediaTailor.Avail.Ad` (in the module) or a [Google IMAAd](https://developers.google.com/interactive-media-ads/docs/sdks/ios/client-side/reference/Classes/IMAAd) to get more information, such as the ad ID. See the sample app's `DelegateEventsViewController.logAd(_,_)` for an example.

| **Callbacks** | **Function** | **iOS ArcMediaPlayer** | **iOS AVPlayer** | **tvOS ArcMediaPlayer** | **tvOS AVPlayer** |
| --- | --- | --- | --- | --- | --- |
| Ad break started (livestream only) | `player(_:adBreakStarted:)` | ✅ | ✅ | ✅ | ✅ |
| Ad completed | `player(_:adCompleted:)` | ✅ | ✅ | ✅ | ✅ |
| Ad break ended (livestream only) | `player(_:adBreakEnded:)` | ✅ | ✅ | ✅ | ✅ |
| Ad error | `player(_:adInfo:adError:)` | ✅ | ✅ | ✅ | ✅ |
| Ad started | `player(_:adStarted:)` | ✅ | ✅ | ✅ | ✅ |
| Ad paused | `player(_:adPaused:)` | ✅ | ✅ | ✅ | ✅ |
| Ad resumed | `player(_:adResumed:)` | ✅ | ✅ | ✅ | ✅ |
| Ad skipped (pre-roll ads only) | `player(_:adSkipped:)` | ✅ | ✅ | ✅ | ✅ |
| Ad played 25% | `player(_:adPlayed25Percent:)` | ✅ | ✅ | ✅ | ✅ |
| Ad played 50% | `player(_:adPlayed50Percent:)` | ✅ | ✅ | ✅ | ✅ |
| Ad played 75% | `player(_:adPlayed75Percent:)` | ✅ | ✅ | ✅ | ✅ |
| Ad tapped (pre-roll ads only) | `player(_:adTapped:)` | ✅ | ✅ | ✅ | ✅ |
| Ad impression (livestream only) | `player(_:adImpression:)` | ✅ | ✅ | ✅ | ✅ |
| Ad clicked | `player(_ player: AVPlayer, adClicked: **Any**?)` | ✅ | ✅ | ✅ | ✅ |
| Ad will open external application |  `playerAdWillOpenExternalApplication(player: AVPlayer)` | ✅ | ✅ | ✅ | ✅ |
| Ad will open in-app link | `playerAdWillOpenInAppLink(player: AVPlayer)` | ✅ | ✅ | ✅ | ✅ |
| Ad did open in-app link | `playerAdDidOpenInAppLink(player: AVPlayer)` | ✅ | ✅ | ✅ | ✅ |
| Ad will close in-app link | `playerAdWillCloseInAppLink(player: AVPlayer)` | ✅ | ✅ | ✅ | ✅ |
| Ad did close in-app link | `playerAdDidCloseInAppLink(player: AVPlayer)` | ✅ | ✅ | ✅ | ✅ |

## AVPlayerDelegate

Implement the AVPlayerDelegate protocol to receive callbacks for the video player and video lifecycle events. Assign your implementation to the player controller's `delegate` property.

Note that the `AVPlayerDelegate` protocol also extends the `AdDelegate` protocol.

| **Callbacks** | **Function** | **iOS ArcMediaPlayer** | **iOS AVPlayer** | **tvOS ArcMediaPlayer** | **tvOS AVPlayer** |
| --- | --- | --- | --- | --- | --- |
| Captions on | `player(_:captionsOn:)` | ✅ |   | ✅ |   |
| Captions off | `playerCaptionsOff(_)` | ✅ |   | ✅ |   |
| Current item changed | `player(_:currentItemChangedFrom:)` | ✅ | ✅ | ✅ | ✅ |
| Player error | `player(_:error:)` | ✅ | ✅ | ✅ | ✅ |
| Player appeared | `playerAppeared(_)` | ✅ |   | ✅ |   |
| Player ready | `playerReady(_)` | ✅ | ✅ | ✅ | ✅ |
| Player status unknown | `player(_:statusUnknown)` | ✅ | ✅ | ✅ | ✅ |
| Player item error | `player(_:item:error:)` | ✅ | ✅ | ✅ | ✅ |
| Player item ready | `player(_:itemReady:)` | ✅ | ✅ | ✅ | ✅ |
| Player item status unknown | `player(_:itemStatusUnknown:)` | ✅ | ✅ | ✅ | ✅ |
| Player completed (only for VOD) | `player(_:completed:)` | ✅ | ✅ | ✅ | ✅ |
| Played 25% (only for VOD) | `player(_:played25Percent:)` | ✅ | ✅ | ✅ | ✅ |
| Played 50% (only for VOD) | `player(_:played50Percent:)` | ✅ | ✅ | ✅ | ✅ |
| Played 75% (only for VOD) | `player(_:played75Percent:)` | ✅ | ✅ | ✅ | ✅ |
| Played percent (only for VOD) | `player(_:item:playedPercent:)` | ✅ | ✅ | ✅ | ✅ |
| Player muted | `playerMuted(_)` | ✅ | ✅ | ✅ | ✅ |
| Player unmuted | `playerUnmuted(_)` | ✅ | ✅ | ✅ | ✅ |
| Player volume changed | `player(_:volumeChangedFrom:)` | ✅ | ✅ | ✅ | ✅ |
| Player paused | `player(_:paused:)` | ✅ | ✅ | ✅ | ✅ |
| Player resumed | `player(_:resumed:)` | ✅ | ✅ | ✅ | ✅ |
| Player skipped to time | `player(_:item:skippedTo:)` | ✅ |  | ✅ |   |
| Player started | `player(_:started:byUser:)` | ✅ | ✅ | ✅ | ✅ |

## ArcMediaPlayerViewDelegate

Implement this protocol and assign your implementation to `ArcMediaPlayerViewController`'s `playerView.delegate` to get callbacks that are specific to the `ArcMediaPlayerView`. Note that even though the ArcMediaPlayerView is supported on tvOS, the tvOS version does not have a control bar, so these callbacks will never get called.

| **Callbacks** | **Function** | **iOS ArcMediaPlayer** | **iOS AVPlayer** | **tvOS ArcMediaPlayer** | **tvOS AVPlayer** |
| --- | --- | --- | --- | --- | --- |
| Player view controller bar will appear | `playerViewControlBarWillAppear(_)` | ✅ |   |   |   |
| Player view controller bar did appear | `playerViewControlBarDidAppear(_)` | ✅ |   |   |   |
| Player view controller bar will disappear | `playerViewControlBarWillDisappear(_)` | ✅ |   |   |   |
| Player view controller bar did disappear | `playerViewControlBarDidDisappear(_)` | ✅ |   |   |   |