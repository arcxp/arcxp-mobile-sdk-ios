//  Copyright © 2019 The Washington Post Company. All rights reserved.

import ArcXP

import UIKit

/// Adjusts first-responder views to stay out of the way of a keyboard. To use
/// it, a view controller should declare a property for it, then initialize it
/// in `viewWillAppear(animated:)` and nullify it in `viewDidDisappear`. Then,
/// whenever the first responder (typically a text field or text area) changes,
/// the view controller should set the manager's `firstResponder` field
/// accordingly.
public class KeyboardManager: NSObject {

    // MARK: - Properties

    /// The `UIResponder` (typically a `UITextField` or `UITextArea`) that
    /// the manager will move up and out of the way when the keyboard appears.
    /// The view controller must set this when its first responder changes so
    /// that the `KeyboardManager` knows which view can't be blocked by the
    /// keyboard.
    public var firstResponder: UIResponder? {
        didSet {
            oldValue?.resignFirstResponder()
        }
    }

    /// The keyboard height. This is set in `keyboardWillShow()`.
    private var keyboardHeight: CGFloat?

    /// The root-level view of a view controller.
    private var rootView: UIView

    // MARK: - Initialization

    /// Create the manager with a specific root view that will be moved up to
    /// keep the first responder visible when the keyboard is shown.
    public init(rootView: UIView) {
        self.rootView = rootView
        super.init()

        // Add a gesture to dismiss the keyboard when tapping anywhere outside
        // of it.
        // Props to https://stackoverflow.com/a/38283424/665456.
        let tapToDismissKeyboard = UITapGestureRecognizer(target: self,
                                                          action: #selector(tappedRootView(sender:)))
        tapToDismissKeyboard.cancelsTouchesInView = false
        rootView.addGestureRecognizer((tapToDismissKeyboard))

        start()
    }

    deinit {
        stop()
    }

    /// Register the root view for keyboard show & hide notifications. Since
    /// this is called by `init()`, do not call it explicitly elsewhere unless
    /// you've explicitly `stop()`ped it.
    func start() {
        registerForKeyboardEvents()
    }

    /// Unregister the root view from keyboard show & hide notifications.
    func stop() {
        unregisterForKeyboardEvents()
        keyboardHeight = nil
    }

    /// Adjust the first responder view up and out of the way so that it's not
    /// blocked by the keyboard.
    func move() {
        guard let firstResponder = firstResponder as? UIView,
            let keyboardHeight = keyboardHeight else {
                return
        }

        let rootViewVisibleFrameBottomY = rootView.frame.height - keyboardHeight
        let fieldRectInRootViewRect = firstResponder.convert(firstResponder.bounds, to: rootView)
        let fieldFrameBottomY = fieldRectInRootViewRect.origin.y + fieldRectInRootViewRect.height

        let fieldYAdjustment = rootViewVisibleFrameBottomY - fieldFrameBottomY - rootView.layoutMargins.bottom

        if fieldYAdjustment < 0 {
            let adjustedViewFrame = CGRect(origin: CGPoint(x: 0.0, y: fieldYAdjustment),
                                           size: rootView.frame.size)
            animateKeyboard(to: adjustedViewFrame)
        }
    }

    // MARK: - Actions/Events

    @IBAction func tappedRootView(sender: Any?) {
        firstResponder = nil
    }

    @objc func keyboardWillShow(notification: Notification) {
        let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        keyboardHeight = value?.cgRectValue.height
        move()
    }

    func animateKeyboard(to newFrame: CGRect) {
        UIView.animate(withDuration: 0.5,
                       delay: 0.0,
                       options: .curveEaseIn,
                       animations: { [weak self] in
                        self?.rootView.frame = newFrame
                       },
                       completion: nil)
    }

    @objc func keyboardWillHide(notification: Notification) {
        let adjustedViewFrame = CGRect(origin: CGPoint(),
                                       size: rootView.frame.size)
        animateKeyboard(to: adjustedViewFrame)
    }

    func registerForKeyboardEvents() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }

    func unregisterForKeyboardEvents() {
        // There is no need to remove observers from the `NotificationCenter`
        // that were added with addObserver(_:selector:name:object:).
        // https://developer.apple.com/documentation/foundation/notificationcenter/1415360-addobserver
    }

}
