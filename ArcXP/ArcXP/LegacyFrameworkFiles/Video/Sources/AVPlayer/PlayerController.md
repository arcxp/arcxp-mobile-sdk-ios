# ``ArcXPVideo/Player Controller``

The ``PlayerController`` is the most important component of the ArcXPVideo SDK that you'll interact with. By controlling the `AVPlayer` via the ``PlayerController``, you will ensure that the SDK will make all of the callbacks that it supports. 

## Choose the player UI

The `ArcXPVideo` framework supports two player UIs:

* ``ArcMediaPlayerViewController``
  * Fully customizable to match your app's look and feel.
  * More callbacks for keeping track of the player state.
  * **Must be embedded in another view controller.** You can even have multiple instances in the same view controller, such as for displaying search results.

* `AVPlayerViewController`
  * Apple's standard player, used in Safari and many apps
  * Works best as a standalone view controller
  * Limited UI customizability

Most framework features apply to both player UIs, unless otherwise stated.

Both player UIs can be added either to a storyboard, or programmatically. The next step shows how to do this with the ``ArcMediaPlayerView``. If you choose to use an `AVPlayerViewController`, set it up as you would any other view controller, then skip to the **Get the Player Controller** step.

## Add the ArcMediaPlayerViewController

### Add it to a storyboard

**The ``ArcMediaPlayerViewController`` must be embedded in a container view in another view controller.**

> **Never** use the ``ArcMediaPlayerView`` directly in a storyboard. On its own, it will not respond most user interactions or make callbacks to the delegate (see below).

1. Show the UI component library by selecting **View > Show Library** in the menu bar or pressing `shift + command + L`).

2. Drag a **Container View** into your view controller. This will automatically add an empty view controller and an **embed segue** from the container to the empty view controller. Add whatever constraints you wish; this will set the size of the player.
    ![Drag a container view into your view controller](Resources/add_container_to_view_controller.gif)

3. Delete the empty view controller. (This will also delete the embed segue.)

4. Drag a **Storyboard Reference** into your storyboard.

5. `control` + drag a segue from the container view to the storyboard reference.
    ![Create a storyboard reference](Resources/add_storyboard_reference.gif)

6. Give the segue a unique identifier. This example uses `embedPlayer`.

7. In the storyboard reference's **Attributes Inspector**, set the **Storyboard** name to ``ArcMediaPlayerViewController``, and the **Bundle** to `com.washingtonpost.arc.ArcXPVideo`.

8. In your view controller, add a property for the ``ArcMediaPlayerViewController``:

   ```swift
   var playerViewController: ArcMediaPlayerViewController?
   ```
 
9. In the view controller's `prepareForSegue(for:sender:)`, check for the embed segue and use the segue to assign a value to your ``ArcMediaPlayerViewController`` property:

	```swift
	public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
	    if let segueId = segue.identifier,
	        let playerVC = segue.destination as? ArcMediaPlayerViewController,
	        segueId == "embedPlayer" {
	        playerViewController = playerVC
	    }
	}
	```

10. Continue to the next section, **Get the ``PlayerController``**.

### Add it programmatically

1. In your view controller, add a property for the ``ArcMediaPlayerViewController``:

   ```swift
   var playerViewController: ArcMediaPlayerViewController?
   ```
 
2. In your view controller's `viewDidLoad()` function, load the ``ArcMediaPlayerViewController`` from its storyboard (`ArcMediaPlayerViewController.storyboard`) in the framework bundle:

	```
	playerViewController = ArcMediaPlayerViewController.loadFromStoryboard()
	```

