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
        setupNavBar()
    }

    @objc override func themeDidChange() {
        super.themeDidChange()
        setupNavBar()
    }

    /// Puts a translucent bar over the message rather than the app's usual opaque one, so a page
    /// scrolls up underneath it instead of stopping at its edge. Liquid Glass already does this.
    private func setupNavBar() {
        guard !LiquidGlass.isEnabled else { return }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.shadowColor = nil
        appearance.titleTextAttributes = [.foregroundColor: AppTheme.navBarTitleColor()]

        navigationItem.standardAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
    }
}
