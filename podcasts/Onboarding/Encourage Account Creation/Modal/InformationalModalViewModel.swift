import Foundation
import SwiftUI
import PocketCastsUtils

class InformationalModalViewModel: NSObject, OnboardingModel {
    weak var navigationController: UINavigationController? = nil

    func didAppear() {
        Analytics.track(.informationalModalViewShowed)
        pageDidChange(0)
    }

    func didDismiss(type: OnboardingDismissType) {
        if type != .swipe {
            return
        }
        Analytics.track(.informationalModalViewDismissed)
    }

    func getStarted() {
        Analytics.track(.informationalModalViewGetStartedTap)
        pushOnboarding()
    }

    func login() {
        Analytics.track(.informationalModalViewLoginTap)
        pushOnboarding()
    }

    func pageDidChange(_ index: Int) {
        if let card = cardName(from: index) {
            Analytics.track(.informationalModalViewCardShowed, properties: ["card": card])
        }
    }

    @objc func dismissTapped() {
        navigationController?.dismiss(animated: true) { [weak self] in
            self?.didDismiss(type: .swipe)
        }
    }

    private func pushOnboarding() {
        let controller = OnboardingFlow.shared.begin(flow: FeatureFlag.newOnboardingAccountCreation.enabled ? .loggedOut : .initialOnboarding, in: navigationController, source: .unknown)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func cardName(from index: Int) -> String? {
        switch index {
        case 0:
            return InformationalFeatureCardItem.sync.rawValue
        case 1:
            return InformationalFeatureCardItem.backups.rawValue
        case 2:
            return InformationalFeatureCardItem.recommendation.rawValue
        default:
            return nil
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
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.colorForStyle(.primaryUi01)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let viewModel = viewModel as? InformationalModalViewModel else { return }

        Settings.hasShownInformationalViewModal = true

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
