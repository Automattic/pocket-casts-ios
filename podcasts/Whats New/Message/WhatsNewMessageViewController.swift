import PocketCastsServer
import SwiftUI

/// Hosts `WhatsNewMessageView` under the app's usual navigation bar.
class WhatsNewMessageViewController: PCHostingController<WhatsNewMessageView> {
    private let viewModel: WhatsNewMessageViewModel

    init(message: WhatsNewMessage) {
        viewModel = WhatsNewMessageViewModel(message: message)
        super.init(rootView: WhatsNewMessageView(viewModel: viewModel), background: \.primaryUi01)
    }

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .never
    }
}
