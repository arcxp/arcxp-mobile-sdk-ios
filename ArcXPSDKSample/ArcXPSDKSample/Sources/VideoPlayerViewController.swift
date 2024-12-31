//  Copyright © 2020 The Washington Post. All rights reserved.

import ArcXP

import AVFoundation
import AVKit
import QuartzCore  // for rounded borders in the storyboard
import UIKit

// swiftlint:disable line_length
public class VideoPlayerViewController: UIViewController {

    public enum PlayerMode {
        case avPlayerViewController
        case arcMediaPlayerViewController
    }

    // MARK: - Outlets

    @IBOutlet weak var arcMediaPlayerSettingsButton: UIBarButtonItem?

    @IBOutlet weak var eventsTableContainer: UIView?

    @IBOutlet weak var footerSelector: UISegmentedControl?

    @IBOutlet weak var virtualChannelInfoTable: UITableView?

    @IBOutlet weak var playerPlaceholder: UIView!

    @IBOutlet weak var showTrackingUrlButton: UIBarButtonItem?

    @IBOutlet weak var showVideoUrlButton: UIBarButtonItem?

    // MARK: - Public Properties

    public var adsEnabled: Bool = false

    public var playerMode: PlayerMode = .arcMediaPlayerViewController

    public var video: ArcVideo?

    // MARK: - Private Properties

    private weak var delegateEventsViewController: DelegateEventsViewController?

    private var arcMediaPlayerView: ArcMediaPlayerView?

    /// The `PlayerController` that was provided by the
    /// `playerControllerContainer`. **If you do not assign the player
    /// controller to an instance property, and you use the
    /// `AVPlayerViewController`, your app will crash because the
    /// `AVPlayerViewController` does *not* retain the `playerController`
    /// itself.
    private var playerController: PlayerController!

    // MARK: - Actions

    @IBAction func toggleFooterView(sender: UISegmentedControl) {
        eventsTableContainer?.isHidden = (sender.selectedSegmentIndex != 0)
        virtualChannelInfoTable?.isHidden = (sender.selectedSegmentIndex == 0)
    }

    @IBAction func showUrl(sender: UIBarButtonItem) {
        var url: URL?

        if sender === showVideoUrlButton {
            url = video?.url
        } else if sender === showTrackingUrlButton {
            if let adSettings = video?.adSettings as? LivestreamAdSettings {
                url = adSettings.trackingUrl
            }
        }

        if let url = url {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    // MARK: - UIViewController Functions

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueId = segue.identifier else {
            return
        }

        switch segueId {
        case "embedDelegateEventsTable":
            delegateEventsViewController = segue.destination as? DelegateEventsViewController
#if os(iOS)
        case "showPlayerOptions":
            if #available(iOS 15.0, *), let host = segue.destination as? SettingsViewController {
                host.playerView = arcMediaPlayerView
            }
#endif
        default:
            return
        }
    }

    #if os(tvOS)

    public override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let firstPress = presses.first else {
            super.pressesBegan(presses, with: event)

            return
        }

