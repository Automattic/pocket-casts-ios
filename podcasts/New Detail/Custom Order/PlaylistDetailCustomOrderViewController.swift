import UIKit
import SwiftUI
import PocketCastsDataModel

class PlaylistDetailCustomOrderViewController: PCViewController {
    private weak var viewModel: PlaylistDetailViewModel?
    private var episodes: [ListEpisode] = []

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

    init(viewModel: PlaylistDetailViewModel) {
        self.viewModel = viewModel
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
        episodes = viewModel?.episodes ?? []

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
        tableView.register(PlaylistEpisodePreviewCell.self, forCellReuseIdentifier: PlaylistEpisodePreviewCell.reuseIdentifier)
    }
}

extension PlaylistDetailCustomOrderViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistEpisodePreviewCell.reuseIdentifier, for: indexPath) as! PlaylistEpisodePreviewCell
        let listEpisode = episodes[indexPath.row]
        cell.set(episode: listEpisode.episode)
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
            viewModel?.delete(episodes: [episode.episode.uuid])

            episodes.remove(at: indexPath.row)
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .top)
            tableView.endUpdates()

            // TODO: Add analytics
        }
    }

    // MARK: - Cell reordering

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath == destinationIndexPath { return }

        viewModel?.updatePlaylist(sortType: .dragAndDrop)

        let movedObject = episodes[sourceIndexPath.row]
        episodes.remove(at: sourceIndexPath.row)
        episodes.insert(movedObject, at: destinationIndexPath.row)

        viewModel?.move(episode: movedObject, toIndex: destinationIndexPath.row)

        // TODO: Add analytics
    }
}
