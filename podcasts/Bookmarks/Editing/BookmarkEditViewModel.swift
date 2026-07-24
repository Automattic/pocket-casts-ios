import Foundation
import PocketCastsDataModel

@MainActor
class BookmarkEditViewModel: ObservableObject {
    weak var router: BookmarkEditRouter?

    let editState: EditState
    let maxTitleLength = Constants.Values.bookmarkMaxTitleLength
    let originalTitle: String

    /// Localized Strings
    let headerTitle: String
    let saveButtonTitle: String
    let placeholder: String = L10n.bookmarkDefaultTitle

    /// The title being edited, kept within `maxTitleLength`
    @Published var title: String {
        didSet {
            guard title != oldValue else { return }

            let trimmed = String(title.prefix(maxTitleLength))
            if trimmed != title {
                title = trimmed
            }

            if titleSuggestion == .generating {
                titleSuggestion = .none
            }
        }
    }

    /// Whether the title still is the one the bookmark was created with
    private var isTitleUnchanged: Bool {
        title == originalTitle
    }

    /// A title suggestion generated from the transcript around the bookmark's position
    @Published private(set) var titleSuggestion: TitleSuggestion = .none

    /// The captured transcript passage, re-selectable while editing. It's persisted to the
    /// bookmark only on save, so dismissing without saving leaves the stored passage intact.
    @Published private(set) var snippet: BookmarkTranscriptSnippet?

    /// Whether the transcript is still being fetched, so the passage can be shown as a
    /// placeholder rather than appearing out of nowhere
    @Published private(set) var isCapturingTranscript = false

    var passage: String? {
        snippet?.text ?? bookmark.passage
    }

    /// The captured passage, which the transcript editor changes as the user picks a
    /// different one. It deliberately doesn't regenerate the title, which belongs to the
    /// moment that was bookmarked.
    var transcriptRange: NSRange {
        get { snippet?.range ?? NSRange(location: 0, length: 0) }
        set { snippet?.range = newValue }
    }

    private let bookmarkManager: BookmarkManager
    private let bookmark: Bookmark

    private var suggestionTask: Task<Void, Never>?

    var analyticsSource: BookmarkAnalyticsSource = .unknown

    init(manager: BookmarkManager, bookmark: Bookmark, state: EditState) {
        self.bookmarkManager = manager
        self.bookmark = bookmark
        self.originalTitle = bookmark.title
        self.title = bookmark.title
        self.editState = state

        switch editState {
        case .adding:
            headerTitle = L10n.addBookmark
            saveButtonTitle = L10n.saveBookmark
            generateTitleSuggestion()
        case .updating:
            headerTitle = L10n.editBookmark
            saveButtonTitle = L10n.saveBookmark
            loadCapturedPassage()
        }
    }

    deinit {
        suggestionTask?.cancel()
    }

    private func loadCapturedPassage() {
        guard BookmarkManager.isTitleSuggestionEnabled,
              bookmark.passage?.isEmpty == false,
              let episode = bookmarkManager.episode(for: bookmark) else { return }

        suggestionTask = Task { [weak self, bookmarkManager, bookmark] in
            let snippet = await bookmarkManager.capturedSnippet(for: bookmark, episode: episode)
            guard !Task.isCancelled, let snippet else { return }

            self?.snippet = snippet
        }
    }

    // MARK: - Title Suggestion

    private func generateTitleSuggestion() {
        guard editState == .adding, BookmarkManager.isTitleSuggestionEnabled,
              let episode = bookmarkManager.episode(for: bookmark) else { return }

        titleSuggestion = .generating
        isCapturingTranscript = true
        suggestionTask = Task { [weak self, bookmarkManager, bookmark, maxTitleLength] in
            let snippet = await bookmarkManager.transcriptSnippet(for: bookmark, episode: episode)
            guard !Task.isCancelled else { return }

            self?.snippet = snippet
            self?.isCapturingTranscript = false

            guard let snippet else {
                self?.titleSuggestion = .none
                return
            }

            let suggestion = await bookmarkManager.suggestTitle(from: snippet.text, for: bookmark, episode: episode)
            guard !Task.isCancelled, let self else { return }

            let trimmed = suggestion.map { String($0.trim().prefix(maxTitleLength)) }
            guard let trimmed, !trimmed.isEmpty else {
                self.titleSuggestion = .none
                return
            }

            if self.isTitleUnchanged {
                self.applySuggestion(trimmed)
            } else {
                // Never replace the user's own words — offer the suggestion instead
                self.titleSuggestion = .available(trimmed)
            }
        }
    }

    func applySuggestion(_ suggestion: String) {
        title = suggestion
        titleSuggestion = .none
    }

    enum TitleSuggestion: Equatable {
        case none
        case generating
        case available(String)
    }

    enum EditState {
        case adding, updating
    }

    // MARK: - View Methods

    func cancel() {
        suggestionTask?.cancel()
        router?.dismiss()
    }

    func save() {
        suggestionTask?.cancel()
        Task {
            let title = String(title.trim().prefix(maxTitleLength))
            let passage = snippet.map { BookmarkUpdateParameters.Passage(text: $0.text, location: $0.range.location) }

            await bookmarkManager.update(.init(title: title.isEmpty ? placeholder : title, passage: passage), for: bookmark)

            if editState == .updating {
                Analytics.track(.bookmarkUpdateTitle, source: analyticsSource)
            }

            await MainActor.run {
                router?.titleUpdated(title: title)
            }
        }
    }
}
