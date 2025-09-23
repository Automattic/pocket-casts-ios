import UIKit
import SwiftUI
import PocketCastsDataModel

class PlaylistDetailCustomOrderViewController: PCViewController {
    private static let cellIdentifier = "EpisodeCell"

    private var episodes: [ListEpisode]
    private let playlistUUID: String

    private(set) var tableView: ThemeableTable! {
        didSet {
            tableView.themeStyle = .primaryUi02
            tableView.sectionHeaderTopPadding = 0
            tableView.estimatedRowHeight = 80
            tableView.rowHeight = UITableView.automaticDimension
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.isEditing = true
            registerCells()
        }
    }

    init(episodes: [ListEpisode], playlistUUID: String) {
        self.episodes = episodes
        self.playlistUUID = playlistUUID
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppTheme.viewBackgroundColor()

        setupNavBar()
        setupContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.reloadData()
    }

    private func setupNavBar() {
        let backgroundColor = AppTheme.viewBackgroundColor()
        changeNavTint(titleColor: AppTheme.colorForStyle(.primaryText01), iconsColor: AppTheme.colorForStyle(.primaryIcon03), backgroundColor: backgroundColor)

        title = L10n.playlistManualEpisodesOrderOption
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = AppTheme.colorForStyle(.primaryUi01)
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

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])

        view.layoutSubviews()

        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: tableView)
    }

    private func registerCells() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Test")
    }
}

extension PlaylistDetailCustomOrderViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Test", for: indexPath)
        cell.separatorInset = UIEdgeInsets(top: 0, left: .greatestFiniteMagnitude, bottom: 0, right: 0)
        cell.layoutMargins = .zero
        cell.preservesSuperviewLayoutMargins = false

        let listEpisode = episodes[indexPath.row]
        cell.contentConfiguration = UIHostingConfiguration {
            PlaylistEpisodePreviewRowView(
                episode: listEpisode.episode,
                hideSeparator: true
            )
            .environmentObject(Theme.sharedTheme)
            .frame(maxWidth: .infinity, minHeight: 80.0, alignment: .leading)
            .padding(.leading, 16.0)
            .padding(.vertical, 5.0)
        }
        .margins(.horizontal, 0)
        .margins(.vertical, 0)
        return cell
    }

    // MARK: - Editing

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        false
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete, let episode = episodes[safe: indexPath.row] {
//            PlaylistManager.delete(playlist: playlist, fireEvent: false)
//            playlists.remove(at: indexPath.row)
//            tableView.beginUpdates()
//            tableView.deleteRows(at: [indexPath], with: .top)
//            tableView.endUpdates()
//
//            Analytics.track(.filterDeleted)
        }
    }

    // MARK: - Cell reordering

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//        if sourceIndexPath == destinationIndexPath { return }
//
//        let movedObject = playlists[sourceIndexPath.row]
//        playlists.remove(at: sourceIndexPath.row)
//        playlists.insert(movedObject, at: destinationIndexPath.row)
//
//        // ok, we've now sorted the list that needed sorting, update the sort positions in the DB and mark that list as not synced
//        for (index, filter) in playlists.enumerated() {
//            DataManager.sharedManager.updatePosition(playlist: filter, newPosition: Int32(index))
//        }
//
//        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged)
//
//        Analytics.track(.filterListReordered)
    }
}

class TestCell: EpisodeCell {
    override func setEditing(_ editing: Bool, animated: Bool) { }
}
