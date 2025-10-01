import UIKit
import SwiftUI
import PocketCastsDataModel

class ManualPlaylistsChooserViewController: PCViewController {
    private var manualPlaylists: [EpisodeFilter] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    private var selectedPlaylists: Set<String> = []
    private let episode: Episode

    var tableView: ThemeableTable! {
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

        title = "Add to playlist"

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

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        view.layoutSubviews()

        manualPlaylists = DataManager.sharedManager.allManualPlaylists(includeDeleted: false)
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
                    self.selectedPlaylists.insert(playlist.uuid)
//                    self.playlistSelected?(playlist)
                } else {
                    self.selectedPlaylists.remove(playlist.uuid)
//                    self.playlistUnselected?(playlist)
                }

//                self.didChange = true
                print("Toggle \(playlist.uuid)")
            }
            let isSelected = Binding<Bool>(
                get: { [weak self] in
                    guard let self = self else { return false }
                    return self.selectedPlaylists.contains(playlist.uuid)
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

        print("Push add Playlist")
    }
}
