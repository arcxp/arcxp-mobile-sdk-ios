# Mobile Video Module - Configuring Closed Captioning on iOS and tvOS

The **ArcMediaPlayer** module supports two kinds of closed captions:

* Captions that are embedded in the video stream data (“embedded captions”).
* Captions that are contained in an associated [Video Text Track](https://en.wikipedia.org/wiki/WebVTT) `.vtt` file (“client-side captions”).

Each asset will support one or the other type, but never both. Furthermore, VTT captions are supported only in on-demand (VOD) videos.

|  | Embedded captions | Client-side captions |
| --- | --- | --- |
| **Video-on-Demand (VOD)** | ✅ | _ArcMediaPlayerViewController_ only |
| **Livestream Video** | ✅ | n/a |

## Embedded Captions

Embedded captions are configured in Arc Video Center, which encodes them into the video stream. Captions are styled according to the operating system's accessibility settings. No further configuration has to be done in the **ArcMediaPlayer** framework.

## Client-Side Captions

If no captions are embedded in a stream, but there's an associated `.vtt` file, the `ArcVideo` object that's returned by the `ArcMediaClient` will contain the URL for the `.vtt` file. When the video is played in an `ArcMediaPlayerView`, the captions will be displayed in the view's `captionsLabel`, which is in a fixed position in the bottom third of the player view. There are two properties for customizing the look of the `captionsLabel`:

* `clientSideCaptionTextColor`: The color of the captioning text. The default is `UIColor.white`.
* `clientSideCaptionTextShadowColor`: The color of the text drop shadow. The default on iOS is `UIColor.darkText`, and on tvOS, it's `UIColor.darkGray`.


>VTT captions are available _only_ when using the `ArcMediaPlayerViewController`, not Apple's `AVPlayerViewController`.


## Displaying Captions

There are two ways to toggle captions on and off:

|   | Embedded (iOS) | Embedded (tvOS) | Client-side (iOS) | Client-Side (tvOS) |
| --- | --- | --- | --- | --- |
| **User Interface CC Button** | ✅ |   | ✅ * |   |
| **Programmatically** | ✅ | ✅ | ✅ * | ✅ * |

> \* `ArcMediaPlayerViewController` only

### Player User Interface

#### iOS

Both the `ArcMediaPlayerViewController` and `AVPlayerViewController` have a **CC** button on iOS. If captions are available for a video (either embedded or client-side), the button will be enabled. Press it to toggle captions on and off. Note that if you're using the `ArcMediaPlayerViewController`, and captions are toggled off, the button's alpha value will be 50%.

#### tvOS

For tvOS, _only_ the `AVPlayerViewController` has a UI for toggling captions. It can be accessed by sliding down from the top of the remote control touch surface, then selecting the appropriate option.

### Programmatically

#### `ArcMediaPlayerViewController`

For both tvOS and iOS, there are 3 functions on the `ArcMediaPlayerViewController` for captions: `showClosedCaptions()`, `hideClosedCaptions()`, and `toggleClosedCaptions(_)`. If the current video doesn't have any captions, these won't do anything.

#### `AVPlayerViewController`

Unlike the custom `ArcMediaPlayerViewController`, the `AVPlayerViewController` itself does not control captioning. Instead, you have to toggle captioning on the `AVPlayerItem` that's currently playing (i.e. `AVPlayer.currentItem`). The SDK adds functions for doing this:

* `AVPlayerItem.showEmbeddedCaptions()`
* `AVPlayerItem.hideEmbeddedCaptions()`
* `AVPlayerItem.hasEmbeddedCaptions()`: determines whether the stream even contains captions


>These functions work only for captions that are embedded in the stream. **`AVPlayerViewController`** **does not support client-side (VTT) captions.**
