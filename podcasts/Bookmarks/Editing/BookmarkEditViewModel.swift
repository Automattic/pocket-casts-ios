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

    private let bookmarkManager: BookmarkManager
    private let bookmark: Bookmark

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
    }

    func viewDidAppear() {
        didAppear = true
    }

    // MARK: - View Methods

    func cancel() {
        router?.dismiss()
    }

    func save(title: String) {
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
