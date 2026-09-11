import Combine
import PocketCastsServer
import SwiftUI

/// Hosts `WhatsNewFeedView` and owns the navigation bar the design puts around it.
class WhatsNewFeedViewController: PCHostingController<WhatsNewFeedView> {
    private let viewModel: WhatsNewFeedViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: WhatsNewFeedViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WhatsNewFeedView(viewModel: viewModel), background: \.primaryUi02)
    }

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.whatsNew
        navigationItem.largeTitleDisplayMode = .never

        Analytics.track(.whatsNewFeedShown)

        viewModel.onSelect = { [weak self] message in
            self?.show(message)
        }

        viewModel.$items
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateReadAllButton()
            }
            .store(in: &cancellables)
    }

    private func show(_ message: WhatsNewMessage) {
        let controller = WhatsNewMessageViewController(message: message,
                                                       hasResponded: viewModel.hasResponded(to: message)) { [weak self] poll, _ in
            self?.viewModel.markAsResponded(to: poll)
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func updateReadAllButton() {
        guard viewModel.hasUnreadItems else {
            navigationItem.rightBarButtonItem = nil
            return
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: L10n.whatsNewFeedReadAll,
            primaryAction: UIAction { [weak self] _ in
                Analytics.track(.whatsNewReadAllTapped)
                self?.viewModel.markAllAsRead()
            }
        )
    }
}
