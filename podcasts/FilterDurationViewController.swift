import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class FilterDurationViewController: PCViewController {
    private let filter: EpisodeFilter

    @IBOutlet var longerThanLabel: ThemeableLabel! {
        didSet {
            longerThanLabel.style = .primaryText02
        }
    }

    @IBOutlet var longerThanStepper: CustomTimeStepper! {
        didSet {
            longerThanStepper.minimumValue = 0
            longerThanStepper.maximumValue = 10.hours
        }
    }

    @IBOutlet var longerThanDescription: ThemeableLabel! {
        didSet {
            longerThanDescription.text = L10n.filterLongerThanLabel
        }
    }

    @IBOutlet var shorterThanLabel: ThemeableLabel! {
        didSet {
            shorterThanLabel.style = .primaryText02
        }
    }

    @IBOutlet var shorterThanStepper: CustomTimeStepper! {
        didSet {
            shorterThanStepper.minimumValue = 5.minutes
            shorterThanStepper.maximumValue = 10.hours
        }
    }

    @IBOutlet var shorterThanDescription: ThemeableLabel! {
        didSet {
            shorterThanDescription.text = L10n.filterShorterThanLabel
        }
    }

    @IBOutlet var filterSwitch: ThemeableSwitch! {
        didSet {
            filterSwitch.isOn = filter.filterDuration
        }
    }

    @IBOutlet var durationConfigView: UIView!

    @IBOutlet var saveBtn: ThemeableRoundedButton! {
        didSet {
            saveBtn.backgroundColor = filter.playlistColor()
            saveBtn.layer.cornerRadius = 12
            saveBtn.setTitleColor(ThemeColor.primaryInteractive02(), for: .normal)
            saveBtn.setTitle(L10n.filterUpdate, for: .normal)
        }
    }

    @IBOutlet var filterDurationLabel: ThemeableLabel! {
        didSet {
            filterDurationLabel.text = L10n.episodeFilterByDurationLabel
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

        let closeButton = createStandardCloseButton(imageName: "cancel")
        closeButton.addTarget(self, action: #selector(closeTapped(_:)), for: .touchUpInside)
        let backButtonItem = UIBarButtonItem(customView: closeButton)
        navigationItem.leftBarButtonItem = backButtonItem

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

        let playlistColor = filter.playlistColor()
        saveBtn.backgroundColor = playlistColor
        filterSwitch.onTintColor = playlistColor
        shorterThanStepper.tintColor = playlistColor
        longerThanStepper.tintColor = playlistColor
    }

    private func setupNavigationBar() {
        title = L10n.filterOptionEpisodeDuration
        changeNavTint(titleColor: nil, iconsColor: ThemeColor.primaryIcon02())

        let navigationBar = navigationController?.navigationBar
        navigationBar?.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .automatic

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = ThemeColor.primaryUi01()
        appearance.shadowColor = .clear
        appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: ThemeColor.primaryText01()]
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: ThemeColor.primaryText02()]
        navigationBar?.scrollEdgeAppearance = appearance
        navigationBar?.standardAppearance = appearance
    }

    @IBAction private func saveTapped() {
        if !checkIfSettingsValid() { return }

        filter.syncStatus = SyncStatus.notSynced.rawValue
        DataManager.sharedManager.save(filter: filter)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.filterChanged, object: filter)
        dismiss(animated: true, completion: nil)

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
