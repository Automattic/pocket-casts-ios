import Foundation

/// Which of the edit form's events is being reported, since they don't all carry the same
/// properties — see `BookmarkEditViewModel.analyticsProperties(for:)`.
enum BookmarkEditStage {
    case shown, dismissed, submitted
}

/// The parts of a bookmark edit view model the hosting controller drives, so it can
/// hold either view model while `FeatureFlag.smartBookmarks` picks between them.
@MainActor
protocol BookmarkEditing: AnyObject {
    var router: BookmarkEditRouter? { get set }
    var analyticsSource: BookmarkAnalyticsSource { get set }

    func viewDidAppear()
    func cancel()
    func analyticsProperties(for stage: BookmarkEditStage) -> [String: Sendable]
}

extension BookmarkEditing {
    /// `BookmarkEditView` focuses its field in `onAppear`, so it has nothing to do here
    func viewDidAppear() {}

    /// The form predating Smart Bookmarks has nothing to add, which also keeps the flag-off
    /// arm reporting exactly what it did before
    func analyticsProperties(for stage: BookmarkEditStage) -> [String: Sendable] { [:] }
}

extension BookmarkEditViewModel: BookmarkEditing {}

extension BookmarkEditTitleViewModel: BookmarkEditing {}

extension BookmarkEditTitleViewModel.EditState {
    init(_ state: BookmarkEditViewModel.EditState) {
        switch state {
        case .adding:
            self = .adding
        case .updating:
            self = .updating
        }
    }
}
