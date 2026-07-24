import PocketCastsDataModel
import SwiftUI

/// Hosts `BookmarkDetailsView` and performs the actions its navigation bar offers.
class BookmarkDetailsViewController: ThemedHostingController<BookmarkDetailsView> {
    private let bookmarkManager: BookmarkManager
    private let playbackManager: PlaybackManager
    private let analyticsSource: BookmarkAnalyticsSource
    private let viewModel: BookmarkDetailsViewModel

    init(bookmark: Bookmark,
         bookmarkManager: BookmarkManager = PlaybackManager.shared.bookmarkManager,
         playbackManager: PlaybackManager = .shared,
         source: BookmarkAnalyticsSource = .unknown) {
        self.bookmarkManager = bookmarkManager
        self.playbackManager = playbackManager
        self.analyticsSource = source

        let viewModel = BookmarkDetailsViewModel(bookmark: bookmark, bookmarkManager: bookmarkManager)
        self.viewModel = viewModel

        super.init(rootView: .init(viewModel: viewModel))

        viewModel.onPlay = { [weak self] in
            self?.play()
        }
    }

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.bookmarkDetailsTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "more"),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(moreTapped))
        navigationItem.rightBarButtonItem?.accessibilityLabel = L10n.accessibilityMoreActions
    }
}

// MARK: - Actions

private extension BookmarkDetailsViewController {
    var bookmark: Bookmark {
        viewModel.bookmark
    }

    func play() {
        Task {
            do {
                try await playbackManager.playBookmark(bookmark, source: analyticsSource)
            } catch {
                HapticsHelper.triggerErrorHaptic()
                Toast.show(L10n.discoverEpisodeFailToLoad)
            }
        }
    }

    @objc func moreTapped() {
        let optionPicker = OptionsPicker(title: nil)

        var actions: [OptionAction] = [
            .init(label: L10n.edit, icon: "folder-edit") { [weak self] in
                self?.edit()
            }
        ]

        if viewModel.episode is Episode {
            actions.append(.init(label: L10n.share, icon: "podcast-share") { [weak self] in
                self?.share()
            })
        }

        let delete = OptionAction(label: L10n.delete, icon: "delete") { [weak self] in
            self?.confirmDeletion()
        }
        delete.destructive = true
        actions.append(delete)

        optionPicker.addActions(actions)
        optionPicker.present()
    }

    func edit() {
        let controller = BookmarkEditTitleViewController(manager: bookmarkManager,
                                                         bookmark: bookmark,
                                                         state: .updating) { [weak self] _, _ in
            self?.viewModel.refresh()
        }

        controller.source = analyticsSource

        present(controller, animated: true)
    }

    func share() {
        guard let episode = viewModel.episode as? Episode else { return }

        Analytics.track(.bookmarkShareTapped, source: analyticsSource, properties: ["podcast_uuid": episode.podcastUuid, "episode_uuid": bookmark.episodeUuid])

        SharingModal.show(option: .bookmark(episode, bookmark.time), from: .bookmark, in: self)
    }

    func confirmDeletion() {
        let alert = UIAlertController(title: L10n.bookmarkDeleteWarningTitle,
                                      message: L10n.bookmarkDeleteWarningBody,
                                      preferredStyle: .alert)

        alert.addAction(.init(title: L10n.cancel, style: .cancel, handler: { [analyticsSource] _ in
            Analytics.track(.bookmarkDeleteFormDismissed, source: analyticsSource)
        }))

        alert.addAction(.init(title: L10n.delete, style: .destructive, handler: { [weak self, analyticsSource] _ in
            Analytics.track(.bookmarkDeleteFormSubmitted, source: analyticsSource)
            self?.delete()
        }))

        Analytics.track(.bookmarkDeleteFormShown, source: analyticsSource)

        present(alert, animated: true)
    }

    func delete() {
        Task {
            guard await bookmarkManager.remove([bookmark]) else { return }

            Analytics.track(.bookmarkDeleted, source: analyticsSource)

            close()
        }
    }

    /// Pushed onto a list's navigation stack, or presented over the player
    func close() {
        if let navigationController, navigationController.viewControllers.first != self {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
