import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftUI

class BookmarkEditTitleViewController: ThemedHostingController<AnyView> {
    private let viewModel: any BookmarkEditing
    let onDismiss: ((String, Bool) -> Void)?
    var editSaved: Bool = false

    private var didReportDismiss = false

    var source: BookmarkAnalyticsSource = .unknown {
        didSet {
            viewModel.analyticsSource = source
        }
    }

    init(manager: BookmarkManager,
         bookmark: Bookmark,
         state: BookmarkEditViewModel.EditState,
         style: BookmarkEditTheme.Style = .player,
         onDismiss: ((String, Bool) -> Void)? = nil) {
        let episode = manager.episode(for: bookmark)

        let viewModel: any BookmarkEditing
        let rootView: AnyView

        if FeatureFlag.smartBookmarks.enabled {
            let theme = BookmarkEditTheme(episode: episode, style: style)
            let smartViewModel = BookmarkEditViewModel(manager: manager, bookmark: bookmark, state: state)
            viewModel = smartViewModel
            rootView = AnyView(BookmarkEditView(viewModel: smartViewModel, theme: theme))
        } else {
            let theme = BookmarkEditTheme(episode: episode)
            let titleViewModel = BookmarkEditTitleViewModel(manager: manager, bookmark: bookmark, state: .init(state))
            viewModel = titleViewModel
            rootView = AnyView(BookmarkEditTitleView(viewModel: titleViewModel, theme: theme))
        }

        self.viewModel = viewModel
        self.onDismiss = onDismiss

        super.init(rootView: rootView)

        viewModel.router = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        presentationController?.delegate = self
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
        reportDismiss(title: viewModel.originalTitle, canceled: true)
    }

    func titleUpdated(title: String) {
        editSaved = true
        Analytics.track(.bookmarkEditFormSubmitted, properties: ["source": source.rawValue])
        dismiss(animated: true)
        reportDismiss(title: title, canceled: false)
    }

    private func reportDismiss(title: String, canceled: Bool) {
        guard !didReportDismiss else { return }

        didReportDismiss = true
        onDismiss?(title, canceled)
    }
}

extension BookmarkEditTitleViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        viewModel.cancel()
    }
}
