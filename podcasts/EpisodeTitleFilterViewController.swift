import UIKit
import Combine
import PocketCastsDataModel
import PocketCastsUtils

class EpisodeTitleFilterViewController: PCViewController {
    private static let episodeCellId = "EpisodeTitleCellId"
    private static let headerCellId = "EpisodeTitleHeaderCellId"

    var filterToEdit: EpisodeFilter!
    var analyticsSource: AnalyticsSource = .filters

    private var tableView: ThemeableTable! {
        didSet {
            tableView.themeStyle = .primaryUi01
            tableView.dataSource = self
            tableView.delegate = self
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.headerCellId)
            tableView.register(UINib(nibName: "EpisodePreviewCell", bundle: nil), forCellReuseIdentifier: FilterPreviewViewController.previewCellId)
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = UITableView.automaticDimension
            tableView.keyboardDismissMode = .onDrag
        }
    }

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
            saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        }
    }

    private var episodes = [ListEpisode]()
    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppTheme.viewBackgroundColor()

        setupNavBar()
        setupContent()
        reloadEpisodes()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    private func setupNavBar() {
        let backgroundColor = AppTheme.viewBackgroundColor()
        changeNavTint(
            titleColor: AppTheme.colorForStyle(.primaryText01),
            iconsColor: AppTheme.colorForStyle(.primaryIcon03),
            backgroundColor: backgroundColor
        )

        largeTitleFont = UIFont.font(ofSize: 22, weight: .bold, scalingWith: .title2)
        title = SmartPlaylistRule.episodeTitle.title

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

    private func setupContent() {
        tableView = ThemeableTable()
        view.addSubview(tableView)

        footerView = ThemeableView()
        view.addSubview(footerView)

        saveButton = UIButton(type: .custom)
        footerView.addSubview(saveButton)

        NSLayoutConstraint.activate([
            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerView.heightAnchor.constraint(equalToConstant: 110),
            footerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            saveButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -16),
            saveButton.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -34),
            saveButton.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 16),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: footerView.topAnchor)
        ])

        view.layoutSubviews()
    }

    private func setupSaveButtonTitle() {
        saveButton.setTitle(L10n.playlistSmartRuleSaveButton, for: .normal)
        saveButton.tintColor = ThemeColor.primaryInteractive02()
        saveButton.titleLabel?.font = UIFont.font(ofSize: 18.0, weight: .semibold, scalingWith: .headline)
        saveButton.titleLabel?.adjustsFontForContentSizeCategory = true
        saveButton.titleLabel?.numberOfLines = 0
        saveButton.titleLabel?.lineBreakMode = .byWordWrapping
    }

    private func reloadEpisodes() {
        let title = filterToEdit.filterEpisodeTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            operationQueue.cancelAllOperations()
            episodes.removeAll()
            tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
            return
        }
        let refreshOperation = PlaylistRefreshOperation(playlist: filterToEdit) { [weak self] newData in
            guard let self else { return }
            self.episodes = newData
            self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        }
        operationQueue.addOperation(refreshOperation)
    }

    @objc private func saveTapped() {
        filterToEdit.titleSmartRuleApplied = !filterToEdit.filterEpisodeTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        filterToEdit.syncStatus = SyncStatus.notSynced.rawValue
        DataManager.sharedManager.save(playlist: filterToEdit)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: filterToEdit)
        navigationController?.popViewController(animated: true)

        if !filterToEdit.isNew {
            Analytics.track(.filterUpdated, properties: ["group": "episode_title", "source": analyticsSource])
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension EpisodeTitleFilterViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : episodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.headerCellId, for: indexPath)
            cell.backgroundColor = AppTheme.colorForStyle(.primaryUi01)
            cell.contentView.backgroundColor = AppTheme.colorForStyle(.primaryUi01)
            cell.contentConfiguration = UIHostingConfiguration {
                EpisodeTitleFilterHeaderView(
                    currentTitle: self.filterToEdit.filterEpisodeTitle,
                    onTitleChanged: { [weak self] newTitle in
                        self?.filterToEdit.filterEpisodeTitle = newTitle
                        self?.reloadEpisodes()
                    }
                )
                .environmentObject(Theme.sharedTheme)
                .frame(minHeight: 70.0, alignment: .leading)
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
        false
    }
}
