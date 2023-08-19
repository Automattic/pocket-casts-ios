import Foundation
import PocketCastsDataModel

class BookmarkEditTitleViewController: ThemedHostingController<BookmarkEditTitleView> {
    private let viewModel: BookmarkEditViewModel
    let onDismiss: ((String) -> Void)?

    var source: BookmarkAnalyticsSource? = nil {
        didSet {
            viewModel.analyticsSource = source
        }
    }

    init(manager: BookmarkManager,
         bookmark: Bookmark,
         state: BookmarkEditViewModel.EditState,
         onDismiss: ((String) -> Void)? = nil) {
        let viewModel = BookmarkEditViewModel(manager: manager, bookmark: bookmark, state: state)
        self.viewModel = viewModel
        self.onDismiss = onDismiss

        super.init(rootView: .init(viewModel: viewModel))

        viewModel.router = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.viewDidAppear()
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BookmarkEditTitleViewController: BookmarkEditRouter {
    func dismiss() {
        dismiss(animated: true)
        onDismiss?(viewModel.originalTitle)
    }

    func titleUpdated(title: String) {
        dismiss(animated: true)
        onDismiss?(title)
    }
}
