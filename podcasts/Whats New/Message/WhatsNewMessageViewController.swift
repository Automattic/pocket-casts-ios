import PocketCastsServer
import SwiftUI

/// Hosts `WhatsNewMessageView` and owns the navigation bar the design puts around it.
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
