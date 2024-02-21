import Foundation
import Combine
import PocketCastsDataModel

/// Wraps the SwiftUI view in a `PlayerItemViewController` and adds some basic listeners
class BookmarksPlayerTabController: PlayerItemViewController {
    private let playbackManager: PlaybackManager
    private let bookmarkManager: BookmarkManager
    private let viewModel: BookmarkEpisodeListViewModel
    private let controller: ThemedHostingController<BookmarksPlayerTab>

    private var cancellables = Set<AnyCancellable>()

    init(bookmarkManager: BookmarkManager, playbackManager: PlaybackManager) {
        let viewModel = BookmarkEpisodeListViewModel(bookmarkManager: bookmarkManager, sortOption: Settings.playerBookmarksSort)
        viewModel.analyticsSource = .player

        self.playbackManager = playbackManager
        self.bookmarkManager = bookmarkManager
        self.viewModel = viewModel
        self.controller = ThemedHostingController(rootView: BookmarksPlayerTab(viewModel: viewModel))
        super.init(nibName: nil, bundle: nil)

        viewModel.router = self
    }

    override func loadView() {
        self.view = controller.view.map {
            let view = UIStackView(arrangedSubviews: [$0])
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .clear
            return view
        } ?? UIView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(controller)
    }

    // MARK: - Player Events

    override func willBeAddedToPlayer() {
        updateCurrentEpisode()

        // Listen when the track changes and update the view model with the current episode
        Constants.Notifications.playbackTrackChanged.publisher().sink { [weak self] _ in
            self?.updateCurrentEpisode()
        }.store(in: &cancellables)

        bookmarkManager.onBookmarkCreated
            .receive(on: RunLoop.main)
            .filter { [weak self] event in
                self?.viewModel.episode?.uuid == event.episode
            }
            .map { [weak self] event in
                (event.isDuplicate, self?.bookmarkManager.bookmark(for: event.uuid))
            }
            .sink { [weak self] info in
                guard let bookmark = info.1 else { return }

                self?.handleBookmarkCreated(bookmark: bookmark, isDuplicate: info.0)
            }
            .store(in: &cancellables)
    }

    override func willBeRemovedFromPlayer() {
        viewModel.episode = nil
    }

    // MARK: - Notification Handlers

    private func updateCurrentEpisode() {
        viewModel.episode = playbackManager.currentEpisode()
    }

    private func handleBookmarkCreated(bookmark: Bookmark, isDuplicate: Bool) {
        // Prevent the add bookmark window from opening if the app isn't active
        // We also prevent it from opening while connected to CarPlay to not distract anyone, and in my testing the app state is always
        // true while connected to CarPlay, even if it's in the background
        guard UIApplication.shared.applicationState == .active, !SceneHelper.isConnectedToCarPlay else {
            return
        }

        showBookmarkEdit(isNew: !isDuplicate, bookmark: bookmark)
    }

    private func showBookmarkEdit(isNew: Bool, bookmark: Bookmark) {
        let controller = BookmarkEditTitleViewController(manager: bookmarkManager, bookmark: bookmark, state: isNew ? .adding : .updating, onDismiss: { [weak self] title in
            self?.handleEditDismissed(isNew: isNew, title: title)
        })

        controller.source = viewModel.analyticsSource

        present(controller, animated: true)
    }

    func handleEditDismissed(isNew: Bool, title: String) {
        guard isNew else { return }

        // If the title is still the default, we'll just show a 'Bookmark Added' message instead of displaying 'Bookmark "Bookmark" Added'.
        let message = title == L10n.bookmarkDefaultTitle ? L10n.bookmarkAdded : L10n.bookmarkAddedNotification(title)

        let action = Toast.Action(title: L10n.bookmarkAddedButtonTitle) { [weak self] in
            self?.showBookmarksTab()
        }

        Toast.show(message, actions: [action], theme: .playerTheme)
    }

    private func showBookmarksTab() {
        containerDelegate?.scrollToBookmarks()
    }

    // MARK: - Coder....
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - BookmarkListRouter

extension BookmarksPlayerTabController: BookmarkListRouter {
    func bookmarkPlay(_ bookmark: Bookmark) {
        playbackManager.playBookmark(bookmark, source: .player)
    }

    func bookmarkEdit(_ bookmark: Bookmark) {
        showBookmarkEdit(isNew: false, bookmark: bookmark)
    }
}
