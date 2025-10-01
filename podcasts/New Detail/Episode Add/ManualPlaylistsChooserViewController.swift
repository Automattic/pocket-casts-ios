import UIKit
import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

class ManualPlaylistsChooserViewController: PCViewController {
    private var manualPlaylists: [EpisodeFilter] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    private var initialSelectedPlaylists: Set<String> = []
    private var newSelectedPlaylists: Set<String> = []
    private let episode: Episode
    private let dataManager = DataManager.sharedManager

    private var tableView: ThemeableTable! {
        didSet {
            tableView.themeStyle = .primaryUi01
            tableView.estimatedRowHeight = 80
            tableView.rowHeight = UITableView.automaticDimension
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.sectionHeaderTopPadding = 0
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.register(PlaylistCell.self, forCellReuseIdentifier: PlaylistCell.reuseIdentifier)
        }
    }

    private var doneButton: UIButton! {
        didSet {
            doneButton.translatesAutoresizingMaskIntoConstraints = false
            doneButton.backgroundColor = AppTheme.colorForStyle(.primaryInteractive01)
            doneButton.layer.cornerRadius = 12
            doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
            let attributedTitle = NSAttributedString(string: L10n.done, attributes: [NSAttributedString.Key.foregroundColor: ThemeColor.primaryInteractive02(), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18.0, weight: .semibold)])
            doneButton.setAttributedTitle(attributedTitle, for: .normal)
        }
    }

    private var footerView: ThemeableView! {
        didSet {
            footerView.translatesAutoresizingMaskIntoConstraints = false
            footerView.backgroundColor = AppTheme.viewBackgroundColor()
        }
    }

    init(episode: Episode) {
        self.episode = episode
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBar()
        addCloseButton()
        setupContent()
    }

    private func setupNavBar() {
        let backgroundColor = AppTheme.viewBackgroundColor()
        changeNavTint(titleColor: AppTheme.colorForStyle(.primaryText01), iconsColor: AppTheme.colorForStyle(.primaryIcon03), backgroundColor: backgroundColor)

        title = L10n.playlistManualEpisodeAddToPlaylist

        largeTitleFont = UIFont.systemFont(ofSize: 22, weight: .bold)

        navigationController?.navigationBar.prefersLargeTitles = false

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = backgroundColor
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
        isModalInPresentation = true

        view.backgroundColor = AppTheme.viewBackgroundColor()

        tableView = ThemeableTable()
        view.insertSubview(tableView, at: 0)

        footerView = ThemeableView()
        view.addSubview(footerView)

        doneButton = UIButton(type: .custom)
        footerView.addSubview(doneButton)

        NSLayoutConstraint.activate([
            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            footerView.heightAnchor.constraint(equalToConstant: 110),
            footerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),

            doneButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 16),
            doneButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -16),
            doneButton.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -34),
            doneButton.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 16),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: footerView.topAnchor, constant: 0)
        ])

        view.layoutSubviews()

        manualPlaylists = dataManager.allManualPlaylists(includeDeleted: false)

        let uuids = dataManager.manualPlaylistUUIDs(for: episode.uuid)
        initialSelectedPlaylists = Set(uuids)
        newSelectedPlaylists = initialSelectedPlaylists
    }

    private func addCloseButton() {
        let closeButton = createStandardCloseButton(imageName: "cancel")
        closeButton.addTarget(self, action: #selector(closeTapped(_:)), for: .touchUpInside)

        let backButtonItem = UIBarButtonItem(customView: closeButton)
        navigationItem.leftBarButtonItem = backButtonItem
    }

    @objc private func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @objc private func doneTapped() {
        let added = newSelectedPlaylists.subtracting(initialSelectedPlaylists)
        let removed = initialSelectedPlaylists.subtracting(newSelectedPlaylists)

        FileLog.shared.console("Added \(added), removed \(removed)")

        manualPlaylists.forEach { playlist in
            if added.contains(playlist.uuid) {
                dataManager.add(episodes: [episode], to: playlist)
            }
            if removed.contains(playlist.uuid) {
                dataManager.deleteEpisodes([episode.uuid], from: playlist)
            }
        }

        dismiss(animated: true, completion: nil)
    }
}

extension ManualPlaylistsChooserViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        default:
            return manualPlaylists.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistCell.reuseIdentifier, for: indexPath) as! PlaylistCell
        switch indexPath.section {
        case 0:
            cell.configureAddPlaylistCell()
        default:
            let playlist = manualPlaylists[indexPath.row]
            let onToggleChange: (Bool) -> Void = { [weak self] selected in
                guard let self = self else { return }

                if selected {
                    self.newSelectedPlaylists.insert(playlist.uuid)
                } else {
                    self.newSelectedPlaylists.remove(playlist.uuid)
                }
            }
            let isSelected = Binding<Bool>(
                get: { [weak self] in
                    guard let self = self else { return false }
                    return self.newSelectedPlaylists.contains(playlist.uuid)
                },
                set: { newValue in
                    onToggleChange(newValue)
                }
            )
            cell.configure(
                cellType: .check,
                playlist: playlist,
                isLastRow: indexPath.row == manualPlaylists.count - 1,
                isSelected: isSelected)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }

        tableView.deselectRow(at: indexPath, animated: true)

        // TODO: Push manual playlist creation
    }
}
