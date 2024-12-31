# Mobile Video Module - Customizing the player on iOS

The `ArcMediaPlayerView` can be customized to fit your app's UI design and features. You can get it from the `ArcMediaPlayerViewController`'s `playerView` property.


>Unless otherwise noted, controls are customizable only on iOS, not tvOS, because tvOS uses the remote control instead. Even if the properties are exposed, the outlets are not connected in tvOS.


## Buttons

The default button icons are sourced from [Icons8](https://icons8.com/) and free to use. The default icons use the [IOS Glyphs Style](https://icons8.com/icons/ios-glyphs), have a size of 30x30, and have light and dark mode versions. You can use your own icons instead, but keep in mind that if they're not the same size, the player's layout will be affected.

Some buttons can be hidden, but unless otherwise specified, the _order_ the buttons appear in, and their positions in the view, cannot be changed.

| Name | Type | Description |
| --- | :------ | :------ |
| `closedCaptionsButton` | [UIButton](https://developer.apple.com/documentation/uikit/uibutton#) | Toggles closed-captioning (if available) on and off. |
| `controlBarPlayButton` | [UIButton](https://developer.apple.com/documentation/uikit/uibutton#) | Toggles between playing and pausing the video. The Play icon is used in the button's `.default` state, while the Pause icon is used in its `.selected` state. |
| `fullScreenButton` | [UIButton](https://developer.apple.com/documentation/uikit/uibutton#) | Toggles the player between full screen and the its original size and location. |
| `goBackwardButton` | [UIButton](https://developer.apple.com/documentation/uikit/uibutton#) | Skips to the beginning of the video, or rewinds if pressed continuously. |
| `goForwardButton` | [UIButton](https://developer.apple.com/documentation/uikit/uibutton#) | Skips to the end of the video (or the next video), or fast-forwards if pressed continuously. |
| `skipBackwardButton` | [UIButton](https://developer.apple.com/documentation/uikit/uibutton#) | Rewinds the video by a certain number of seconds.  <br /> The default icon displays 15. If you change this to an icon with a different value, you must _also_ set the `ArcMediaPlayerViewController`'s `goBackwardInterval` to that same value. **Make sure you specify a *negative* number of seconds!**<br />`playerViewController.playerView.skipBackwardButton.setImage(UIImage(named: “back-60-seconds”), for: .normal) playerViewController.goBackwardInterval = CMTime(seconds: -60.0, preferredTimescale: 1)`|
| `skipForwardButton` | [UIButton](https://developer.apple.com/documentation/uikit/uibutton#)  | Skips the video ahead by a certain number of seconds.<br /> The default icon displays 30. If you change this to an icon with a different value, you must *also* set the `ArcMediaPlayerViewController`'s `goForwardInterval` to that same value. **Make sure that you specify a** _**positive**_ **number of seconds!**<br /><br />`playerViewController.playerView.skipBackwardButton.setImage(UIImage(named: “forward-20-seconds”), for: .normal) playerViewController.goBackwardInterval = CMTime(seconds: 20.0, preferredTimescale: 1)` |
| `useSkipBackwardButton` | Bool | Whether the `skipBackwardButton` will be displayed, even if the current video allows skipping. |
| `useSkipForwardButton` | Bool | Whether the `skipForwardButton` will be displayed, even if the current video allows skipping. |
| `volumeButton` | [UIButton](https://developer.apple.com/documentation/uikit/uibutton#) | Pops up a volume slider. (See `mpVolumeView`, below.) <br /> **Note: The icons used for the various volume levels are not currently customizable.** |

## Labels

| Name | Type | Description |
| --- | --- | --- |
| `timeElapsedLabel` | [UILabel](https://developer.apple.com/documentation/uikit/uilabel#) | Shows the video's elapsed time. <br /> There are two formats that are used for the times: one with, and one without, the _hours_. (If _alwaysShowHours_ is true, then the format with _hours_ is always used.) |
| `timeRemainingLabel` | [UILabel](https://developer.apple.com/documentation/uikit/uilabel#) | Shows the video's remaining time. If the video is a livestream, then the label will display “LIVE” instead of a time. <br /> There are two formats that are used for the times: one with, and one without, the _hours_. (If _alwaysShowHours_ is true, then the format with _hours_ is always used.) |
| `alwaysShowHours` | Bool | Set this to _true_ if the time-elapsed & time-remaining labels should always show the _hours_ field. The default is _false_. |
| `durationFormat` | String | The format string for the time-elapsed & time-remaining labels when the time is less than one hour. The default is _mm:ss_. Examples are 31:20 or 04:32. It should _not_ be prefixed with a “-”, as that’s added automatically by the player. |
| `durationFormatWithHours` | String | The format string for the time-elapsed/time-remaining label when the time one hour or greater. The default is _H:mm:ss_. Examples are _1:31:20_ or _2:04:32_. It should _not_ be prefixed with a “-”, as that’s added automatically by the player. |

## Captions

The `ArcMediaPlayerView` supports captions in two different ways:

* Embedded in the video stream 
* Listed in an associated Video Text Track (VTT) file

The appearance and behavior of embedded captions is determined by the operation system or app's accessibility settings, and are not customizable directly in the _ArcMediaPlayerView_.

VTT captions are customizable using the following properties:

| Name | Type | Description |
| --- | --- | --- |
| `closedCaptionsButton` | UIButton | Toggles closed-captioning (if available) on and off. |
| `clientSideCaptionTextColor` | UIColor | The text color for the client-side caption overlay text. The default value is _UIColor.white_. The color should contrast with the _clientSideCaptionTextShadowColor_ so that it will show up clearly, no matter what the underlying video content looks like. |
| `clientSideCaptionTextShadowColor` | UIColor | The text color for the client-side caption overlay text shadow. On iOS, this defaults to `UIColor.darkText`, but since that property isn't available on tvOS, the tvOS default is `.white`. The color should contrast with the `clientSideCaptionTextColor` so that it will show up clearly, no matter what the underlying video content looks like. |

## Other Controls & Views

| Name | Type | Description |
| --- | --- | --- |
| `controlBar` | UIView | The overlay that displays the playback controls. It cannot be positioned elsewhere inside or outside the view, but its behavior can be customized. |
| `mpVolumeView:` | MPVolumeView | The volume slider that appears when the volumeButton is toggled. **Note:** this appears only on iOS devices, not on the simulator. |
| `secondsBeforeControlBarHides` | Double | The number of seconds that the control bar is visible after playback starts. If it's _nil_, then no timer will be set. Instead, you must call _ArcMediaPlayerView.showControlBar()_ and _hideControlBar()_ manually. |