3. Add the ``ArcMediaPlayerViewController`` as a child view controller:

	```
	self.addChild(mediaPlayerVC)
	mediaPlayerVC.didMove(toParent: self)  // DON'T FORGET THIS!
	```

	**Note:** You may also need to implement the other functions listed in the [Managing Child View Controllers in a Custom Container](https://developer.apple.com/documentation/uikit/uiviewcontroller) section of Apple's `UIViewController` documentation.

4. Add the ``ArcMediaPlayerView`` to your view hierarchy:

	```
	let mediaPlayerView = mediaPlayerVC.playerView
	self.view.addSubview(mediaPlayerView)
	// Set up the mediaPlayerView's constraints.
	// Manual positioning (i.e. non-autolayout) is not supported.
	```

5. Removing the ``ArcMediaPlayerViewController``

	If you need to remove the view controller, call its `removeFromParent()` function.
	
6. Continue to the next section, **Get the ``PlayerController``**.

## Get the PlayerController.

Both the ``ArcMediaPlayerViewController`` and the `AVPlayerViewController` have a `playerController` property, whose type is ``PlayerController``. After the initial setup of the view controllers, almost all of your interactions with the player (such as playing, pausing, loading, skipping, and muting) should be via this controller, *not* through the player view controller.

The `playerController` instance _must_ be assigned to a class property so that it won't be destroyed when it goes out of scope. **This is especially important if you're using an `AVPlayerViewController`, which does not retain its `playerView` property.** This should be done in your view controller's `viewDidLoad()` or `viewWillAppear()`.

> Pay careful attention to the names:
> 
> * The ``PlayerController`` _controls_ an `AVPlayer`.
> * The ``ArcMediaPlayerViewController`` and `AVPlayerViewController` control *player views*.

#### In a storyboard

1. In `prepare(for:sender:)`, assign the player view controller to an instance property.

  ```swift
    var playerViewController: ArcMediaPlayerViewController?

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueId = segue.identifier else {
            return
        }

        if segueId == "embedPlayer" {
          playerViewController = segue.destination as? ArcMediaPlayerViewController
        }
    }
  ```

  If you want to decide _at runtime_ which player view controller type to use, your instance property can be of type ``PlayerControllerContainer``, which both ``ArcMediaPlayerViewController`` and `AVPlayerViewController` implement.

  ```swift
    var playerViewController: PlayerControllerContainer?

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segueId == "embedAVPlayerViewController" {
            playerViewController = segue.destination as? AVPlayerViewController
        } else if segueId == "embedArcMediaPlayerViewController" {
            playerViewController = segue.destination as? ArcMediaPlayerViewController
        }
    }
  ```

2. Skip the "Programmatically" step and go to the `viewDidLoad()` step.

#### Programmatically

1. Assign the player view controller to an instance property.

#### In viewDidLoad()

1. Get the `playerController` from the player view controller and assign it to an instance property. 

> This is especially important if you're using an `AVPlayerViewController`, because it does not retain its own `playerController`. If you don't assign it to an instance property, it will be destroyed as soon as it goes out of scope.

```swift
var playerController: PlayerController?

public override func viewDidLoad() {
    super.viewDidLoad()
    playerController = playerControllerContainer?.playerController
}
```

> **Note:** **Why do this in `viewDidLoad()` instead of in `prepareForSegue()`?** The ``PlayerController`` can't be initialized until the root view of the view controller that contains it has been initialized. `prepareForSegue()` is called _before_ `viewDidLoad()`, so the root view is still `nil` at that point.


## Note for tvOS when embedding a player view controller

In order for the video player to receive play/pause events from the TV remote, you must do the following in the view controller that embeds the player view controller:

1. Override the `preferredFocusEnvironments` property (from `UIFocusEnvironment`) to return an array that contains the player view controller or its `view` (aka the ``ArcMediaPlayerViewController/playerView``). You may want additional logic to do so only if a video is playing, such as in this example from the sample app:

  ```
  public override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if isPlaying {
            return [playerViewController]
        } else {
            return super.preferredFocusEnvironments
        }
  }
  ```

2. After the video is loaded, to call `setNeedsFocusUpdate()` on your view controller. This will call `preferredFocusEnvironments` to set the focus on the player view.

If you have multiple players embedded in the same view controller, it's up to you to manage which one has focus at any given time.
