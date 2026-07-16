import Combine
import Foundation
import PocketCastsDataModel

protocol BookmarkEditRouter: AnyObject {
    func titleUpdated(title: String)
    func dismiss()
}

class BookmarkEditViewModel: ObservableObject {
    weak var router: BookmarkEditRouter?

    let editState: EditState
    let maxTitleLength = Constants.Values.bookmarkMaxTitleLength
    let originalTitle: String

    /// Localized Strings
    let headerTitle: String
    let headerSubTitle: String
    let saveButtonTitle: String
    let placeholder: String = L10n.bookmarkDefaultTitle

    @Published var didAppear = false

    /// A title suggestion generated from the transcript around the bookmark's position
    @Published private(set) var titleSuggestion: TitleSuggestion = .none

    /// Emits a generated title that should directly replace the field's text,
    /// because the user hasn't edited it yet.
    let autoApplySuggestion = PassthroughSubject<String, Never>()

    private let bookmarkManager: BookmarkManager
    private let bookmark: Bookmark

    private var suggestionTask: Task<Void, Never>?
    private var userHasEditedTitle = false

    var analyticsSource: BookmarkAnalyticsSource = .unknown

    init(manager: BookmarkManager, bookmark: Bookmark, state: EditState) {
        self.bookmarkManager = manager
        self.bookmark = bookmark
        self.originalTitle = bookmark.title
        self.editState = state

        switch editState {
        case .adding:
            headerTitle = L10n.addBookmark
            headerSubTitle = L10n.addBookmarkSubtitle
            saveButtonTitle = L10n.saveBookmark
        case .updating:
            headerTitle = L10n.changeBookmarkTitle
            headerSubTitle = L10n.changeBookmarkSubtitle
            saveButtonTitle = L10n.changeBookmarkTitle
        }

        generateTitleSuggestion()
    }

    deinit {
        suggestionTask?.cancel()
    }

    func viewDidAppear() {
        didAppear = true
    }

    // MARK: - Title Suggestion

    /// Kicks off generating a title suggestion for a newly created bookmark
    /// from the transcript text around its position. Fails silently — the
    /// suggestion simply never appears.
    private func generateTitleSuggestion() {
        guard editState == .adding, BookmarkManager.isTitleSuggestionEnabled else { return }

        titleSuggestion = .generating
        suggestionTask = Task { [weak self, bookmarkManager, bookmark, maxTitleLength] in
            let suggestion = await bookmarkManager.suggestTitle(for: bookmark)
            guard !Task.isCancelled else { return }

            let trimmed = suggestion.map { String($0.trim().prefix(maxTitleLength)) }
            await MainActor.run {
                guard let self else { return }
                guard let trimmed, !trimmed.isEmpty else {
                    self.titleSuggestion = .none
                    return
                }

                if self.userHasEditedTitle {
                    // Never replace the user's own words — offer the
                    // suggestion below the field instead.
                    self.titleSuggestion = .available(trimmed)
                } else {
                    self.titleSuggestion = .none
                    self.autoApplySuggestion.send(trimmed)
                }
            }
        }
    }

    /// The view calls this when the user changes the title themselves, so an
    /// arriving suggestion is offered rather than applied.
    func userDidEditTitle() {
        userHasEditedTitle = true
    }

    /// The view calls this once it has consumed the current suggestion
    /// (applied it to the title field).
    func suggestionHandled() {
        titleSuggestion = .none
    }

    enum TitleSuggestion: Equatable {
        /// Nothing to show: suggestions are disabled, generation failed, or the suggestion was consumed
        case none

        /// A suggestion is being generated
        case generating

        /// A suggestion is ready and waiting for the user to accept it
        case available(String)
    }

    // MARK: - View Methods

    func cancel() {
        suggestionTask?.cancel()
        router?.dismiss()
    }

    func save(title: String) {
        suggestionTask?.cancel()
        Task {
            let title = String(title.trim().prefix(maxTitleLength))

            await bookmarkManager.update(title: title.isEmpty ? placeholder : title, for: bookmark)

            if editState == .updating {
                Analytics.track(.bookmarkUpdateTitle, source: analyticsSource)
            }

            await MainActor.run {
                router?.titleUpdated(title: title)
            }
        }
    }

    enum EditState {
        case adding, updating
    }
}
