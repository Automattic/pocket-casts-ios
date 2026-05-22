import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class FilterDurationViewController: PCViewController {
    private let filter: EpisodeFilter

    @IBOutlet var longerThanLabel: ThemeableLabel! {
        didSet {
            longerThanLabel.style = .primaryText02
            longerThanLabel.font = .font(ofSize: 15.0, weight: .medium, scalingWith: .subheadline)
        }
    }

    @IBOutlet var longerThanDescription: ThemeableLabel! {
        didSet {
            longerThanDescription.style = .primaryText02
            longerThanDescription.font = .font(ofSize: 15.0, weight: .medium, scalingWith: .subheadline)
            longerThanDescription.text = L10n.filterLongerThanLabel
        }
    }

    @IBOutlet var shorterThanLabel: ThemeableLabel! {
        didSet {
            shorterThanLabel.style = .primaryText02
            shorterThanLabel.font = .font(ofSize: 15.0, weight: .medium, scalingWith: .subheadline)
        }
    }

    @IBOutlet var shorterThanDescription: ThemeableLabel! {
        didSet {
            shorterThanDescription.style = .primaryText02
            shorterThanDescription.font = .font(ofSize: 15.0, weight: .medium, scalingWith: .subheadline)
            shorterThanDescription.text = L10n.filterShorterThanLabel
        }
    }

    @IBOutlet var longerThanStepper: CustomTimeStepper! {
        didSet {
            longerThanStepper.minimumValue = 0
            longerThanStepper.maximumValue = 10.hours
        }
    }

    @IBOutlet var shorterThanStepper: CustomTimeStepper! {
        didSet {
            shorterThanStepper.minimumValue = 5.minutes
            shorterThanStepper.maximumValue = 10.hours
        }
    }

    @IBOutlet var filterSwitch: ThemeableSwitch! {
        didSet {
            filterSwitch.isOn = filter.filterDuration
        }
    }
    @IBOutlet weak var filterSwitchTopConstraint: NSLayoutConstraint! {
        didSet {
            filterSwitchTopConstraint.constant = 10
        }
    }

    @IBOutlet var durationConfigView: UIView!

    @IBOutlet var saveBtn: ThemeableRoundedButton! {
        didSet {
            saveBtn.backgroundColor = filter.playlistColor()
            saveBtn.layer.cornerRadius = 12
            saveBtn.setTitleColor(ThemeColor.primaryInteractive02(), for: .normal)
            saveBtn.titleLabel?.adjustsFontForContentSizeCategory = true
            saveBtn.titleLabel?.numberOfLines = 0
            saveBtn.setTitle(L10n.playlistSmartRuleSaveButton, for: .normal)
        }
    }

    @IBOutlet var filterDurationLabel: ThemeableLabel! {
        didSet {
            filterDurationLabel.font = .font(ofSize: 18.0, weight: .semibold, scalingWith: .body)
            filterDurationLabel.text = L10n.episodeFilterByDurationLabel
        }
    }

    @IBOutlet weak var dividerView: ThemeDividerView! {
        didSet {
            dividerView.isHidden = true
        }
    }
    @IBOutlet weak var dividerTopConstraint: NSLayoutConstraint! {
        didSet {
            dividerTopConstraint.constant = 10.0
        }
    }
    @IBOutlet weak var dividerBottomConstraint: NSLayoutConstraint! {
        didSet {
            dividerBottomConstraint.constant = 16.0
        }
    }
    @IBOutlet weak var linesSpacing: NSLayoutConstraint! {
        didSet {
            linesSpacing.constant = 30.0
        }
    }
    @IBOutlet weak var topShadowView: TopShadowView! {
        didSet {
            topShadowView.hideShadow = true
        }
    }

    init(filter: EpisodeFilter) {
        self.filter = filter

        super.init(nibName: "FilterDurationViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        largeTitleFont = UIFont.font(ofSize: 22, weight: .bold, scalingWith: .title2)
        navigationItem.largeTitleDisplayMode = .always

        // if this filter has database default shorter or longer than values, set more sensible defaults
        if !filter.filterDuration, filter.shorterThan == 0 {
            filter.shorterThan = 40
        }
        if !filter.filterDuration, filter.longerThan == 0 {
            filter.longerThan = 20
        }

        shorterThanStepper.currentValue = TimeInterval(filter.shorterThan * 60)
        longerThanStepper.currentValue = TimeInterval(filter.longerThan * 60)

        updateDurationSection()
        updateDisplayedTimes()
        handleThemeChanged()
    }

    override func handleThemeChanged() {
        setupNavigationBar()

        let playlistColor: UIColor
        playlistColor = AppTheme.colorForStyle(.primaryInteractive01)

        saveBtn.backgroundColor = playlistColor
        filterSwitch.onTintColor = playlistColor
        shorterThanStepper.tintColor = playlistColor
        longerThanStepper.tintColor = playlistColor
    }

    private func setupNavigationBar() {
        let backgroundColor: UIColor

        title = L10n.filterOptionEpisodeDuration

        backgroundColor = AppTheme.viewBackgroundColor()
        changeNavTint(titleColor: AppTheme.colorForStyle(.primaryText01), iconsColor: AppTheme.colorForStyle(.primaryIcon03), backgroundColor: AppTheme.viewBackgroundColor())
        title = L10n.filterOptionEpisodeDuration.sentenceCased

        let navigationBar = navigationController?.navigationBar
        navigationBar?.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .automatic

        if !LiquidGlass.isEnabled {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = backgroundColor
            appearance.shadowColor = .clear
            appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: ThemeColor.primaryText01()]
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: ThemeColor.primaryText02()]
            navigationBar?.scrollEdgeAppearance = appearance
            navigationBar?.standardAppearance = appearance
        }
    }

    @IBAction private func saveTapped() {
        if !checkIfSettingsValid() { return }

        filter.syncStatus = SyncStatus.notSynced.rawValue
        DataManager.sharedManager.save(playlist: filter)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: filter)
        navigationController?.popViewController(animated: true)

        if !filter.isNew {
            Analytics.track(.filterUpdated, properties: ["group": "episode_duration", "source": "filters"])
        }
    }

    @IBAction func longerThanChanged(_ sender: CustomTimeStepper) {
        let minutes = sender.currentValue / 60
        filter.longerThan = Int32(minutes)

        updateDisplayedTimes()
    }

    @IBAction func shorterThanChanged(_ sender: CustomTimeStepper) {
        let minutes = sender.currentValue / 60
        filter.shorterThan = Int32(minutes)

        updateDisplayedTimes()
    }

    @IBAction func filterSwitchChanged(_ sender: UISwitch) {
        filter.filterDuration = sender.isOn
        updateDurationSection()
    }

    private func updateDurationSection() {
        durationConfigView.alpha = filter.filterDuration ? 1 : 0.4
        durationConfigView.isUserInteractionEnabled = filter.filterDuration
    }

    private func updateDisplayedTimes() {
        shorterThanLabel.text = TimeFormatter.shared.multipleUnitFormattedShortTime(time: shorterThanStepper.currentValue)
        longerThanLabel.text = TimeFormatter.shared.multipleUnitFormattedShortTime(time: longerThanStepper.currentValue)
    }

    private func checkIfSettingsValid() -> Bool {
        if !filter.filterDuration { return true }

        let shorterThanTime = TimeFormatter.shared.multipleUnitFormattedShortTime(time: shorterThanStepper.currentValue)
        let longerThanTime = TimeFormatter.shared.multipleUnitFormattedShortTime(time: longerThanStepper.currentValue)
        if filter.longerThan >= filter.shorterThan {
            SJUIUtils.showAlert(title: L10n.filterOptionEpisodeDurationErrorTitle, message: L10n.filterOptionEpisodeDurationErrorMsgFormat(longerThanTime, shorterThanTime), from: self)

            return false
        }

        return true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait // since this controller is presented modally it needs to tell iOS it only goes portrait
    }
}
