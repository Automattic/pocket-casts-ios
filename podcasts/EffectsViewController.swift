import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class EffectsViewController: SimpleNotificationsViewController {
    @IBOutlet var headingLbl: ThemeableLabel! {
        didSet {
            headingLbl.style = .playerContrast02
            headingLbl.text = L10n.playbackEffects.localizedUppercase
        }
    }

    @IBOutlet var headingView: UIView!

    @IBOutlet var handleView: ThemeableView! {
        didSet {
            handleView.style = .playerContrast02
        }
    }

    // MARK: - Speed

    @IBOutlet var speedLbl: ThemeableLabel! {
        didSet {
            speedLbl.style = .playerContrast01
            speedLbl.text = L10n.speed
        }
    }

    @IBOutlet var speedBtn: ShiftyRoundButton! {
        didSet {
            speedBtn.buttonTapped = { [weak self] in
                self?.speedTapped()
            }
        }
    }

    @IBOutlet var speedIcon: TintableImageView! {
        didSet {
            speedIcon.tintColor = ThemeColor.playerContrast01()
        }
    }

    // MARK: - Trim Silence

    @IBOutlet var trimSilenceLbl: ThemeableLabel! {
        didSet {
            trimSilenceLbl.style = .playerContrast01
            trimSilenceLbl.text = L10n.trimSilence
        }
    }

    @IBOutlet var trimSilenceDescription: ThemeableLabel! {
        didSet {
            trimSilenceDescription.style = .playerContrast02
        }
    }

    @IBOutlet var trimSilenceSwitch: ThemeableSwitch! {
        didSet {
            trimSilenceSwitch.themeOverride = .dark
        }
    }

    @IBOutlet var trimIcon: TintableImageView! {
        didSet {
            trimIcon.tintColor = ThemeColor.playerContrast01()
        }
    }

    // MARK: - Volume

    @IBOutlet var volumeLbl: ThemeableLabel! {
        didSet {
            volumeLbl.style = .playerContrast01
            volumeLbl.text = L10n.volumeBoost
        }
    }

    @IBOutlet var volumeDescription: ThemeableLabel! {
        didSet {
            volumeDescription.style = .playerContrast02
            volumeDescription.text = L10n.volumeBoostDescription
        }
    }

    @IBOutlet var volumeBoostSwitch: ThemeableSwitch! {
        didSet {
            volumeBoostSwitch.themeOverride = .dark
        }
    }

    @IBOutlet var volumeIcon: TintableImageView! {
        didSet {
            volumeIcon.tintColor = ThemeColor.playerContrast01()
        }
    }

    @IBOutlet var clearForPodcastView: UIView!
    @IBOutlet var clearForPodcastImage: PodcastImageView!

    @IBOutlet var divider1: ThemeableView! {
        didSet {
            divider1.style = .playerContrast05
        }
    }

    @IBOutlet var dividerTwo: ThemeableView! {
        didSet {
            dividerTwo.style = .playerContrast05
        }
    }

    @IBOutlet var customEffectsLabel: ThemeableLabel! {
        didSet {
            customEffectsLabel.style = .playerContrast01
        }
    }

    @IBOutlet var trimSilenceAmountControl: CustomSegmentedControl! {
        didSet {
            let lowAction = SegmentedAction(title: TrimSilenceAmount.low.description)
            let mediumAction = SegmentedAction(title: TrimSilenceAmount.medium.description)
            let highAction = SegmentedAction(title: TrimSilenceAmount.high.description)
            trimSilenceAmountControl.setActions([lowAction, mediumAction, highAction])

            trimSilenceAmountControl.unselectedBgColor = UIColor.clear

            trimSilenceAmountControl.addTarget(self, action: #selector(trimSilenceAmountChanged), for: .valueChanged)
        }
    }

    @IBOutlet var minusBtn: UIButton!
    @IBOutlet var plusBtn: UIButton!

    @IBOutlet var trimSilenceSpeedsToLabelConstraint: NSLayoutConstraint! {
        didSet {
            trimSilenceSpeedsToLabelConstraint.isActive = false
        }
    }

    @IBOutlet var customEffectsToVolumeBoostConstraint: NSLayoutConstraint! {
        didSet {
            customEffectsToVolumeBoostConstraint.isActive = false
        }
    }

    private let analyticsPlaybackHelper = AnalyticsPlaybackHelper.shared

    private var analyticsSource: AnalyticsSource {
        .playerPlaybackEffects
    }

    private var didChangePlaybackSpeed: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false

        updateColors()
        updateControls()
        if let episode = PlaybackManager.shared.currentEpisode() as? Episode, let podcast = episode.parentPodcast() {
            clearForPodcastImage.setPodcast(uuid: podcast.uuid, size: .list)
        }

        setPreferredSize()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setPreferredSize()
    }

    private func setPreferredSize() {
        let computedSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        // if the trim silence view is hidden, allow enough space for it to appear
        if !PlaybackManager.shared.effects().trimSilence.isEnabled() {
            let additionalHeightRequired: CGFloat = view.bounds.width < 340 ? 100 : 50
            preferredContentSize = CGSize(width: computedSize.width, height: computedSize.height + additionalHeightRequired)
        } else {
            preferredContentSize = computedSize
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(updateControls))
        addCustomObserver(Constants.Notifications.playbackEffectsChanged, selector: #selector(updateControls))
        addCustomObserver(Constants.Notifications.themeChanged, selector: #selector(updateColors))
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        removeAllCustomObservers()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard didChangePlaybackSpeed else {
            return
        }

        analyticsPlaybackHelper.currentSource = analyticsSource

        let speed = PlaybackManager.shared.effects().playbackSpeed
        AnalyticsPlaybackHelper.shared.playbackSpeedChanged(to: speed)
    }

    @IBAction func minusTapped(_ sender: Any) {
        didChangePlaybackSpeed = true
        PlaybackManager.shared.decreasePlaybackSpeed()
    }

    @IBAction func plusTapped(_ sender: Any) {
        didChangePlaybackSpeed = true
        PlaybackManager.shared.increasePlaybackSpeed()
    }

    @IBAction func trimSilenceChanged(_ sender: UISwitch) {
        let effects = PlaybackManager.shared.effects()
        if sender.isOn {
            effects.trimSilence = .low
        } else {
            effects.trimSilence = .off
        }

        PlaybackManager.shared.changeEffects(effects)

        analyticsPlaybackHelper.currentSource = analyticsSource
        analyticsPlaybackHelper.trimSilenceToggled(enabled: sender.isOn)
    }

    @objc private func trimSilenceAmountChanged() {
        let effects = PlaybackManager.shared.effects()
        let amount = trimSilenceIndexToAmount(trimSilenceAmountControl.selectedIndex)
        effects.trimSilence = amount

        PlaybackManager.shared.changeEffects(effects)

        analyticsPlaybackHelper.currentSource = analyticsSource
        analyticsPlaybackHelper.trimSilenceAmountChanged(amount: amount)
    }

    @IBAction func volumeBoostChanged(_ sender: UISwitch) {
        let effects = PlaybackManager.shared.effects()
        effects.volumeBoost = sender.isOn

        PlaybackManager.shared.changeEffects(effects)

        analyticsPlaybackHelper.currentSource = analyticsSource
        analyticsPlaybackHelper.volumeBoostToggled(enabled: sender.isOn)
    }

    @IBAction func clearForPodcastTapped(_ sender: Any) {
        guard let episode = PlaybackManager.shared.currentEpisode() as? Episode, let podcast = episode.parentPodcast() else { return }

        podcast.isEffectsOverridden = false
        DataManager.sharedManager.save(podcast: podcast)
        PlaybackManager.shared.effectsChangedExternally()
        updateClearView()
    }

    @objc private func updateControls() {
        trimSilenceSwitch.isEnabled = PlaybackManager.shared.silenceRemovalAvailable()
        volumeBoostSwitch.isEnabled = PlaybackManager.shared.volumeBoostAvailable()

        let effects = PlaybackManager.shared.effects()
        volumeBoostSwitch.isOn = effects.volumeBoost
        updateRemoveSilenceViews()
        updateSpeedBtn()
        updateClearView()
    }

    private func updateClearView() {
        guard let episode = PlaybackManager.shared.currentEpisode() as? Episode, let podcast = episode.parentPodcast() else {
            clearForPodcastView.isHidden = true
            customEffectsToVolumeBoostConstraint.isActive = false

            return
        }

        customEffectsToVolumeBoostConstraint.isActive = podcast.isEffectsOverridden
        clearForPodcastView.isHidden = !podcast.isEffectsOverridden
    }

    private func updateRemoveSilenceViews() {
        let effects = PlaybackManager.shared.effects()
        trimSilenceSwitch.isOn = effects.trimSilence.isEnabled()

        trimSilenceSpeedsToLabelConstraint.isActive = effects.trimSilence.isEnabled()
        UIView.animate(withDuration: 0.3) {
            self.trimSilenceAmountControl.alpha = effects.trimSilence.isEnabled() ? 1 : 0
            self.view.layoutIfNeeded()
        }

        trimSilenceAmountControl.selectedIndex = trimSilenceAmountToIndex(effects.trimSilence)

        let timeSaved = StatsManager.shared.timeSavedDynamicSpeedInclusive()
        if timeSaved < 60 {
            trimSilenceDescription.text = L10n.playerEffectsTrimSilenceDetails
        } else {
            let timeFormatted = DateFormatHelper.sharedHelper.longElapsedTime(timeSaved)
            trimSilenceDescription.text = L10n.playerEffectsTrimSilenceProgress(timeFormatted)
        }
    }

    private func speedTapped() {
        didChangePlaybackSpeed = true
        PlaybackManager.shared.toggleDefinedPlaybackSpeed()
    }

    private func updateSpeedBtn() {
        let effects = PlaybackManager.shared.effects()
        speedBtn.fillColor = ThemeColor.playerContrast01()
        speedBtn.isOn = (effects.playbackSpeed != 1)
        speedBtn.buttonTitle = "  " + L10n.playbackSpeed(effects.playbackSpeed.localized())
        speedBtn.strokeColor = speedBtn.isOn ? ThemeColor.playerContrast01() : ThemeColor.playerContrast02()
        speedBtn.textColor = speedBtn.isOn ? PlayerColorHelper.playerBackgroundColor01() : ThemeColor.playerContrast01()
        speedBtn.accessibilityLabel = L10n.accessibilityPlayerEffectsPlaybackSpeed(effects.playbackSpeed.localized(.spellOut))
    }

    @objc private func updateColors() {
        view.backgroundColor = PlayerColorHelper.playerBackgroundColor01()
        headingView.backgroundColor = PlayerColorHelper.playerBackgroundColor02()
        volumeBoostSwitch.onTintColor = PlayerColorHelper.playerHighlightColor02(for: .dark)
        trimSilenceSwitch.onTintColor = PlayerColorHelper.playerHighlightColor02(for: .dark)

        trimSilenceAmountControl.lineColor = ThemeColor.playerContrast02()
        trimSilenceAmountControl.unselectedItemColor = ThemeColor.playerContrast01()
        trimSilenceAmountControl.selectedBgColor = ThemeColor.playerContrast01()
        trimSilenceAmountControl.selectedItemColor = PlayerColorHelper.playerBackgroundColor01()

        updateSpeedBtn()

        minusBtn.tintColor = ThemeColor.playerContrast01()
        plusBtn.tintColor = ThemeColor.playerContrast01()
    }

    private func trimSilenceAmountToIndex(_ amount: TrimSilenceAmount) -> Int {
        switch amount {
        case .low, .off:
            return 0
        case .medium:
            return 1
        case .high:
            return 2
        }
    }

    private func trimSilenceIndexToAmount(_ index: Int) -> TrimSilenceAmount {
        if index == 1 {
            return .medium
        } else if index == 2 {
            return .high
        } else {
            return .low
        }
    }

    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
