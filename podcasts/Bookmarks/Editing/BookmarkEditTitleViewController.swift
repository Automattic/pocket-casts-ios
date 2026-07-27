import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftUI

class BookmarkEditTitleViewController: ThemedHostingController<AnyView> {
    private let viewModel: any BookmarkEditing
    let onDismiss: ((String, Bool) -> Void)?
    var editSaved: Bool = false

    var source: BookmarkAnalyticsSource = .unknown {
        didSet {
            viewModel.analyticsSource = source
        }
    }

    init(manager: BookmarkManager,
         bookmark: Bookmark,
         state: BookmarkEditViewModel.EditState,
         onDismiss: ((String, Bool) -> Void)? = nil) {
        let theme = BookmarkEditTheme(episode: manager.episode(for: bookmark))

        let viewModel: any BookmarkEditing
        let rootView: AnyView

        if FeatureFlag.smartBookmarks.enabled {
            let smartViewModel = BookmarkEditViewModel(manager: manager, bookmark: bookmark, state: state)
            viewModel = smartViewModel
            rootView = AnyView(BookmarkEditView(viewModel: smartViewModel, theme: theme))
        } else {
            let titleViewModel = BookmarkEditTitleViewModel(manager: manager, bookmark: bookmark, state: .init(state))
            viewModel = titleViewModel
            rootView = AnyView(BookmarkEditTitleView(viewModel: titleViewModel, theme: theme))
        }

        self.viewModel = viewModel
        self.onDismiss = onDismiss

        super.init(rootView: rootView)

        viewModel.router = self
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
