import Foundation
import SwiftUI

class InformationalModalViewModel: NSObject, OnboardingModel {
    weak var navigationController: UINavigationController? = nil

    func didAppear() {
        // Add Analytics
    }

    func didDismiss(type: OnboardingDismissType) {
        if type != .swipe {
            return
        }
        // Add Analytics
    }

    func getStarted() {
        // Add Analytics
        let controller = OnboardingFlow.shared.begin(flow: .initialOnboarding, in: navigationController)
        navigationController?.pushViewController(controller, animated: true)
    }

    func pageDidChange(_ index: Int) {
        // Add Analytics
    }

    @objc func dismissTapped() {
        navigationController?.dismiss(animated: true) { [weak self] in
            self?.didDismiss(type: .swipe)
        }
    }

    static func makeController() -> UINavigationController {
        let viewModel = InformationalModalViewModel()

        let view = InformationalModalView(viewModel: viewModel)
        let controller = InformationalModalHostingController(rootView: view.setupDefaultEnvironment())
        controller.viewModel = viewModel

        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = UIDevice.current.isiPad() ? .formSheet : .fullScreen
        viewModel.navigationController = navController

        return  navController
    }
}

fileprivate class InformationalModalHostingController<Content>: OnboardingHostingViewController<Content> where Content: View {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let viewModel = viewModel as? InformationalModalViewModel else { return }

        let imageView = ThemeableImageView(frame: .zero)
        imageView.imageNameFunc = AppTheme.pcLogoSmallHorizontalForBackgroundImageName
        imageView.accessibilityLabel = L10n.setupAccount
        navigationItem.titleView = imageView

        let dismissItem: UIBarButtonItem
        dismissItem = UIBarButtonItem(image: UIImage(named: "close"), style: .plain, target: viewModel, action: #selector(viewModel.dismissTapped))
        dismissItem.tintColor = ThemeColor.primaryText01()
        navigationItem.rightBarButtonItem = dismissItem

        navigationController?.navigationBar.isHidden = false
    }
}
