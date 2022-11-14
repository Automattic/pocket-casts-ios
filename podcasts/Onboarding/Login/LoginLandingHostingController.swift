import Foundation
import SwiftUI

class LoginLandingHostingController<Content>: UIHostingController<Content> where Content: View {
    let coordinator: LoginCoordinator

    init(rootView: Content, coordinator: LoginCoordinator) {
        self.coordinator = coordinator
        super.init(rootView: rootView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let imageView = ThemeableImageView(frame: .zero)
        imageView.imageNameFunc = AppTheme.pcLogoSmallHorizontalForBackgroundImageName
        imageView.accessibilityLabel = L10n.setupAccount
        navigationItem.titleView = imageView

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Not Now", style: .plain, target: coordinator, action: #selector(LoginCoordinator.dismissTapped))
    }
}
