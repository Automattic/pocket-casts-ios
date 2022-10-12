import GoogleCast
import UIKit

class CastToViewController: PCViewController {
    @IBOutlet var castTable: ThemeableTable! {
        didSet {
            setupTable()
        }
    }

    @IBOutlet var connectedView: UIView!
    @IBOutlet var volumeSlider: UISlider!
    @IBOutlet var episodeName: ThemeableLabel! {
        didSet {
            episodeName.themeOverride = themeOverride
        }
    }

    @IBOutlet var podcastName: ThemeableLabel! {
        didSet {
            podcastName.style = .primaryText02
            podcastName.themeOverride = themeOverride
        }
    }

    @IBOutlet var playPauseBtn: UIButton!
    @IBOutlet var playingArtwork: UIImageView!
    @IBOutlet var stopCastingBtn: ThemeableRoundedButton! {
        didSet {
            stopCastingBtn.themeOverride = themeOverride
        }
    }

    @IBOutlet var multiZoneVolumeView: CastDeviceVolumeView! {
        didSet {
            multiZoneVolumeView.themeOverride = themeOverride
        }
    }

    var devices = [GCKDevice]()

    var themeOverride: Theme.ThemeType?

    init(themeOverride: Theme.ThemeType? = nil) {
        self.themeOverride = themeOverride

        super.init(nibName: "CastToViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(cancelTapped))

        let connected = GoogleCastManager.sharedManager.connectedOrConnectingToDevice()
        if connected {
            title = GoogleCastManager.sharedManager.connectedDevice()?.friendlyName ?? L10n.chromecastConnected
            connectedView.isHidden = false
            castTable.isHidden = true
            volumeSlider.value = GoogleCastManager.sharedManager.currentVolume()
            updatePlayingDetails()
            GoogleCastManager.sharedManager.requestMultizoneUpdate()
        } else {
            title = L10n.chromecastCastTo
            castTable.isHidden = false
            connectedView.isHidden = true
            reloadAvailableDevices()
        }
        updateColors()

        NotificationCenter.default.addObserver(self, selector: #selector(playingStateDidChange), name: Constants.Notifications.playbackStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playingStateDidChange), name: Constants.Notifications.playbackPaused, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playingStateDidChange), name: Constants.Notifications.playbackStarting, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playingStateDidChange), name: Constants.Notifications.playbackTrackChanged, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(deviceListDidChange), name: Constants.Notifications.googleCastStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(multiZoneDevicesChanged), name: Constants.Notifications.googleCastMultiZoneStatusChanged, object: nil)

        GoogleCastManager.sharedManager.startDeviceDiscovery()

        Analytics.track(.chromecastViewShown, properties: ["is_connected": connected])
    }

    deinit {
        GoogleCastManager.sharedManager.stopDeviceDiscovery()
        NotificationCenter.default.removeObserver(self)
    }

    @IBAction func playPauseTapped(_ sender: Any) {
        AnalyticsPlaybackHelper.shared.currentSource = .chromecast
        PlaybackManager.shared.playPause()
    }

    @objc private func cancelTapped() {
        dismiss(animated: true, completion: nil)
        Analytics.track(.chromecastViewDismissed)
    }

    @IBAction func stopCastingTapped(_ sender: Any) {
        GoogleCastManager.sharedManager.stopCasting()
        Analytics.track(.chromecastStoppedCasting)

        dismiss(animated: true, completion: nil)
    }

    @IBAction func volumeSliderDidChange(_ sender: UISlider) {
        GoogleCastManager.sharedManager.changeVolume(to: sender.value)
    }

    private func updatePlayingDetails() {
        guard GoogleCastManager.sharedManager.connected(), let playingEpisode = PlaybackManager.shared.currentEpisode() else {
            episodeName.text = L10n.chromecastConnectedToDevice
            podcastName.text = L10n.chromecastNothingPlaying
            playPauseBtn.isHidden = true
            playingArtwork.isHidden = true

            return
        }

        episodeName.text = playingEpisode.displayableTitle()
        podcastName.text = playingEpisode.subTitle()

        let imageName = PlaybackManager.shared.playing() ? "icon-pause" : "icon-play"
        playPauseBtn.setImage(UIImage(named: imageName), for: .normal)
        playPauseBtn.isHidden = false

        playingArtwork.isHidden = false
        ImageManager.sharedManager.loadImage(episode: playingEpisode, imageView: playingArtwork, size: .page)
    }

    private func reloadAvailableDevices() {
        devices = GoogleCastManager.sharedManager.deviceManager.availableDevices()
        castTable.reloadData()
    }

    @objc private func deviceListDidChange() {
        reloadAvailableDevices()
    }

    @objc private func multiZoneDevicesChanged() {
        multiZoneVolumeView.update()
    }

    @objc private func playingStateDidChange() {
        updatePlayingDetails()
    }

    override func handleThemeChanged() {
        updateColors()
        castTable.reloadData()
    }

    private func updateColors() {
        let interactive01 = ThemeColor.primaryInteractive01(for: themeOverride)

        volumeSlider.tintColor = interactive01
        volumeSlider.minimumTrackTintColor = interactive01
        playPauseBtn.tintColor = interactive01
        playPauseBtn.imageView?.tintColor = interactive01

        multiZoneVolumeView.updateTrackColor(interactive01)

        view.backgroundColor = ThemeColor.primaryUi01(for: themeOverride)
        connectedView.backgroundColor = ThemeColor.primaryUi01(for: themeOverride)

        changeNavTint(titleColor: ThemeColor.secondaryText01(for: themeOverride), iconsColor: ThemeColor.secondaryIcon01(for: themeOverride), backgroundColor: ThemeColor.secondaryUi01(for: themeOverride))
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}

extension CastToViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .chromecast
    }
}
