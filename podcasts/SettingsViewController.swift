import PocketCastsServer
import PocketCastsUtils
import SwiftUI
import UIKit
import WatchConnectivity

class SettingsViewController: PCViewController, UITableViewDataSource, UITableViewDelegate {
    private enum TableRow: String {
        case general, notifications, appearance, storageAndDataUse
        case autoArchive, autoDownload, autoAddToUpNext, siriShortcuts
        case watch, customFiles, importSteps, opml
        case about, pocketCastsPlus, privacy
        case headphoneControls
        case developer, beta

        /// Whether the section should be displayed or not
        var visible: Bool {
            switch self {
            case .watch:
                return WCSession.isSupported()

            case .pocketCastsPlus:
                return !SubscriptionHelper.hasActiveSubscription()

            default:
                return true
            }
        }

        var display: (text: String, image: UIImage?) {
            switch self {
            case .general:
                return (L10n.settingsGeneral, UIImage(named: "profile-settings"))
            case .notifications:
                return (L10n.settingsNotifications, UIImage(named: "settings_notifications"))
            case .appearance:
                return (L10n.settingsAppearance, UIImage(named: "settings_appearance"))
            case .storageAndDataUse:
                return (L10n.settingsStorage, UIImage(named: "settings_storage"))
            case .autoArchive:
                return (L10n.settingsAutoArchive, UIImage(named: "settings_archive"))
            case .autoAddToUpNext:
                return (L10n.settingsAutoAdd, UIImage(named: "playlast"))
            case .autoDownload:
                return (L10n.settingsAutoDownload, UIImage(named: "settings_autodownload"))
            case .importSteps:
                return (L10n.welcomeImportButton, UIImage(named: "settings_import_podcasts"))
            case .opml:
                return (L10n.exportPodcastsOption, UIImage(named: "settings_export_podcasts"))
            case .about:
                return (L10n.settingsAbout, UIImage(named: "settings_about"))
            case .siriShortcuts:
                return (L10n.settingsSiriShortcuts, UIImage(named: "settings_shortcuts"))
            case .customFiles:
                return (L10n.files, UIImage(named: "profile_files"))
            case .watch:
                return (L10n.appleWatch, UIImage(named: "settings_watch"))
            case .pocketCastsPlus:
                return (L10n.pocketCastsPlus, UIImage(named: "plusGold24"))
            case .privacy:
                return (L10n.settingsPrivacy, UIImage(named: "privacy"))
            case .developer:
                return ("Developer", UIImage(systemName: "ladybug.fill"))
            case .beta:
                return ("Beta Features", UIImage(systemName: "testtube.2"))
            case .headphoneControls:
                return (L10n.settingsHeadphoneControls, .init(named: "settings_headphone_controls"))
            }
        }
    }

    private var tableData: [[TableRow]] = []

    /// All the possible settings sections
    private let allSections: [[TableRow]] = {
        #if DEBUG
        let developerSection: [TableRow] = [.developer, .beta]
        #else
        let developerSection: [TableRow] = []
        #endif

        return [
            developerSection,
            [.pocketCastsPlus],
            [.general, .notifications, .appearance],
            [.autoArchive, .autoDownload, .autoAddToUpNext],
            [.storageAndDataUse, .siriShortcuts, .headphoneControls, .watch, .customFiles],
            [.importSteps, .opml],
            [.privacy, .about]
        ]
    }()

    private let settingsCellId = "SettingsCell"

    @IBOutlet var settingsTable: UITableView! {
        didSet {
            settingsTable.register(UINib(nibName: "TopLevelSettingsCell", bundle: nil), forCellReuseIdentifier: settingsCellId)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.settings
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: settingsTable)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadTable()
    }

    // MARK: - UITableView Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        tableData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: settingsCellId, for: indexPath) as! TopLevelSettingsCell
        cell.plusIndicator.isHidden = true

        let tableRow = tableData[indexPath.section][indexPath.row]
        cell.settingsLabel.text = tableRow.display.text
        cell.settingsLabel.accessibilityIdentifier = tableRow.rawValue
        cell.settingsImage.image = tableRow.display.image

        switch tableRow {
        case .appearance, .customFiles, .watch:
            cell.plusIndicator.isHidden = SubscriptionHelper.hasActiveSubscription()
        default:
            break
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let tableRow = tableData[indexPath.section][indexPath.row]
        switch tableRow {
        case .general:
            navigationController?.pushViewController(GeneralSettingsViewController(), animated: true)
        case .notifications:
            navigationController?.pushViewController(NotificationsViewController(), animated: true)
        case .appearance:
            navigationController?.pushViewController(AppearanceViewController(), animated: true)
        case .storageAndDataUse:
            navigationController?.pushViewController(StorageAndDataUseViewController(), animated: true)
        case .autoAddToUpNext:
            navigationController?.pushViewController(AutoAddToUpNextViewController(), animated: true)
        case .autoArchive:
            navigationController?.pushViewController(AutoArchiveViewController(), animated: true)
        case .autoDownload:
            navigationController?.pushViewController(DownloadSettingsViewController(), animated: true)
        case .importSteps:
            let controller = ImportViewModel.make(source: "settings", showSubtitle: false)
            navigationController?.present(controller, animated: true)
        case .opml:
            navigationController?.pushViewController(ImportExportViewController(), animated: true)
        case .about:
            Analytics.track(.settingsAboutShown)

            let aboutView = AboutView(dismissAction: { [weak self] in
                self?.navigationController?.dismiss(animated: true, completion: nil)
            }).environmentObject(Theme.sharedTheme)
            let hostingController = PCHostingController(rootView: aboutView)

            navigationController?.present(hostingController, animated: true, completion: nil)
        case .siriShortcuts:
            navigationController?.pushViewController(SiriSettingsViewController(), animated: true)
        case .customFiles:
            navigationController?.pushViewController(UploadedSettingsViewController(), animated: true)
        case .watch:
            navigationController?.pushViewController(WatchSettingsViewController(), animated: true)
        case .pocketCastsPlus:
            navigationController?.present(OnboardingFlow.shared.begin(flow: .plusUpsell, source: "settings"), animated: true)
        case .privacy:
            navigationController?.pushViewController(PrivacySettingsViewController(), animated: true)
        case .developer:
            let hostingController = UIHostingController(rootView: DeveloperMenu().setupDefaultEnvironment())
            navigationController?.pushViewController(hostingController, animated: true)
        case .beta:
            let hostingController = UIHostingController(rootView: BetaMenu().setupDefaultEnvironment())
            hostingController.title = "Beta Features"
            navigationController?.pushViewController(hostingController, animated: true)
        case .headphoneControls:
            navigationController?.pushViewController(HeadphoneSettingsViewController(), animated: true)
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        1
    }

    private func reloadTable() {
        tableData = allSections.compactMap {
            $0.filter(\.visible).nilIfEmpty()
        }

        settingsTable.reloadData()
    }
}
