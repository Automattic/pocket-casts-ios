import SafariServices
import UIKit

protocol WhatsNewLinkDelegate: AnyObject {
    func closeWhatsNew()
}

class WhatsNewLinkButton: ThemeableRoundedButton {
    var url: URL?
    var navigationKey: String?
    weak var delegate: WhatsNewLinkDelegate?
    required init(url: URL) {
        self.url = url

        super.init(frame: .zero)
        addTarget(self, action: #selector(openLink), for: .touchUpInside)
    }

    required init(navigationKey: String) {
        self.navigationKey = navigationKey

        super.init(frame: .zero)
        addTarget(self, action: #selector(navigateTo), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func openLink() {
        guard let url else { return }

        NavigationManager.shared.navigateTo(NavigationManager.openUrlInSafariVCKey, data: [NavigationManager.safariVCUrlKey: url.absoluteString])
    }

    @objc private func navigateTo() {
        guard let navigationKey else { return }
        delegate?.closeWhatsNew()
        NavigationManager.shared.navigateTo(navigationKey, data: nil)
    }
}
