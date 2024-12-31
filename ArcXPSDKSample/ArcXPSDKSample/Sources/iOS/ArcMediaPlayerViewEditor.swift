//  Copyright © 2021 The Washington Post. All rights reserved.

import ArcXP

import SwiftUI
import UIKit

/// A `View` for customizing the properties of the `ArcMediaPlayerView`.
@available(iOS 14.0, *)
struct ArcMediaPlayerViewEditor: View {

    /// The `ArcMediaPlayerView`. If it's `nil`,  then a simple message will
    /// be displayed that tells the user to launch the editor from the
    /// `ArcMediaPlayerView` option in the sample app.
    weak var playerView: ArcMediaPlayerView? = nil // is weak even necessary in a struct?

    /// The action to perform when the editor's close button is tapped. I
    /// don't know of any other way for a SwiftUI `View` that's in a modal
    /// `UIHostingViewController` to dismiss the modal, so the block that's
    /// assigned to this property should do that.
    var closeButtonAction: () -> Void = { }

    var body: some View {
        if let playerView = playerView {  // 'guard let' isn't allowed here.
            VStack(spacing: 8.0) {
                HStack {
                    Text("ArcMediaPlayerView Settings")
                        .font(.headline)
                    Spacer()
                    Button(action: closeButtonAction) {
                        Image(systemName: "xmark.circle.fill")
                    }
                }

                ScrollView {
                    SettingsGroup(title: "Buttons") {
                        UIButtonIconEditor(propertyName: "controlBarPlayButton",
                                           buttonBeingEdited: playerView.controlBarPlayButton)
                        UIButtonIconEditor(propertyName: "fullScreenButton",
                                           buttonBeingEdited: playerView.fullScreenButton)
                        UIButtonIconEditor(propertyName: "goBackwardButton",
                                           buttonBeingEdited: playerView.goBackwardButton)
                        UIButtonIconEditor(propertyName: "goForwardButton",
                                           buttonBeingEdited: playerView.goForwardButton)
                        UIButtonIconEditor(propertyName: "skipBackwardButton",
                                           buttonBeingEdited: playerView.skipBackwardButton)
                        UIButtonIconEditor(propertyName: "skipForwardButton",
                                           buttonBeingEdited: playerView.skipForwardButton)
                        UIButtonIconEditor(propertyName: "volumeButton",
                                           buttonBeingEdited: playerView.volumeButton)
                    }

                    SettingsGroup(title: "Toggles") {
                        BooleanPropertyEditor(playerView: playerView,
                                              propertyName: "useSkipBackwardButton",
                                              property: \ArcMediaPlayerView.useSkipBackwardButton)
                        BooleanPropertyEditor(playerView: playerView,
                                              propertyName: "useSkipForwardButton",
                                              property: \ArcMediaPlayerView.useSkipForwardButton)
                    }

                    SettingsGroup(title: "Captions") {
                        UIButtonIconEditor(propertyName: "closedCaptionsButton",
                                           buttonBeingEdited: playerView.closedCaptionsButton)
                        ColorPropertyEditor(playerView: playerView,
                                            propertyName: "clientSideCaptionTextColor",
                                            property: \ArcMediaPlayerView.clientSideCaptionTextColor)
                        ColorPropertyEditor(playerView: playerView,
                                            propertyName: "clientSideCaptionTextShadowColor",
                                            property: \ArcMediaPlayerView.clientSideCaptionTextShadowColor)
                    }
                }
            }
            .padding(8.0)
        } else {
            Text("The ArcMediaPlayerView isn't visible, so it can't be configured")
        }
    }

    /// A group of related settings.
    struct SettingsGroup<Content: View>: View {

        var title: String

        @ViewBuilder var children: () -> Content

        var body: some View {
            VStack(alignment: .leading, spacing: 8.0) {
                Text(title)
                    .font(.headline)
                children()
                    .padding([.leading], 8.0)
            }
            .padding(8.0)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8.0)
        }

    }

}

/// Allows the user to customize the images for all four `UIControl.State`s of
/// a `UIButton`
@available(iOS 13.0, *)
struct UIButtonIconEditor: View {

    var propertyName: String

    weak var buttonBeingEdited: UIButton?

    @State private var showEditor: Bool = false

    var body: some View {
        VStack(spacing: 8.0) {
            Button(action: { showEditor.toggle() }) {
                HStack(spacing: 8.0) {
                    Text(propertyName)
                        .font(.body)

                    Spacer()

                    ButtonImage(button: buttonBeingEdited, buttonState: .normal)
                }

            }

            // Expand the editor to display the icons for each control state.
            if showEditor {
                VStack(spacing: 8.0) {
                    ButtonStateEditor(state: .normal,
                                      stateName: "Normal",
                                      button: buttonBeingEdited)
                    ButtonStateEditor(state: .selected,
                                      stateName: "Selected",
                                      button: buttonBeingEdited)
                    ButtonStateEditor(state: .highlighted,
                                      stateName: "Highlighted",
                                      button: buttonBeingEdited)
                    ButtonStateEditor(state: .disabled,
                                      stateName: "Disabled",
                                      button: buttonBeingEdited)
                }
            }
        }
    }

    /// Displays a button's image. This can be one of three values:
    ///
    /// * The SFSymbol of the new image, iff `symbolName` is not `nil`;
    /// * The button's existing `UIImage` for the specified `buttonState`; or
    /// * A default icon to indicate that there isn't any new or existing
    /// image.
    struct ButtonImage: View {

        weak var button: UIButton?

        var buttonState: UIControl.State

        var symbolName: String? = nil

