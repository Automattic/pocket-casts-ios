import Combine
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

    /// Where the passage started out, so re-selecting one can be told apart from leaving it alone
    private var capturedPassageRange: NSRange?

    /// Where the passage stood when the editor was last opened, so dismissing it reports
    /// only what that visit changed
    private var passageRangeAtEditorOpen: NSRange?

    /// Whether the user picked a different passage than the one captured for them
    private var didChangePassage: Bool {
        guard let capturedPassageRange, let snippet else { return false }
        return snippet.range != capturedPassageRange
    }

    /// Fires when the title is replaced programmatically so the field can re-select it
    let didApplySuggestion = PassthroughSubject<Void, Never>()

    /// The captured transcript passage, re-selectable while editing. It's persisted to the
    /// bookmark only on save, so dismissing without saving leaves the stored passage intact.
    @Published private(set) var snippet: BookmarkTranscriptSnippet?

    /// Whether the transcript is still being fetched, so the passage can be shown as a
    /// placeholder rather than appearing out of nowhere
    @Published private(set) var isCapturingTranscript = false

    var passage: String? {
        snippet?.text ?? bookmark.passage
    }

    /// The bookmark's position on the transcript's reference timeline. The stored value
    /// covers bookmarks opened for editing; a snippet freshly captured for a new bookmark
    /// carries the resolved time before it's saved.
    var referenceTime: TimeInterval? {
        bookmark.referenceTime ?? snippet?.referenceTime
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

    /// Taken at init because generating a title starts there, so a source assigned afterwards
    /// would arrive too late for the events the generation reports
    var analyticsSource: BookmarkAnalyticsSource

    init(manager: BookmarkManager, bookmark: Bookmark, state: EditState, source: BookmarkAnalyticsSource = .unknown) {
        self.bookmarkManager = manager
        self.bookmark = bookmark
        self.originalTitle = bookmark.title
        self.title = bookmark.title
        self.editState = state
        self.analyticsSource = source

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
            self?.capturedPassageRange = snippet.range
        }
    }

    // MARK: - Title Suggestion

    private func generateTitleSuggestion() {
        guard editState == .adding, BookmarkManager.isTitleSuggestionEnabled,
              let episode = bookmarkManager.episode(for: bookmark) else { return }

        titleSuggestion = .generating
        isCapturingTranscript = true
        suggestionTask = Task { [weak self, bookmarkManager, bookmark, maxTitleLength, analyticsSource] in
            let snippet = await bookmarkManager.transcriptSnippet(for: bookmark, episode: episode)
            guard !Task.isCancelled else { return }

            self?.snippet = snippet
            self?.capturedPassageRange = snippet?.range
            self?.isCapturingTranscript = false

            guard let snippet else {
                self?.titleSuggestion = .none
                return
            }

            let attempt = await bookmarkManager.suggestTitle(from: snippet.text, for: bookmark, episode: episode, trigger: .editSheet, source: analyticsSource)
            guard !Task.isCancelled, let self else { return }

            let trimmed = attempt.map { String($0.title.trim().prefix(maxTitleLength)) }
            guard let attempt, let trimmed, !trimmed.isEmpty else {
                self.titleSuggestion = .none
                return
            }

            BookmarkGenerationAnalytics.titleGenerated(attempt, bookmark: bookmark, trigger: .editSheet, source: analyticsSource)

            if self.isTitleUnchanged {
                self.applySuggestion(trimmed)
            } else {
                // Never replace the user's own words — offer the suggestion instead
                self.titleSuggestion = .available(trimmed)
            }
        }
    }

    /// Called when the user taps the suggestion, as well as when it lands on a title they
    /// haven't touched and replaces it outright.
    func applySuggestion(_ suggestion: String) {
        title = suggestion
        titleSuggestion = .none
        didApplySuggestion.send()
    }

    /// The user tapped the offered suggestion rather than it being applied for them.
    func suggestionTapped(_ suggestion: String) {
        BookmarkGenerationAnalytics.suggestionTapped(bookmark: bookmark, source: analyticsSource)
        applySuggestion(suggestion)
    }

    // MARK: - Passage Editor

    func passageEditorShown() {
        passageRangeAtEditorOpen = snippet?.range
        BookmarkGenerationAnalytics.passageEditorShown(bookmark: bookmark, source: analyticsSource)
    }

    func passageEditorDismissed() {
        let didChange: Bool
        if let passageRangeAtEditorOpen, let snippet {
            didChange = snippet.range != passageRangeAtEditorOpen
        } else {
            didChange = false
        }

        BookmarkGenerationAnalytics.passageEditorDismissed(bookmark: bookmark,
                                                           source: analyticsSource,
                                                           passage: passage ?? "",
                                                           didChange: didChange)
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
            let parameters = BookmarkUpdateParameters(title: title.isEmpty ? placeholder : title, passage: passage, referenceTime: snippet?.referenceTime)

            await bookmarkManager.update(parameters, for: bookmark)

            if editState == .updating {
                Analytics.track(.bookmarkUpdateTitle, source: analyticsSource)
            }

            await MainActor.run {
                router?.titleUpdated(title: title)
            }
        }
    }

    // MARK: - Analytics

    /// What the edit form events report on top of the source every bookmark form sends.
    ///
    /// The set differs by stage: nothing about the title is settled when the form opens, and
    /// the passage only matters once something has been saved.
    func analyticsProperties(for stage: BookmarkEditStage) -> [String: Sendable] {
        var properties: [String: Sendable] = ["is_new_bookmark": editState == .adding]

        switch stage {
        case .shown, .dismissed:
            break
        case .submitted:
            properties["has_passage"] = passage?.isEmpty == false
            properties["passage_changed"] = didChangePassage
        }

        properties["episode_uuid"] = bookmark.episodeUuid
        if let podcastUuid = bookmark.podcastUuid {
            properties["podcast_uuid"] = podcastUuid
        }
        return properties
    }
}
