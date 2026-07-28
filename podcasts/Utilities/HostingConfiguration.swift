import UIKit
import SwiftUI

struct HostingConfiguration<Content: View>: UIContentConfiguration {
    fileprivate let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeContentView() -> any UIView & UIContentView {
        HostingView(configuration: self)
    }

    func updated(for state: any UIConfigurationState) -> HostingConfiguration {
        self
    }
}

fileprivate final class HostingView<Content: View>: UIView, UIContentView {
    private let hostingController: UIHostingController<Content>
    private var _configuration: HostingConfiguration<Content>

    var configuration: any UIContentConfiguration {
        get {
            _configuration
        }
        set {
            guard let newConfig = newValue as? HostingConfiguration<Content> else {
                assertionFailure("Invalid configuration type")
                return
            }
            _configuration = newConfig
            hostingController.rootView = newConfig.content
        }
    }

    init(configuration: HostingConfiguration<Content>) {
        self._configuration = configuration
        self.hostingController = UIHostingController(rootView: configuration.content)
        super.init(frame: .zero)

        let hostedView: UIView = hostingController.view
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        hostedView.backgroundColor = .clear
        addSubview(hostedView)
        hostedView.backgroundColor = .clear
        hostedView.anchorToAllSidesOf(view: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
