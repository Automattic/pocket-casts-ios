import Foundation
import Combine
import PocketCastsDataModel
import PocketCastsUtils

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
        guard UIApplication.shared.applicationState == .active, !CarPlayHelper.isConnectedToCarPlay else {
            return
        }

        showBookmarkEdit(isNew: !isDuplicate, bookmark: bookmark)
    }

    private func showBookmarkEdit(isNew: Bool, bookmark: Bookmark) {
        if isNew, FeatureFlag.smartBookmarks.enabled, let episode = viewModel.episode as? Episode {
            showSmartBookmarkIfAvailable(bookmark: bookmark, episode: episode) { [weak self] shown in
                if !shown {
                    self?.showBookmarkTitleEdit(isNew: isNew, bookmark: bookmark)
                }
            }
            return
        }

        showBookmarkTitleEdit(isNew: isNew, bookmark: bookmark)
    }

    private func showBookmarkTitleEdit(isNew: Bool, bookmark: Bookmark, prefilledTitle: String? = nil, transcriptText: String? = nil, transcriptContext: TranscriptEditContext? = nil) {
        var editBookmark = bookmark
        if let prefilledTitle {
            editBookmark = Bookmark(uuid: bookmark.uuid, title: prefilledTitle, time: bookmark.time, created: bookmark.created, episodeUuid: bookmark.episodeUuid, podcastUuid: bookmark.podcastUuid)
        }

        let controller = BookmarkEditTitleViewController(manager: bookmarkManager, bookmark: editBookmark, state: isNew ? .adding : .updating, transcriptText: transcriptText, onDismiss: { [weak self] title, canceled in
            self?.handleEditDismissed(bookmark: bookmark, isNew: isNew, title: title, canceled: canceled)
        })

        controller.source = viewModel.analyticsSource

        if let transcriptContext {
            controller.onEditTranscript = { [weak self] in
                self?.presentTranscriptEditor(bookmark: bookmark, context: transcriptContext, from: controller)
            }
        }

        let presenter = presentedViewController ?? self
        presenter.present(controller, animated: true)
    }

    private func showSmartBookmarkIfAvailable(bookmark: Bookmark, episode: Episode, completion: @escaping (Bool) -> Void) {
        let transcriptManager = TranscriptManager(episodeUUID: episode.uuid, podcastUUID: episode.podcastUuid)

        Task {
            do {
                let transcript = try await transcriptManager.loadTranscript()
                let cues = transcript.cues
                let fullText = transcript.attributedText.string
                guard !cues.isEmpty else {
                    await MainActor.run { completion(false) }
                    return
                }

                guard let selection = TranscriptSelectionLogic.selectTranscript(
                    around: bookmark.time,
                    cues: cues,
                    fullText: fullText
                ) else {
                    await MainActor.run { completion(false) }
                    return
                }

                let title = await BookmarkTitleGenerator.generateTitle(from: selection.text)

                await bookmarkManager.update(title: title, for: bookmark)
                await bookmarkManager.updateTranscript(
                    text: selection.text,
                    startTime: selection.startTime,
                    endTime: selection.endTime,
                    for: bookmark
                )

                let context = TranscriptEditContext(cues: cues, fullText: fullText, episode: episode)

                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.showBookmarkTitleEdit(isNew: true, bookmark: bookmark, prefilledTitle: title, transcriptText: selection.text, transcriptContext: context)
                    completion(true)
                }
            } catch {
                await MainActor.run { completion(false) }
            }
        }
    }

    func handleEditDismissed(bookmark: Bookmark, isNew: Bool, title: String, canceled: Bool) {
        guard isNew else { return }

        if canceled {
            Task {
                let _ = await bookmarkManager.remove([bookmark])
                viewModel.reload()
            }
            return
        }
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

    // MARK: - Transcript Editing

    private func presentTranscriptEditor(bookmark: Bookmark, context: TranscriptEditContext, from presenter: UIViewController) {
        let latestBookmark = bookmarkManager.bookmark(for: bookmark.uuid) ?? bookmark
        let selectionVM = TranscriptSelectionViewModel(
            bookmark: latestBookmark,
            cues: context.cues,
            fullText: context.fullText,
            bookmarkManager: bookmarkManager,
            existingTitle: latestBookmark.title
        )

        let selectionVC = TranscriptSelectionViewController(
            viewModel: selectionVM,
            episode: context.episode,
            onDismiss: { [weak presenter] _, canceled in
                // After transcript editor is dismissed, dismiss the title sheet too
                if !canceled {
                    presenter?.dismiss(animated: true)
                }
            }
        )
        selectionVC.source = viewModel.analyticsSource

        presenter.present(selectionVC, animated: true)
    }

    // MARK: - Coder....
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Transcript Edit Context

/// Holds transcript data needed to open the transcript editor from the title sheet
struct TranscriptEditContext {
    let cues: [TranscriptCue]
    let fullText: String
    let episode: Episode
}

// MARK: - BookmarkListRouter

extension BookmarksPlayerTabController: BookmarkListRouter {
    func bookmarkPlay(_ bookmark: Bookmark) {
        playbackManager.playBookmark(bookmark, source: .player)
    }

    func bookmarkEdit(_ bookmark: Bookmark) {
        showBookmarkEdit(isNew: false, bookmark: bookmark)
    }

    func bookmarkDetail(_ bookmark: Bookmark) {
        let detailView = BookmarkDetailView(
            bookmark: bookmark,
            episode: bookmark.episode ?? viewModel.episode,
            onPlay: { [weak self] in
                self?.playbackManager.playBookmark(bookmark, source: .player)
            },
            onEdit: { [weak self] done in
                guard let self else { return }
                presentBookmarkEditor(bookmark: bookmark, bookmarkManager: bookmarkManager, analyticsSource: viewModel.analyticsSource) { [weak self] in
                    self?.viewModel.reload()
                    done()
                }
            },
            onShare: (bookmark.episode ?? viewModel.episode) is Episode ? { [weak self] in
                self?.bookmarkShare(bookmark)
            } : nil,
            isModal: true,
            bookmarkLookup: { [weak self] uuid in
                self?.bookmarkManager.bookmark(for: uuid)
            }
        )

        let hostingController = ThemedHostingController(rootView: detailView)
        let nav = UINavigationController(rootViewController: hostingController)
        present(nav, animated: true)
    }

    func bookmarkShare(_ bookmark: Bookmark) {
        guard let episode = viewModel.episode as? Episode else {
            return
        }
        Analytics.track(.bookmarkShareTapped, source: viewModel.analyticsSource, properties: ["podcast_uuid": episode.podcastUuid, "episode_uuid": bookmark.episodeUuid])
        SharingModal.show(option: .bookmark(episode, bookmark.time), from: .player, in: self)
    }
}
