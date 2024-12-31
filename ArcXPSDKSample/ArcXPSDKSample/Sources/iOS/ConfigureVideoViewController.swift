//
//  ConfigureVideoViewController.swift
//  Sample iOS App
//
//  Created by Tibbetts, Jason on 7/19/21.
//  Copyright © 2021 The Washington Post. All rights reserved.
//

import ArcXP
import GoogleInteractiveMediaAds
import OMSDK_Washpost
import ProgrammaticAccessLibrary
import UIKit

class ConfigureVideoViewController: ConfigureVideoBaseViewController {

    // MARK: - Outlets

    @IBOutlet weak var dependencyVersionsStack: UIStackView?

    @IBOutlet weak var showGoogleIMAAdsSwitch: UISwitch?

    @IBOutlet weak var pageViewPlayButton: UIButton!
    
    @IBOutlet weak var multiVideoPlayButton: UIButton!
    
    // show an example for playing multiple videos in single page
    private let showMultiVideoPlayButton = true
    
    // show an example for playing videos in page view.
    private let showPageViewPlayButton = false
    
    @IBOutlet weak var testOpenMeasurementComplianceSwitch: UISwitch?

    @IBOutlet weak var virtualChannelIDField: UITextField?

    // MARK: - Other Properties

    private var dependencyData = [
        "Google Interactive Media Ads": (
            Bundle(for: IMAAdsManager.self),
            URL(string: "https://developers.google.com/interactive-media-ads/docs/sdks/ios/client-side")!
        ),
        "Google Programmatic Access Library": (
            Bundle(for: NonceManager.self),
            URL(string: "https://developers.google.com/ad-manager/pal/ios")!
        ),
        "Open Measurement": (
            Bundle(for: OMIDWashpostSDK.self),
            URL(string: "https://iabtechlab.com/standards/")!
        )
    ]

    private var keyboardManager: KeyboardManager?

    // MARK: - UIViewController

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? VideoPlayerViewController {
            viewController.adsEnabled = (showGoogleIMAAdsSwitch?.isOn ?? false)

            if var livestreamAdSettings = newVideo?.adSettings as? LivestreamAdSettings {
                if let testOMSwitch = testOpenMeasurementComplianceSwitch {
                    livestreamAdSettings.testOpenMeasurementCompliance = testOMSwitch.isOn
                }

                newVideo?.adSettings = livestreamAdSettings
            }
        }

        super.prepare(for: segue, sender: sender)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configSelector?.selectedSegmentIndex = AppSettings.selectedConfiguration.get() as? Int ?? 0

        if let configSelector = configSelector {
            selectConfigView(sender: configSelector)
        }
        
        pageViewPlayButton.isHidden = !showPageViewPlayButton
        multiVideoPlayButton.isHidden = !showMultiVideoPlayButton

        // Populate the dependencyVersions label
        if let dependencyVersionsStack = dependencyVersionsStack {
            let sampleButton = dependencyVersionsStack.arrangedSubviews.first as? UIButton

            for key in dependencyData.keys.sorted() { // .forEach { (key, value) is unsorted
                let info = dependencyData[key]!
                let bundle = info.0
                let bundleVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"

                let button = UIButton()
                button.addTarget(self, action: #selector(showDependencyInfo(sender:)), for: .touchUpInside)
                button.titleLabel?.font = sampleButton?.titleLabel?.font
                button.setTitleColor(sampleButton?.titleColor(for: .normal), for: .normal)
                button.setTitle(key + ": " + bundleVersion, for: .normal)
                dependencyVersionsStack.addArrangedSubview(button)
            }

            sampleButton?.removeFromSuperview()
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        keyboardManager = KeyboardManager(rootView: view)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        keyboardManager = nil
    }

    // MARK: - Actions

    @IBAction func selectConfigView(sender: UISegmentedControl) {
        let isVideoMode = (sender.selectedSegmentIndex == 0)
        componentsOnlyForVideos.forEach { $0.isHidden = !isVideoMode }
        componentsOnlyForVirtualChannels.forEach { $0.isHidden = isVideoMode }

        AppSettings.selectedConfiguration.set(value: sender.selectedSegmentIndex)
    }

    @objc private func showDependencyInfo(sender button: UIButton) {
        if let buttonTitle = button.title(for: .normal)?.split(separator: ":").first,
           let url = dependencyData[String(buttonTitle)]?.1 {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    @IBAction func toggleOpenMeasurementComplianceMode(_ sender: UISwitch) {
        showGoogleIMAAdsSwitch?.isSelected = false
    }

    // MARK: - Other Functions

    override func play(sender: UIButton!) {

        if configSelector?.selectedSegmentIndex == 0,
           let mediaIDText = mediaIDField?.text {
                mediaID = mediaIDText
        } else if configSelector?.selectedSegmentIndex == 1,
                  let virtualChannelIDText = virtualChannelIDField?.text {
            mediaID = virtualChannelIDText
        }

        mediaID = mediaID.trimmingCharacters(in: .whitespacesAndNewlines)

        super.play(sender: sender)
    }

}

extension ConfigureVideoViewController: UITextFieldDelegate {

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        keyboardManager?.firstResponder = textField
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        keyboardManager?.firstResponder = nil
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        keyboardManager?.firstResponder = nil

        return true
    }

}
