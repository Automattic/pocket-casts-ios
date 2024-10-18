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

            if FeatureFlag.customPlaybackSettings.enabled {
                trimSilenceAmountControl.backgroundColor = ThemeColor.playerContrast06()
            } else {
                trimSilenceAmountControl.backgroundColor = .clear
                trimSilenceAmountControl.unselectedBgColor = .clear
            }

            trimSilenceAmountControl.addTarget(self, action: #selector(trimSilenceAmountChanged), for: .valueChanged)
        }
    }

    @IBOutlet weak var playbackSettingsSegmentedControl: UISegmentedControl! {
        didSet {
            playbackSettingsSegmentedControl.isHidden = !FeatureFlag.customPlaybackSettings.enabled

            playbackSettingsSegmentedControl.setTitle(L10n.playbackEffectAllPodcasts, forSegmentAt: 0)
            playbackSettingsSegmentedControl.setTitle(L10n.playbackEffectThisPodcast, forSegmentAt: 1)

            playbackSettingsSegmentedControl.addTarget(self, action: #selector(playbackSettingsDestinationChanged), for: .valueChanged)
        }
    }

    @IBOutlet var minusBtn: UIButton!
    @IBOutlet var plusBtn: UIButton!

    @IBOutlet weak var speedControlTopConstraint: NSLayoutConstraint! {
        didSet {
            speedControlTopConstraint.isActive = FeatureFlag.customPlaybackSettings.enabled
        }
    }

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

    private var playbackSpeedDebouncer: Debounce = .init(delay: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false

        updateColors()
        updateControls()

        if FeatureFlag.customPlaybackSettings.enabled {
            playbackSettingsSegmentedControl.selectedSegmentIndex = PlaybackManager.shared.isCurrentEffectGlobal() ? 0 : 1
        }
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

        if FeatureFlag.customPlaybackSettings.enabled {
            analyticsPlaybackHelper.currentSource = analyticsSource
            analyticsPlaybackHelper.viewDidAppear(currentSettings: currentPlaybackSettings())
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        removeAllCustomObservers()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if FeatureFlag.customPlaybackSettings.enabled {
            PlaybackManager.shared.applyCurrentEffect()
            return
        }

        guard didChangePlaybackSpeed else {
            return
        }

        analyticsPlaybackHelper.currentSource = analyticsSource

        let speed = PlaybackManager.shared.effects().playbackSpeed
        analyticsPlaybackHelper.playbackSpeedChanged(to: speed)
    }

    @IBAction func minusTapped(_ sender: Any) {
        didChangePlaybackSpeed = true
        PlaybackManager.shared.decreasePlaybackSpeed()

        if FeatureFlag.customPlaybackSettings.enabled {
            trackPlaybackSpeedChanged()
        }
    }

    @IBAction func plusTapped(_ sender: Any) {
        didChangePlaybackSpeed = true
        PlaybackManager.shared.increasePlaybackSpeed()

        if FeatureFlag.customPlaybackSettings.enabled {
            trackPlaybackSpeedChanged()
        }
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
        if FeatureFlag.customPlaybackSettings.enabled {
            analyticsPlaybackHelper.trimSilenceToggled(enabled: sender.isOn, currentSettings: currentPlaybackSettings())
        } else {
            analyticsPlaybackHelper.trimSilenceToggled(enabled: sender.isOn)
        }
    }

    @objc private func trimSilenceAmountChanged() {
        let effects = PlaybackManager.shared.effects()
        let amount = trimSilenceIndexToAmount(trimSilenceAmountControl.selectedIndex)
        effects.trimSilence = amount

        PlaybackManager.shared.changeEffects(effects)

        analyticsPlaybackHelper.currentSource = analyticsSource
        if FeatureFlag.customPlaybackSettings.enabled {
            analyticsPlaybackHelper.trimSilenceAmountChanged(amount: amount, currentSettings: currentPlaybackSettings())
        } else {
            analyticsPlaybackHelper.trimSilenceAmountChanged(amount: amount)
        }
    }

    @objc private func playbackSettingsDestinationChanged() {
        let applyLocalSettings = playbackSettingsSegmentedControl.selectedSegmentIndex == 1
        PlaybackManager.shared.overrideEffectsToggled(applyLocalSettings: applyLocalSettings)
        updateControls()
        analyticsPlaybackHelper.currentSource = analyticsSource
        analyticsPlaybackHelper.effectSettingsChanged(currentSettings: currentPlaybackSettings())
    }

    @IBAction func volumeBoostChanged(_ sender: UISwitch) {
        let effects = PlaybackManager.shared.effects()
        effects.volumeBoost = sender.isOn

        PlaybackManager.shared.changeEffects(effects)

        analyticsPlaybackHelper.currentSource = analyticsSource
        if FeatureFlag.customPlaybackSettings.enabled {
            analyticsPlaybackHelper.volumeBoostToggled(enabled: sender.isOn, currentSettings: currentPlaybackSettings())
        } else {
            analyticsPlaybackHelper.volumeBoostToggled(enabled: sender.isOn)
        }
    }

    @IBAction func clearForPodcastTapped(_ sender: Any) {
        guard let episode = PlaybackManager.shared.currentEpisode() as? Episode, let podcast = episode.parentPodcast() else { return }

        podcast.isEffectsOverridden = false
        DataManager.sharedManager.save(podcast: podcast)
        PlaybackManager.shared.effectsChangedExternally()
        updateClearView()
    }

    private func trackPlaybackSpeedChanged() {
        playbackSpeedDebouncer.call { [weak self] in
            guard let self else { return }
            analyticsPlaybackHelper.currentSource = analyticsSource
            let speed = PlaybackManager.shared.effects().playbackSpeed
            analyticsPlaybackHelper.playbackSpeedChanged(to: speed, currentSettings: currentPlaybackSettings())
        }
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
        // We don't need a clear view if the FF is enbaled
        if FeatureFlag.customPlaybackSettings.enabled {
            return
        }
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

        if FeatureFlag.customPlaybackSettings.enabled {
            trackPlaybackSpeedChanged()
        }
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

        if FeatureFlag.customPlaybackSettings.enabled {
            trimSilenceAmountControl.lineColor = .clear
            trimSilenceAmountControl.unselectedItemColor = ThemeColor.playerContrast02()
            trimSilenceAmountControl.selectedBgColor = ThemeColor.playerContrast01()
            trimSilenceAmountControl.selectedItemColor = PlayerColorHelper.playerBackgroundColor01()

            playbackSettingsSegmentedControl.backgroundColor = ThemeColor.playerContrast06()
            playbackSettingsSegmentedControl.selectedSegmentTintColor = ThemeColor.playerContrast01()

            let normalAttribute = [NSAttributedString.Key.foregroundColor: ThemeColor.playerContrast02()]
            playbackSettingsSegmentedControl.setTitleTextAttributes(normalAttribute, for: .normal)
            let selectedAttribute = [NSAttributedString.Key.foregroundColor: PlayerColorHelper.playerBackgroundColor01()]
            playbackSettingsSegmentedControl.setTitleTextAttributes(selectedAttribute, for: .selected)
        } else {
            trimSilenceAmountControl.lineColor = ThemeColor.playerContrast02()
            trimSilenceAmountControl.unselectedItemColor = ThemeColor.playerContrast01()
            trimSilenceAmountControl.selectedBgColor = ThemeColor.playerContrast01()
            trimSilenceAmountControl.selectedItemColor = PlayerColorHelper.playerBackgroundColor01()
        }

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

    private func currentPlaybackSettings() -> String {
        playbackSettingsSegmentedControl.selectedSegmentIndex == 0 ? "global" : "local"
    }

    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
