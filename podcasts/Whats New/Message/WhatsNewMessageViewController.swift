import PocketCastsServer
import SwiftUI

/// Hosts `WhatsNewMessageView` under the app's usual navigation bar.
class WhatsNewMessageViewController: PCHostingController<WhatsNewMessageView> {
    private let viewModel: WhatsNewMessageViewModel

    /// - Parameters:
    ///   - hasResponded: Whether the account has already answered the message's poll, if it asks one.
    ///   - onRespond: Called with the option the user answered the poll with.
    init(message: WhatsNewMessage,
         hasResponded: Bool = false,
         onRespond: ((WhatsNewPoll, WhatsNewPoll.Option) -> Void)? = nil) {
        let viewModel = WhatsNewMessageViewModel(message: message, hasResponded: hasResponded)
        viewModel.onRespond = onRespond
        self.viewModel = viewModel
        super.init(rootView: WhatsNewMessageView(viewModel: viewModel), background: \.primaryUi01)
    }

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.navigationTitle
        navigationItem.largeTitleDisplayMode = .never
    }
}
