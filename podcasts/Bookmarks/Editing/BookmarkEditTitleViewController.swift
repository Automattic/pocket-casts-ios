import Foundation
import PocketCastsDataModel

class BookmarkEditTitleViewController: ThemedHostingController<BookmarkEditTitleView> {
    private let viewModel: BookmarkEditViewModel

    init(manager: BookmarkManager, bookmark: Bookmark, state: BookmarkEditViewModel.EditState) {
        let viewModel = BookmarkEditViewModel(manager: manager, bookmark: bookmark, state: state)
        self.viewModel = viewModel

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
    }

    func titleUpdated(title: String) {
        print("Title updated!")
        dismiss()
    }
}