        switch firstPress.type {
        case .playPause,
             .select:
            playerController?.togglePlayAndPause()
        default:
            super.pressesBegan(presses, with: event)
        }
    }

    #endif

    // swiftlint:disable function_body_length
    override public func viewDidLoad() {
        super.viewDidLoad()

        let playerViewController: UIViewController

        // Figure out which player controller container we want.
        if playerMode == .arcMediaPlayerViewController {
            let playerVC = ArcMediaPlayerViewController.loadFromStoryboard()
            playerVC.playerView.delegate = delegateEventsViewController
            playerController = playerVC.playerController
            playerViewController = playerVC
            arcMediaPlayerView = playerVC.playerView
        } else {
            let playerVC = AVPlayerViewController()
            playerController = playerVC.playerController
            playerViewController = playerVC
        }

        arcMediaPlayerSettingsButton?.isEnabled = (playerMode == .arcMediaPlayerViewController)

        addChild(playerViewController)
        playerViewController.didMove(toParent: self)  // DON'T FORGET THIS!
        playerPlaceholder.addSubview(playerViewController.view)
        let playerView = playerViewController.view!
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.leadingAnchor.constraint(equalTo: playerPlaceholder.leadingAnchor).isActive = true
        playerView.trailingAnchor.constraint(equalTo: playerPlaceholder.trailingAnchor).isActive = true
        playerView.topAnchor.constraint(equalTo: playerPlaceholder.topAnchor).isActive = true
        playerView.bottomAnchor.constraint(equalTo: playerPlaceholder.bottomAnchor).isActive = true

        // Configure the player controller.
        playerController.delegate = delegateEventsViewController
        playerController?.adsEnabled = adsEnabled

        if adsEnabled {
            // Load the ad config file.
            let adConfigUrl:URL?
#if os(iOS)
            adConfigUrl = URL(string: "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/single_preroll_skippable&sz=640x480&ciu_szs=300x250%2C728x90&gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&impl=s&correlator=")
#elseif os(tvOS)
            adConfigUrl = URL(string: "https://pubads.g.doubleclick.net/gampad/ads?slotname=/124319096/external/ad_rule_samples&sz=640x480&ciu_szs=300x250&cust_params=deployment%3Ddevsite%26sample_ar%3Dpostonly&url=https://developers.google.com/interactive-media-ads/docs/sdks/html5/tags&unviewed_position_start=1&output=xml_vast3&impl=s&env=vp&gdfp_req=1&ad_rule=0&vad_type=linear&vpos=postroll&pod=1&ppos=1&lip=true&min_ad_duration=0&max_ad_duration=30000&vrid=6016&video_doc_id=short_onecue&cmsid=496&kfa=0&tfcd=0")
#endif
            let adConfig = ArcMediaAdConfig(adConfigUrl: adConfigUrl, adEnabled: true)
            playerController?.configureAds(adConfig)
        }

        footerSelector?.selectedSegmentIndex = 0
        footerSelector?.isHidden = true
        virtualChannelInfoTable?.isHidden = true

        if let video = video {
            if video.info is [VirtualChannel.Program] {
                footerSelector?.isHidden = false
                virtualChannelInfoTable?.reloadData()
            }

            let adSettings = video.adSettings as? LivestreamAdSettings
            showTrackingUrlButton?.isEnabled = (adSettings?.trackingUrl != nil)
            showVideoUrlButton?.isEnabled = true

            let playerItem = AVPlayerItem(asset: video)
            playerController?.play(playerItem: playerItem)
        } else {
            showTrackingUrlButton?.isEnabled = false
            showVideoUrlButton?.isEnabled = false
        }

        do {
            try PictureInPictureManager.activatePictureInPictureSession()
            if playerMode == .arcMediaPlayerViewController {
                try PictureInPictureManager.setUp(with: playerController.player, for: self)
            }
        } catch {
            print("An error occured while setting up picture-in-picture capability: \(error.localizedDescription)")
        }
    }

    // swiftlint:enable function_body_length

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        playerController?.pause()
    }
    
    /// As per the latest IMA framework updates, ads must be requested only in `ViewDidAppear`
    /// to avoid view hierarchy error for playing the ads
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Handling for only default avPlayerViewController
        // since ArcPlayerController handles its own.
        if playerMode == .avPlayerViewController {
            playerController.requestAds()
        }
    }

}

extension VideoPlayerViewController: UITableViewDataSource {

    var programs: [VirtualChannel.Program]? {
        return video?.info as? [VirtualChannel.Program]
    }

    var startTimes: [TimeInterval] {
        guard let programs = programs else {
            return []
        }

        var startTimes = [TimeInterval(0.0)]

        for program in programs.dropLast() {
            startTimes.append(program.duration + (startTimes.last ?? 0.0))
        }

        return startTimes
    }

    public func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
        return programs?.count ?? 0
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt path: IndexPath) -> UITableViewCell {
        if let programCount = programs?.count,
           programCount > 0,
           let cell = tableView.dequeueReusableCell(withIdentifier: "programCell", for: path) as? ProgramCell {
            cell.indexLabel?.text = "\(path.row)"
            cell.program = programs?[path.row]
            cell.startTime = startTimes[path.row]

            return cell
        } else {
            return UITableViewCell(frame: .zero)
        }
    }

}

extension VideoPlayerViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Jump to the start time for this cell.
        let startTime = startTimes[indexPath.row]
        playerController?.seek(to: CMTime(seconds: startTime, preferredTimescale: 1))
    }

}

class ProgramCell: UITableViewCell {

    var program: VirtualChannel.Program? {
        didSet {
            nameLabel?.text = program?.name
            descriptionLabel?.text = program?.description
        }
    }

    @IBOutlet weak var indexLabel: UILabel?

    @IBOutlet weak var nameLabel: UILabel?

    @IBOutlet weak var startTimeLabel: UILabel?

    @IBOutlet weak var descriptionLabel: UILabel?

    var startTime: TimeInterval? {
        didSet {
            if let startTime = startTime,
               let startTimeString = TimeFormatter.timeFormatter.string(from: startTime) {
                startTimeLabel?.text = startTimeString
            } else {
                startTimeLabel?.text = nil
            }
        }
    }

}

class TimeFormatter {
    static var timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.collapsesLargestUnit = true

        return formatter
    }()
}

class SelfHidingLabel: UILabel {

    override var text: String? {
        get { return super.text }

        set {
            super.text = newValue
            isHidden = (newValue == nil)
        }
    }

}
