//  Copyright © 2020 The Washington Post. All rights reserved.

import ArcXP

import AVFoundation
import UIKit

class ConfigureVideoBaseViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var configSelector: UISegmentedControl?

    @IBOutlet weak var mediaIDField: UITextField?

    @IBOutlet weak var organizationIDField: UITextField?

    @IBOutlet weak var serverEnvironmentSelector: UISegmentedControl?

    @IBOutlet weak var spinner: UIActivityIndicatorView?

    @IBOutlet var playButtons: [UIButton] = []

    @IBOutlet var playUsingArcMediaPlayerViewButtons: [UIButton] = []

    @IBOutlet var playUsingAVPlayerViewButtons: [UIButton] = []

    @IBOutlet var componentsOnlyForVideos: [UIView] = []

    @IBOutlet var componentsOnlyForVirtualChannels: [UIView] = []

    // MARK: - Other Properties

    var newVideo: ArcVideo?

    /// The value of the `mediaIDField`, stripped of whitespace and checked
    /// whether it's a valid `UUID`.
    var mediaID: String = "no media"

    /// The value of the `organizationIDField`, after stripping the whitespace
    /// and being lowercased.
    private var organizationID: String? {
        guard let orgId = organizationIDField?.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !orgId.isEmpty else {
            return nil
        }

        return orgId
    }

    /// The value of the `serverEnvironmentControl`, converted to either
    /// `sandbox` or `prod`.
    private var serverEnvironment: ServerEnvironment {
        guard let selectedIndex = serverEnvironmentSelector?.selectedSegmentIndex else {
            return ServerEnvironment.none // for some reason, a bare '.none' doesn't work
        }

        switch selectedIndex {
        case 0:
            return .sandbox
        case 1:
            return .production
        default:
            return ServerEnvironment.none // for some reason, a bare '.none' doesn't work
        }
    }

    // MARK: - Actions

    @IBAction public func play(sender: UIButton!) {
        spinner?.startAnimating()

        for button in playButtons {
            button.isEnabled = false
        }

        if let orgID = organizationID,
            !orgID.isEmpty { // DON'T check whether organizationIDAndServerEnvironment is empty!
            ArcXP.Services.configure(service: .video(.init(organization: orgID,
                                                           environment: serverEnvironment,
                                                           useGeorestrictions: nil)))
            AppSettings.organizationName.set(value: orgID)
            AppSettings.serverEnvironment.set(value: serverEnvironmentSelector?.selectedSegmentIndex)
        } else {
            ArcMediaClientManager.client = ArcMediaSampleClient()
        }

        let device = UIDevice.current
        let userAgent = "(\(device.model); \(device.systemName) \(device.systemVersion); Scale/1.00)"
        var livestreamAdSettings = LivestreamAdSettings()

        // Settings that are passed in the body of the stream call.
        livestreamAdSettings.adParams = LivestreamAdParams(adsParams: ["deviceType": device.model,
                                                                      "[session.user_agent]": userAgent])

        livestreamAdSettings.livestreamHTTPHeaders = ["User-Agent": userAgent]
        livestreamAdSettings.livestreamBeaconHeaders = ["User-Agent": userAgent]

        let selectedConfigIndex = configSelector?.selectedSegmentIndex ?? 0

        if selectedConfigIndex == 0 {
            ArcMediaClientManager.client.video(mediaID: mediaID,
                                               adSettings: livestreamAdSettings,
                                               accessToken: "unused") { [unowned self] (videoResult) in
                handleVideoResult(videoResult, sender: sender)
            }
        } else {
            ArcMediaClientManager.client.virtualChannel(mediaID: mediaID) { [unowned self] (videoResult) in
                handleVideoResult(videoResult, sender: sender)
            }
        }
    }

    private func handleVideoResult(_ videoResult: ArcVideoResult,
                                   sender: UIButton) {
        for button in self.playButtons {
            button.isEnabled = true
        }

        spinner?.stopAnimating()

        switch videoResult {
        case .failure(let error):
            handleError(error)
        case .success(let video):
            // Save the mediaID, but not if it's empty. It's easier to clear
            // it out manually when you want to get the default video, rather
            // than copying & pasting the UUID when you DON'T want the
            // default.
            if !mediaID.isEmpty {
                if configSelector?.selectedSegmentIndex == 0 {
                    AppSettings.mediaId.set(value: mediaID)
                } else {
                    AppSettings.virtualChannelId.set(value: mediaID)
                }
            }

            handleSuccess(video, sender: sender)
        }
    }

    // MARK: - Internal Functions

    private func handleSuccess(_ video: ArcVideo, sender: UIButton) {
        
        self.newVideo = video

        var segueId: String?

        if playUsingAVPlayerViewButtons.contains(sender) {
            segueId = "playUsingAVPlayerViewController"
        } else if playUsingArcMediaPlayerViewButtons.contains(sender) {
            segueId = "playUsingArcMediaPlayerViewController"
        }

        if let segueId = segueId {
            performSegue(withIdentifier: segueId, sender: self)
        }
    }

    private func handleError(_ error: Error) {
        print("Failed to get the video: \(error.localizedDescription)")

        let alert = UIAlertController(title: "Failed to get the video",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .default) { _ in
            alert.dismiss(animated: true, completion: nil)
        }

        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }

    // MARK: - UIViewController Functions

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? VideoPlayerViewController {
            if segue.identifier == "playUsingAVPlayerViewController" {
                viewController.playerMode = .avPlayerViewController
            } else {
                viewController.playerMode = .arcMediaPlayerViewController
            }

            viewController.video = newVideo
        }
    }

    /// Previous versions of the app stored the environment as part of the org
    /// ID, so the environment should be stripped off before restoring the
    /// value.
    private func orgIdWithoutServerEnvironment(_ orgId: String) -> String {
        if orgId.hasSuffix(ServerEnvironment.production.rawValue) {
            return orgId.replacingOccurrences(of: "-" + ServerEnvironment.production.rawValue, with: "")
        } else if orgId.hasSuffix(ServerEnvironment.sandbox.rawValue) {
            return orgId.replacingOccurrences(of: "-" + ServerEnvironment.sandbox.rawValue, with: "")
        } else {
            return orgId
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Restore the org and media IDs from the UserDefaults, if any.
        if let previousOrgId = AppSettings.organizationName.get() as? String {
            organizationIDField?.text = orgIdWithoutServerEnvironment(previousOrgId)
        }

        if let previousMediaId = AppSettings.mediaId.get() as? String {
            mediaIDField?.text = previousMediaId
        }

        serverEnvironmentSelector?.selectedSegmentIndex = AppSettings.serverEnvironment.get() as? Int ?? 0
        spinner?.stopAnimating()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = "ArcXP Video SDK \(ArcXPSDK.version)"
        navigationItem.backButtonTitle = "Configure Video"
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        newVideo = nil
    }

}
