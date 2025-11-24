import UIKit
import SwiftUI
import PocketCastsDataModel
import PocketCastsDependencyInjection

class NewPlaylistCell: ThemeableCell {
    typealias NewPlaylistCellType = NewPlaylistCellViewModel.DisplayType

    @Dependency(\.playlistMetadataLoader) var playlistMetadataLoader: PlaylistMetadataLoader

    lazy var artworkImageSource: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    static let reuseIdentifier = "PlaylistCell"
    static let cellHeight = 81.0
    static let emptyPlaylist = EpisodeFilter()

    lazy var separatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var viewModel = NewPlaylistCellViewModel()
    private lazy var hostingController = ThemedHostingController(
        rootView: NewPlaylistCellView(viewModel: viewModel)
    )
    private var playlistCountLoadTask: Task<Void, Never>?
    private var playlistImageLoadTask: Task<Void, Never>?
    private var playlistID: String = ""

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator

        self.style = .primaryUi01
        iconStyle = .primaryIcon02

        updateColor()

        separatorView.backgroundColor = AppTheme.colorForStyle(.primaryUi05)

        separatorInset = UIEdgeInsets(top: 0, left: .greatestFiniteMagnitude, bottom: 0, right: 0)
        layoutMargins = .zero
        preservesSuperviewLayoutMargins = false

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingController.view)

        addSubview(artworkImageSource)
        addSubview(separatorView)
        bringSubviewToFront(separatorView)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32.0),

            artworkImageSource.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16.0),
            artworkImageSource.widthAnchor.constraint(equalToConstant: 56.0),
            artworkImageSource.heightAnchor.constraint(equalToConstant: 56.0),
            artworkImageSource.centerYAnchor.constraint(equalTo: centerYAnchor),

            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16.0),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1.0)
        ])
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        ensureCorrectReorderColor()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        ensureCorrectReorderColor()
    }

    private func ensureCorrectReorderColor() {
        let theme = themeOverride ?? Theme.sharedTheme.activeTheme

        overrideUserInterfaceStyle = theme.isDark ? .dark : .light
    }

    override func updateColor() {
        super.updateColor()
        separatorView.backgroundColor = AppTheme.colorForStyle(.primaryUi05)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reset() {
        viewModel.playlistName = ""
        viewModel.isSmartPlaylist = false
        viewModel.episodesCount = 0
        viewModel.images = []
        playlistCountLoadTask?.cancel()
        playlistCountLoadTask = nil
        playlistImageLoadTask?.cancel()
        playlistImageLoadTask = nil
        Task {
            await playlistMetadataLoader.cancelLoadCount(for: playlistID)
            await playlistMetadataLoader.cancelLoadImages(for: playlistID)
        }
    }

    func set(playlistName: String, isManualPlaylist: Bool) {
        viewModel.playlistName = playlistName
        viewModel.isSmartPlaylist = !isManualPlaylist
    }

    func loadMetadata(for playlist: EpisodeFilter) {
        playlistID = playlist.uuid
        playlistCountLoadTask = Task { [weak self] in
            guard let self else { return }
            let loadingPlaylist = playlistID
            let count = await self.playlistMetadataLoader.loadCount(for: playlist)
            if self.playlistID != loadingPlaylist {
                return
            }
            await MainActor.run {
                if count != self.viewModel.episodesCount {
                    self.viewModel.episodesCount = count
                }
            }
        }
        playlistImageLoadTask = Task { [weak self] in
            guard let self else { return }
            let loadingPlaylist = playlistID
            let images = await self.playlistMetadataLoader.loadImages(for: playlist)
            if self.playlistID != loadingPlaylist {
                return
            }
            await MainActor.run {
                if images != self.viewModel.images {
                    self.viewModel.images = images
                }
            }
        }
    }

    func hideSeparator(_ hide: Bool) {
        separatorView.alpha = hide ? 0 : 1
    }
}
