import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class FilterDurationViewController: PCViewController {
    private let filter: EpisodeFilter

    @IBOutlet var longerThanLabel: ThemeableLabel! {
        didSet {
            if FeatureFlag.playlistsRebranding.enabled {
                longerThanLabel.style = .primaryText02
                longerThanLabel.font = .systemFont(ofSize: 15.0, weight: .medium)
            } else {
                longerThanLabel.style = .primaryText01
                longerThanLabel.font = .systemFont(ofSize: 17.0, weight: .regular)
            }
        }
    }

    @IBOutlet var longerThanDescription: ThemeableLabel! {
        didSet {
            if FeatureFlag.playlistsRebranding.enabled {
                longerThanDescription.style = .primaryText02
                longerThanDescription.font = .systemFont(ofSize: 15.0, weight: .medium)
            } else {
                longerThanDescription.style = .primaryText01
                longerThanDescription.font = .systemFont(ofSize: 17.0, weight: .regular)
            }
            longerThanDescription.text = L10n.filterLongerThanLabel
        }
    }

    @IBOutlet var shorterThanLabel: ThemeableLabel! {
        didSet {
            if FeatureFlag.playlistsRebranding.enabled {
                shorterThanLabel.style = .primaryText02
                shorterThanLabel.font = .systemFont(ofSize: 15.0, weight: .medium)
            } else {
                shorterThanLabel.style = .primaryText01
                shorterThanLabel.font = .systemFont(ofSize: 17.0, weight: .regular)
            }
        }
    }

    @IBOutlet var shorterThanDescription: ThemeableLabel! {
        didSet {
            if FeatureFlag.playlistsRebranding.enabled {
                shorterThanDescription.style = .primaryText02
                shorterThanDescription.font = .systemFont(ofSize: 15.0, weight: .medium)
            } else {
                shorterThanDescription.style = .primaryText01
                shorterThanDescription.font = .systemFont(ofSize: 17.0, weight: .regular)
            }
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
            filterSwitchTopConstraint.constant = FeatureFlag.playlistsRebranding.enabled ? 10 : 20
        }
    }

    @IBOutlet var durationConfigView: UIView!

    @IBOutlet var saveBtn: ThemeableRoundedButton! {
        didSet {
            saveBtn.backgroundColor = filter.playlistColor()
            saveBtn.layer.cornerRadius = 12
            saveBtn.setTitleColor(ThemeColor.primaryInteractive02(), for: .normal)
            if FeatureFlag.playlistsRebranding.enabled {
                saveBtn.setTitle(L10n.playlistSmartRuleSaveButton, for: .normal)
            } else {
                saveBtn.setTitle(L10n.filterUpdate, for: .normal)
            }
        }
    }

    @IBOutlet var filterDurationLabel: ThemeableLabel! {
        didSet {
            if FeatureFlag.playlistsRebranding.enabled {
                filterDurationLabel.font = .systemFont(ofSize: 18.0, weight: .semibold)
            } else {
                filterDurationLabel.font = .systemFont(ofSize: 18.0, weight: .regular)
            }
            filterDurationLabel.text = L10n.episodeFilterByDurationLabel
        }
    }

    @IBOutlet weak var dividerView: ThemeDividerView! {
        didSet {
            dividerView.isHidden = FeatureFlag.playlistsRebranding.enabled
        }
    }
    @IBOutlet weak var dividerTopConstraint: NSLayoutConstraint! {
        didSet {
            dividerTopConstraint.constant = FeatureFlag.playlistsRebranding.enabled ? 10.0 : 20.0
        }
    }
    @IBOutlet weak var dividerBottomConstraint: NSLayoutConstraint! {
        didSet {
            dividerBottomConstraint.constant = FeatureFlag.playlistsRebranding.enabled ? 16.0 : 20.0
        }
    }
    @IBOutlet weak var linesSpacing: NSLayoutConstraint! {
        didSet {
            linesSpacing.constant = FeatureFlag.playlistsRebranding.enabled ? 30.0 : 36.0
        }
    }
    @IBOutlet weak var topShadowView: TopShadowView! {
        didSet {
            topShadowView.hideShadow = FeatureFlag.playlistsRebranding.enabled
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
        if FeatureFlag.playlistsRebranding.enabled {
            largeTitleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
            navigationItem.largeTitleDisplayMode = .always
        } else {
            let closeButton = createStandardCloseButton(imageName: "cancel")
            closeButton.addTarget(self, action: #selector(closeTapped(_:)), for: .touchUpInside)
            let backButtonItem = UIBarButtonItem(customView: closeButton)
            navigationItem.leftBarButtonItem = backButtonItem
        }

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
        if FeatureFlag.playlistsRebranding.enabled {
            playlistColor = AppTheme.colorForStyle(.primaryInteractive01)
        } else {
            playlistColor = filter.playlistColor()
        }

        saveBtn.backgroundColor = playlistColor
        filterSwitch.onTintColor = playlistColor
        shorterThanStepper.tintColor = playlistColor
        longerThanStepper.tintColor = playlistColor
    }

    private func setupNavigationBar() {
        title = L10n.filterOptionEpisodeDuration
        let backgroundColor: UIColor
        if FeatureFlag.playlistsRebranding.enabled {
            backgroundColor = AppTheme.viewBackgroundColor()
            changeNavTint(titleColor: AppTheme.colorForStyle(.primaryText01), iconsColor: AppTheme.colorForStyle(.primaryIcon03), backgroundColor: AppTheme.viewBackgroundColor())
        } else {
            backgroundColor = ThemeColor.primaryUi01()
            changeNavTint(titleColor: nil, iconsColor: AppTheme.colorForStyle(.primaryIcon02))
        }

        let navigationBar = navigationController?.navigationBar
        navigationBar?.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .automatic

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = backgroundColor
        appearance.shadowColor = .clear
        appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: ThemeColor.primaryText01()]
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: ThemeColor.primaryText02()]
        navigationBar?.scrollEdgeAppearance = appearance
        navigationBar?.standardAppearance = appearance
    }

    @IBAction private func saveTapped() {
        if !checkIfSettingsValid() { return }

        filter.syncStatus = SyncStatus.notSynced.rawValue
        DataManager.sharedManager.save(playlist: filter)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: filter)
        if FeatureFlag.playlistsRebranding.enabled {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }

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

    @objc private func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait // since this controller is presented modally it needs to tell iOS it only goes portrait
    }
}
