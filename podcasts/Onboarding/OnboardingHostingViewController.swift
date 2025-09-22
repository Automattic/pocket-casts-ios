import Foundation
import SwiftUI

class OnboardingHostingViewController<Content>: UIHostingController<Content>, UIAdaptivePresentationControllerDelegate where Content: View {
    var navBarIsHidden: Bool = false
    var iconTintColor: UIColor = AppTheme.colorForStyle(.primaryIcon01)

    var viewModel: OnboardingModel?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationBarStyle(animated: false)

        navigationController?.navigationBar.isHidden = navBarIsHidden
        navigationController?.navigationBar.tintColor = iconTintColor
        navigationItem.backButtonDisplayMode = .minimal
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel?.didAppear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let controller = navigationController ?? self
        guard controller.isBeingDismissed else { return }

        DispatchQueue.main.async {
            OnboardingFlow.shared.reset()
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        navigationController?.presentationController?.delegate = self

        updateNavigationBarStyle(animated: false)

        navigationItem.backButtonDisplayMode = .minimal
        navigationController?.navigationBar.tintColor = iconTintColor

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewModel?.didDismiss(type: .viewDisappearing)
    }

    @objc func themeDidChange() {
        updateNavigationBarStyle(animated: false)
    }

    private func updateNavigationBarStyle(animated: Bool) {
        guard animated else {
            apply()
            return
        }

        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime) {
            self.apply()
        }
    }

    private func apply() {
        let barAppearance = UINavigationBar.appearance(whenContainedInInstancesOf: [Self.self])

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = nil
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

        // Update the back icon
        let config = UIImage.SymbolConfiguration(weight: .bold)
        let image = UIImage(systemName: "arrow.left")?.applyingSymbolConfiguration(config)

        barAppearance.backIndicatorImage = image
        barAppearance.backIndicatorTransitionMaskImage = image
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        viewModel?.didDismiss(type: .swipe)
    }
}

class OnboardingModalHostingViewController<Content>: BottomSheetSwiftUIWrapper<Content> where Content: View {
    var viewModel: OnboardingModel?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel?.didAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewModel?.didDismiss(type: .viewDisappearing)
    }
}
