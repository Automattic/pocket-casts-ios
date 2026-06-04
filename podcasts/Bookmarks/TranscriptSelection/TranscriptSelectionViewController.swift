import Foundation
import PocketCastsDataModel

class TranscriptSelectionViewController: ThemedHostingController<TranscriptSelectionView> {
    private let viewModel: TranscriptSelectionViewModel
    let onDismiss: ((String, Bool) -> Void)?

    var source: BookmarkAnalyticsSource = .unknown

    init(viewModel: TranscriptSelectionViewModel,
         episode: BaseEpisode?,
         onDismiss: ((String, Bool) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss

        let theme = TranscriptSelectionTheme(episode: episode)
        super.init(rootView: .init(viewModel: viewModel, theme: theme))

        modalPresentationStyle = .overFullScreen
        viewModel.router = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.track(.bookmarkEditFormShown, properties: ["source": source.rawValue, "smart_bookmark": true])
    }

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TranscriptSelectionViewController: TranscriptSelectionRouter {
    func selectionSaved(title: String) {
        Analytics.track(.bookmarkEditFormSubmitted, properties: ["source": source.rawValue, "smart_bookmark": true])
        dismiss(animated: true)
        onDismiss?(title, false)
    }

    func selectionDismissed() {
        Analytics.track(.bookmarkEditFormDismissed, properties: ["source": source.rawValue, "smart_bookmark": true])
        dismiss(animated: true)
        onDismiss?(viewModel.bookmark.title, true)
    }
}