        var body: some View {
            if let symbolName = symbolName, !symbolName.isEmpty {
                Image(systemName: symbolName)
            } else if let buttonImage = button?.image(for: .normal) {
                Image(uiImage: buttonImage)
            } else {
                Image(systemName: "photo")
                    .disabled(true)
            }
        }

    }

    struct ButtonStateEditor: View {

        var state: UIControl.State
        var stateName: String
        weak var button: UIButton?

        @State private var symbolName: String = ""

        var body: some View {
            GeometryReader { (proxy) in
                HStack(spacing: 8.0) {
                    let cellHeight = proxy.size.height

                    Text(stateName)
                        .frame(width: proxy.size.width * 0.3, height: cellHeight, alignment: .leading)
                        .font(.headline)
                    TextField("Symbol name",
                              text: $symbolName)
                        .frame(width: proxy.size.width * 0.3, height: cellHeight, alignment: .leading)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Button(action: replaceImage) {
                        Text("Apply")
                    }
                    .frame(width: proxy.size.width * 0.2, height: cellHeight, alignment: .trailing)

                    ButtonImage(button: button, buttonState: state, symbolName: symbolName)
                        .frame(width: proxy.size.width * 0.1, height: cellHeight, alignment: .trailing)
                }
            }
        }

        func replaceImage() {
            if let image = UIImage(systemName: symbolName) {
                button?.setImage(image, for: state)
            }
        }

    }

}

/// Edits a boolean property of the `ArcMediaPlayerView` with a `Toggle`.
@available(iOS 14.0, *)
struct BooleanPropertyEditor: View {

    /// The `ArcMediaPlayerView` whose property is being edited.
    var playerView: ArcMediaPlayerView

    /// The name of the property being edited, which is displayed in the
    /// `Toggle`. I wish that this could be looked up with something like
    /// `String(describing: property)`, but that's hideous.
    var propertyName: String

    /// The `ArcMediaPlayerView`'s boolean property. It has to be a
    /// `ReferenceWritableKeyPath`, not just a `WritableKeyPath`, because the
    /// `ArcMediaPlayerView` is a class., not a struct.
    var property: ReferenceWritableKeyPath<ArcMediaPlayerView, Bool>

    /// Provides the binding for the `Toggle`. `@State` properties can't use
    /// `didSet` to perform some action, like setting the `property`, because
    /// their `didSet` block is run only when the `View` is initialized.
    /// Instead, changes to `isOn` have to be handled in an `.onChange()`
    /// block attached to a `View`.
    @State private var isOn: Bool

    /// This explicit initializer is needed so that the `isOn` property can be
    /// set to the correct initial value.
    init(playerView: ArcMediaPlayerView,
         propertyName: String,
         property: ReferenceWritableKeyPath<ArcMediaPlayerView, Bool>) {
        self.playerView = playerView
        self.propertyName = propertyName
        self.property = property
        self.isOn = playerView[keyPath: property]
    }

    var body: some View {
        HStack(spacing: 8.0) {
            Toggle(propertyName, isOn: $isOn)
        }
        .onChange(of: isOn) { (newValue) in
            playerView[keyPath: property] = newValue
        }
    }

}

// An editor that pops up a `ColorPicker` and sets the corresponding
// `property` of the `playerView` accordingly.
@available(iOS 14.0, *)
struct ColorPropertyEditor: View {

    /// The `ArcMediaPlayerView` whose property is being edited.
    var playerView: ArcMediaPlayerView

    /// The name of the property being edited, which is displayed in the
    /// `ColorPicker`. I wish that this could be looked up with something like
    /// `String(describing: property)`, but that's hideous.
    var propertyName: String

    /// The `ArcMediaPlayerView`'s color property. It has to be a
    /// `ReferenceWritableKeyPath`, not just a `WritableKeyPath`, because the
    /// `ArcMediaPlayerView` is a class., not a struct.
    var property: ReferenceWritableKeyPath<ArcMediaPlayerView, UIColor>

    /// Provides the binding for the `ColorPicker`. `@State` properties can't
    /// use `didSet` to perform some action, like setting the `property`,
    /// because their `didSet` block is run only when the `View` is
    /// initialized. Instead, changes to `isOn` have to be handled in an
    /// `.onChange()` block attached to a `View`.
    @State private var color: CGColor // ColorPicker works with CGColor, not UIColor

    /// This explicit initializer is needed so that the `color` property can be
    /// set to the correct initial value.
    init(playerView: ArcMediaPlayerView,
         propertyName: String,
         property: ReferenceWritableKeyPath<ArcMediaPlayerView, UIColor>) {
        self.playerView = playerView
        self.propertyName = propertyName
        self.property = property
        self.color = playerView[keyPath: property].cgColor
    }

    var body: some View {
        HStack(spacing: 8.0) {
            ColorPicker(propertyName, selection: $color)
        }
        .onChange(of: color) { (newColor) in
            // Wrap the new color in a `UIColor` and assign it to the property.
            playerView[keyPath: property] = UIColor(cgColor: newColor)
        }
    }

}

/// A `UIViewController` that hosts the `ArcMediaPlayerViewEditor`.
@available(iOS 14.0, *)
class SettingsViewController: UIHostingController<ArcMediaPlayerViewEditor> {

    @MainActor @objc required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: ArcMediaPlayerViewEditor())
    }

    var playerView: ArcMediaPlayerView? {
        didSet {
            rootView.playerView = playerView
            rootView.closeButtonAction = { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }

}

@available(iOS 14.0, *)
struct ArcMediaPlayerViewEditorPreviews: PreviewProvider {

    static var previews: some View {
        ArcMediaPlayerViewEditor()
    }

}
