import Foundation

/// The parts of a bookmark edit view model the hosting controller drives, so it can
/// hold either view model while `FeatureFlag.smartBookmarks` picks between them.
protocol BookmarkEditing: AnyObject {
    var router: BookmarkEditRouter? { get set }
    var analyticsSource: BookmarkAnalyticsSource { get set }
    var originalTitle: String { get }

    func viewDidAppear()
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
