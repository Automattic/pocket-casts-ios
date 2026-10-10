import PocketCastsServer
import PocketCastsUtils
import SwiftUI
import UIKit
import WatchConnectivity

class SettingsViewController: PCViewController, UITableViewDataSource, UITableViewDelegate {
    enum TableRow: String {
        case general, notifications, appearance, storageAndDataUse
        case autoArchive, autoDownload, autoAddToUpNext, siriShortcuts
        case watch, customFiles, importSteps, opml
        case about, pocketCastsPlus, privacy
        case upNextHistory, foldersHistory
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
            case .upNextHistory:
                return (L10n.upNextHistory, .init(named: "upnext"))
            case .foldersHistory:
                return (L10n.foldersHistory, .init(named: "folder-empty"))
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
            [.upNextHistory, .foldersHistory],
            [.privacy, .about]
        ]
    }()

    private let settingsCellId = "SettingsCell"

    private var selectedRow: TableRow?

    private var isShowingPageSideBySide: Bool {
        splitViewController?.isCollapsed == false
    }

    @IBOutlet var settingsTable: UITableView! {
        didSet {
            settingsTable.register(UINib(nibName: "TopLevelSettingsCell", bundle: nil), forCellReuseIdentifier: settingsCellId)
            settingsTable.rowHeight = UITableView.automaticDimension
            settingsTable.estimatedRowHeight = UITableView.automaticDimension
            settingsTable.sectionHeaderHeight = UITableView.automaticDimension
            settingsTable.estimatedSectionHeaderHeight = Constants.Values.tableSectionHeaderHeight
            settingsTable.sectionFooterHeight = UITableView.automaticDimension
            settingsTable.estimatedSectionFooterHeight = Constants.Values.tableSectionHeaderHeight
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

        let showsDisclosureIndicator = !isShowingPageSideBySide
        if cell.showsDisclosureIndicator != showsDisclosureIndicator {
            cell.showsDisclosureIndicator = showsDisclosureIndicator
            cell.updateColor()
        }

        switch tableRow {
        case .appearance, .customFiles, .watch:
            cell.plusIndicator.isHidden = SubscriptionHelper.hasActiveSubscription()
        default:
            break
        }

        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath == tableView.indexPathForSelectedRow {
            cell.setSelected(true, animated: false)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tableRow = tableData[indexPath.section][indexPath.row]
        selectRow(tableRow)
        updateTableSelection(animated: true)
    }

    func selectRow(_ tableRow: TableRow) {
        switch tableRow {
        case .general:
            show(GeneralSettingsViewController(), for: tableRow)
        case .notifications:
            show(NotificationsViewController(), for: tableRow)
        case .appearance:
            show(AppearanceViewController(), for: tableRow)
        case .storageAndDataUse:
            show(StorageAndDataUseViewController(), for: tableRow)
        case .autoAddToUpNext:
            show(AutoAddToUpNextViewController(), for: tableRow)
        case .autoArchive:
            show(AutoArchiveViewController(), for: tableRow)
        case .autoDownload:
            show(DownloadSettingsViewController(), for: tableRow)
        case .importSteps:
            let controller = ImportViewModel.make(source: "settings", showSubtitle: false)
            navigationController?.present(controller, animated: true)
        case .opml:
            show(ImportExportViewController(), for: tableRow)
        case .about:
            Analytics.track(.settingsAboutShown)

            let aboutView = AboutView()
                .environmentObject(Theme.shared)
            let hostingController = PCHostingController(rootView: aboutView)

            navigationController?.present(hostingController, animated: true, completion: nil)
        case .siriShortcuts:
            show(SiriSettingsViewController(), for: tableRow)
        case .customFiles:
            show(UploadedSettingsViewController(), for: tableRow)
        case .watch:
            show(WatchSettingsViewController(), for: tableRow)
        case .pocketCastsPlus:
                navigationController?.present(OnboardingFlow.shared.begin(flow: .plusUpsell, source: .settings, traitCollection: traitCollection), animated: true)
        case .privacy:
            show(PrivacySettingsViewController(), for: tableRow)
        case .developer:
            let hostingController = UIHostingController(rootView: DeveloperMenu().setupDefaultEnvironment())
            hostingController.title = "Developer"
            show(hostingController, for: tableRow)
        case .beta:
            let hostingController = UIHostingController(rootView: BetaMenu().setupDefaultEnvironment())
            hostingController.title = "Beta Features"
            show(hostingController, for: tableRow)
        case .headphoneControls:
            show(HeadphoneSettingsViewController(), for: tableRow)
        case .upNextHistory:
            let upNextHistory = UpNextHistoryViewController()
            show(upNextHistory, for: tableRow)
        case .foldersHistory:
            let foldersHistoryViewController = FolderHistoryViewController()
            show(foldersHistoryViewController, for: tableRow)
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
        updateTableSelection(animated: false)
    }

    private func updateTableSelection(animated: Bool) {
        if isShowingPageSideBySide, let selectedRow, let indexPath = indexPath(for: selectedRow) {
            settingsTable.selectRow(at: indexPath, animated: animated, scrollPosition: .none)
        } else if let indexPath = settingsTable.indexPathForSelectedRow {
            settingsTable.deselectRow(at: indexPath, animated: animated)
        }
    }

    private func indexPath(for tableRow: TableRow) -> IndexPath? {
        for (section, rows) in tableData.enumerated() {
            if let row = rows.firstIndex(of: tableRow) {
                return IndexPath(row: row, section: section)
            }
        }
        return nil
    }

    // MARK: - Split View

    /// Shows a settings page next to the list when Settings is in a split view, otherwise pushes it.
    func show(_ viewController: UIViewController, for tableRow: TableRow, animated: Bool = true) {
        selectedRow = tableRow

        guard let splitViewController else {
            navigationController?.pushViewController(viewController, animated: animated)
            return
        }
        splitViewController.showDetailViewController(SJUIUtils.navController(for: viewController), sender: self)
        if isViewLoaded {
            updateTableSelection(animated: false)
        }
    }

    /// Opens Settings from `navigationController`. On large screens, presents the list and the selected page
    /// side by side in a sheet; otherwise pushes the list.
    static func open(from navigationController: UINavigationController, animated: Bool, completion: ((SettingsViewController) -> Void)? = nil) {
        let settingsViewController = SettingsViewController()

        // Check the window's traits: MainTabBarController can leave its children with a compact horizontal size class on iPad
        guard let windowTraits = navigationController.view.window?.traitCollection,
              windowTraits.horizontalSizeClass == .regular, windowTraits.verticalSizeClass == .regular else {
            navigationController.pushViewController(settingsViewController, animated: animated)
            completion?(settingsViewController)
            return
        }

        settingsViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: settingsViewController, action: #selector(closeTapped))
        settingsViewController.selectedRow = .general

        let splitViewController = UISplitViewController(style: .doubleColumn)
        splitViewController.preferredDisplayMode = .oneBesideSecondary
        splitViewController.preferredSplitBehavior = .tile
        splitViewController.presentsWithGesture = false
        splitViewController.modalPresentationStyle = .formSheet
        splitViewController.delegate = settingsViewController
        splitViewController.setViewController(SJUIUtils.navController(for: settingsViewController), for: .primary)
        splitViewController.setViewController(SJUIUtils.navController(for: GeneralSettingsViewController()), for: .secondary)

        let present = {
            navigationController.present(splitViewController, animated: animated) {
                completion?(settingsViewController)
            }
        }

        guard let presentedViewController = navigationController.presentedViewController else {
            present()
            return
        }
        if presentedViewController.isBeingDismissed, let transitionCoordinator = presentedViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { _ in present() }
        } else {
            navigationController.dismiss(animated: false, completion: present)
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

extension SettingsViewController: UISplitViewControllerDelegate {
    func splitViewControllerDidCollapse(_ svc: UISplitViewController) {
        if isViewLoaded {
            reloadTable()
        }
    }

    func splitViewControllerDidExpand(_ svc: UISplitViewController) {
        if isViewLoaded {
            reloadTable()
        }
    }
}
