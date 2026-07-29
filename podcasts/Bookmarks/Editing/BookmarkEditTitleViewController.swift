import Foundation
import PocketCastsDataModel

class BookmarkEditTitleViewController: ThemedHostingController<BookmarkEditTitleView> {
    private let viewModel: BookmarkEditViewModel
    let onDismiss: ((String, Bool) -> Void)?
    var onEditTranscript: (() -> Void)?
    var editSaved: Bool = false

    var source: BookmarkAnalyticsSource = .unknown {
        didSet {
            viewModel.analyticsSource = source
        }
    }

    init(manager: BookmarkManager,
         bookmark: Bookmark,
         state: BookmarkEditViewModel.EditState,
         transcriptText: String? = nil,
         onDismiss: ((String, Bool) -> Void)? = nil) {
        let viewModel = BookmarkEditViewModel(manager: manager, bookmark: bookmark, state: state, transcriptText: transcriptText)
        self.viewModel = viewModel
        self.onDismiss = onDismiss

        let theme = BookmarkEditTheme(episode: manager.episode(for: bookmark))
        super.init(rootView: .init(viewModel: viewModel, theme: theme))

        viewModel.router = self
        viewModel.onEditTranscript = { [weak self] in
            self?.onEditTranscript?()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Analytics.track(.bookmarkEditFormShown, properties: ["source": source.rawValue])
        viewModel.viewDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !editSaved {
            Analytics.track(.bookmarkEditFormDismissed, properties: ["source": source.rawValue])
        }
    }

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BookmarkEditTitleViewController: BookmarkEditRouter {
    func dismiss() {
        dismiss(animated: true)
        onDismiss?(viewModel.originalTitle, true)
    }

    func titleUpdated(title: String) {
        editSaved = true
        Analytics.track(.bookmarkEditFormSubmitted, properties: ["source": source.rawValue])
        dismiss(animated: true)
        onDismiss?(title, false)
    }
}
