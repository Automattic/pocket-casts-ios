import UIKit
import SwiftUI
import Combine
import DifferenceKit
import PocketCastsDataModel

class StarredFilterOverlayController: PCViewController {
    private static let starredEpisodeCellId = "StarredEpisodeCellId"
    private static let smartRuleHeaderCellId = "SmartRuleHeaderCellId"

    var filterToEdit: EpisodeFilter!
    var analyticsSource: AnalyticsSource = .filters

    private var tableView: ThemeableTable! {
        didSet {
            tableView.themeStyle = .primaryUi01
            tableView.dataSource = self
            tableView.delegate = self
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.smartRuleHeaderCellId)
            tableView.register(UINib(nibName: "EpisodePreviewCell", bundle: nil), forCellReuseIdentifier: FilterPreviewViewController.previewCellId)
            tableView.rowHeight = UITableView.automaticDimension
        }
    }
    private var viewModel: SmartRuleToggleViewModel!
    private var footerView: ThemeableView! {
        didSet {
            footerView.translatesAutoresizingMaskIntoConstraints = false
            footerView.backgroundColor = AppTheme.viewBackgroundColor()
        }
    }
    private var saveButton: UIButton! {
        didSet {
            saveButton.translatesAutoresizingMaskIntoConstraints = false
            saveButton.backgroundColor = AppTheme.colorForStyle(.primaryInteractive01)
            setupSaveButtonTitle()
            saveButton.layer.cornerRadius = 12
            saveButton.addTarget(self, action: #selector(saveTapped(sender:)), for: .touchUpInside)
        }
    }
    private var cancellables = Set<AnyCancellable>()
    private var episodes = [ListEpisode]()
    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppTheme.viewBackgroundColor()

        setupViewModel()
        setupNavBar()
        setupContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadEpisodes()
    }

    private func setupNavBar() {
        let backgroundColor = AppTheme.viewBackgroundColor()
        changeNavTint(titleColor: AppTheme.colorForStyle(.primaryText01), iconsColor: AppTheme.colorForStyle(.primaryIcon03), backgroundColor: backgroundColor)

        largeTitleFont = UIFont.systemFont(ofSize: 22, weight: .bold)

        title = L10n.statusStarred
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = AppTheme.colorForStyle(.primaryUi01)
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(.primaryText01)
        ]
        appearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(.primaryText01)
        ]
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.sizeToFit()
    }

    private func setupViewModel() {
        viewModel = .init(
            toggleIsOn: filterToEdit.filterStarred,
            title: L10n.playlistSmartRuleStarredHeaderTitle,
            enabledString: L10n.playlistSmartRuleStarredHeaderSubtitleToggleOn,
            disabledString: L10n.playlistSmartRuleStarredHeaderSubtitleToggleOff
        )
        viewModel.$toggleIsOn
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                self?.filterToEdit.filterStarred = newValue
                self?.reloadEpisodes()
            }
            .store(in: &cancellables)
    }

    private func reloadEpisodes() {
        guard viewModel.toggleIsOn else {
            operationQueue.cancelAllOperations()
            episodes.removeAll()
            tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
            return
        }
        let refreshOperation = PlaylistRefreshOperation(playlist: filterToEdit) { [weak self] newData in
            guard let strongSelf = self, strongSelf.viewModel.toggleIsOn else { return }
            strongSelf.episodes = newData
            strongSelf.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        }
        operationQueue.addOperation(refreshOperation)
    }

    private func setupContent() {
        tableView = ThemeableTable()
        view.addSubview(tableView)

        footerView = ThemeableView()
        view.addSubview(footerView)

        saveButton = UIButton(type: .custom)
        footerView.addSubview(saveButton)

        NSLayoutConstraint.activate([
            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            footerView.heightAnchor.constraint(equalToConstant: 110),
            footerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),

            saveButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -16),
            saveButton.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -34),
            saveButton.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 16),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: footerView.topAnchor, constant: 0)
        ])

        view.layoutSubviews()
    }

    private func setupSaveButtonTitle() {
        let attributedTitle = NSAttributedString(string: L10n.playlistSmartRuleSaveButton, attributes: [NSAttributedString.Key.foregroundColor: ThemeColor.primaryInteractive02(), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18.0, weight: .semibold)])
        saveButton.setAttributedTitle(attributedTitle, for: .normal)
    }

    @objc private func saveTapped(sender: Any) {
        filterToEdit.syncStatus = SyncStatus.notSynced.rawValue
        DataManager.sharedManager.save(playlist: filterToEdit)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: filterToEdit)
        navigationController?.popViewController(animated: true)

        if !filterToEdit.isNew {
            Analytics.track(.filterUpdated, properties: ["group": "starred", "source": analyticsSource])
        }
    }
}

extension StarredFilterOverlayController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return episodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.smartRuleHeaderCellId)!
            cell.backgroundColor = AppTheme.colorForStyle(.primaryUi01)
            cell.contentView.backgroundColor = AppTheme.colorForStyle(.primaryUi01)
            cell.contentConfiguration = UIHostingConfiguration {
                SmartRuleToggleHeaderView(viewModel: viewModel)
                    .environmentObject(Theme.sharedTheme)
                    .frame(maxWidth: .infinity, minHeight: 70.0, alignment: .leading)
            }
            .margins(.horizontal, 0)
            .margins(.vertical, 0)
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: FilterPreviewViewController.previewCellId, for: indexPath) as! EpisodePreviewCell
        cell.imageLeftPadding.constant = 16.0
        cell.style = .primaryUi01
        if let listEpisode = episodes[safe: indexPath.row] {
            cell.populateFrom(episode: listEpisode.episode)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
        } else {
            cell.separatorInset = .zero
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        nil
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
