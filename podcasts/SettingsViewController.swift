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

    fileprivate weak var listDetailViewController: SettingsListDetailViewController?

    private var isShowingPageSideBySide: Bool {
        listDetailViewController?.isShowingDetail == true
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

    fileprivate func reloadTable() {
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

    // MARK: - List and Detail

    /// Shows a settings page next to the list when they're side by side, otherwise pushes it.
    func show(_ viewController: UIViewController, for tableRow: TableRow, animated: Bool = true) {
        selectedRow = tableRow

        guard let listDetailViewController, listDetailViewController.isShowingDetail else {
            navigationController?.pushViewController(viewController, animated: animated)
            return
        }
        listDetailViewController.showDetail(viewController)
        if isViewLoaded {
            updateTableSelection(animated: false)
        }
    }

    /// Opens Settings from `navigationController`. On regular width, presents the list and the selected page
    /// side by side full screen; otherwise pushes the list.
    static func open(from navigationController: UINavigationController, animated: Bool, completion: ((SettingsViewController) -> Void)? = nil) {
        let settingsViewController = SettingsViewController()

        guard navigationController.view.window?.windowScene?.traitCollection.horizontalSizeClass == .regular else {
            navigationController.pushViewController(settingsViewController, animated: animated)
            completion?(settingsViewController)
            return
        }

        settingsViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: settingsViewController, action: #selector(closeTapped))
        let listDetailViewController = SettingsListDetailViewController(settingsViewController: settingsViewController)

        let present = {
            navigationController.present(listDetailViewController, animated: animated) {
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

    fileprivate func makeDefaultPage() -> UIViewController {
        selectedRow = .general
        return GeneralSettingsViewController()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

/// Shows the Settings list and the selected page side by side, and collapses them into the list's navigation
/// stack when the window becomes compact.
///
/// Not a `UISplitViewController`: on iPadOS 26 and later its secondary column extends under the sidebar,
/// which misplaces the system section footers of the settings pages. The size class comes from the window
/// scene because, on iPad, `MainTabBarController` gives its tabs, and what they present, a compact one.
private final class SettingsListDetailViewController: UIViewController {
    private let settingsViewController: SettingsViewController
    private let listNavigationController: UINavigationController
    private var detailNavigationController: UINavigationController?
    private let columnDivider = ThemeDividerView()
    private var sideBySideConstraints: [NSLayoutConstraint] = []
    private var fullWidthConstraints: [NSLayoutConstraint] = []

    var isShowingDetail: Bool {
        detailNavigationController != nil
    }

    init(settingsViewController: SettingsViewController) {
        self.settingsViewController = settingsViewController
        listNavigationController = SJUIUtils.navController(for: settingsViewController)
        detailNavigationController = SJUIUtils.navController(for: settingsViewController.makeDefaultPage())
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .fullScreen
        settingsViewController.listDetailViewController = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(listNavigationController)
        let listView: UIView = listNavigationController.view
        listView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(listView)
        listNavigationController.didMove(toParent: self)

        columnDivider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(columnDivider)

        NSLayoutConstraint.activate([
            listView.topAnchor.constraint(equalTo: view.topAnchor),
            listView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            listView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            columnDivider.topAnchor.constraint(equalTo: view.topAnchor),
            columnDivider.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            columnDivider.leadingAnchor.constraint(equalTo: listView.trailingAnchor),
            columnDivider.widthAnchor.constraint(equalToConstant: 1)
        ])
        fullWidthConstraints = [listView.trailingAnchor.constraint(equalTo: view.trailingAnchor)]
        sideBySideConstraints = [listView.widthAnchor.constraint(equalToConstant: 320)]

        if let detailNavigationController {
            installDetail(detailNavigationController)
        } else {
            NSLayoutConstraint.activate(fullWidthConstraints)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        switch view.window?.windowScene?.traitCollection.horizontalSizeClass {
        case .regular where !isShowingDetail:
            expand()
        case .compact where isShowingDetail:
            collapse()
        default:
            break
        }
    }

    override var childForStatusBarStyle: UIViewController? {
        listNavigationController
    }

    func showDetail(_ viewController: UIViewController) {
        detailNavigationController?.setViewControllers([viewController], animated: false)
    }

    private func installDetail(_ detailNavigationController: UINavigationController) {
        self.detailNavigationController = detailNavigationController
        addChild(detailNavigationController)
        let detailView: UIView = detailNavigationController.view
        detailView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(detailView)
        NSLayoutConstraint.deactivate(fullWidthConstraints)
        NSLayoutConstraint.activate(sideBySideConstraints + [
            detailView.topAnchor.constraint(equalTo: view.topAnchor),
            detailView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            detailView.leadingAnchor.constraint(equalTo: columnDivider.trailingAnchor),
            detailView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        detailNavigationController.didMove(toParent: self)
        columnDivider.isHidden = false
    }

    private func expand() {
        let viewControllers = listNavigationController.viewControllers
        var detailViewControllers = Array(viewControllers.dropFirst())
        if detailViewControllers.isEmpty {
            detailViewControllers = [settingsViewController.makeDefaultPage()]
        } else {
            listNavigationController.setViewControllers([settingsViewController], animated: false)
        }
        let detailNavigationController = SJUIUtils.navController(for: detailViewControllers[0])
        detailNavigationController.setViewControllers(detailViewControllers, animated: false)
        installDetail(detailNavigationController)
        if settingsViewController.isViewLoaded {
            settingsViewController.reloadTable()
        }
    }

    private func collapse() {
        guard let detailNavigationController else { return }

        let detailViewControllers = detailNavigationController.viewControllers
        detailNavigationController.willMove(toParent: nil)
        detailNavigationController.view.removeFromSuperview()
        detailNavigationController.removeFromParent()
        detailNavigationController.setViewControllers([], animated: false)
        self.detailNavigationController = nil

        NSLayoutConstraint.deactivate(sideBySideConstraints)
        NSLayoutConstraint.activate(fullWidthConstraints)
        columnDivider.isHidden = true

        listNavigationController.setViewControllers([settingsViewController] + detailViewControllers, animated: false)
        if settingsViewController.isViewLoaded {
            settingsViewController.reloadTable()
        }
    }
}
