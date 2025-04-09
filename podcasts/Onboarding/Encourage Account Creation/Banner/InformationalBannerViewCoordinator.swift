import PocketCastsUtils
import PocketCastsServer

class InformationalBannerViewCoordinator {
    private var viewModel: InformationalBannerPresenting

    var onDismissBanner: (() -> Void)? = nil

    init(viewModel: InformationalBannerPresenting) {
        self.viewModel = viewModel
        setupBinding()
    }

    private func setupBinding() {
        viewModel.onCloseBannerTap = { [weak self] in
            self?.dismissBanner()
        }

        viewModel.onCreateFreeAccountTap = { [weak self] in
            self?.presentLoginFlow()
        }
    }

    func shouldShowBanner() -> Bool {
        guard
            FeatureFlag.encourageAccountCreation.enabled,
            Settings.shouldShowBanner(for: viewModel.bannerType),
            !SyncManager.isUserLoggedIn()
        else {
            return false
        }
        return true
    }

    func dismissBanner() {
        onDismissBanner?()
        Settings.dismissBanner(for: viewModel.bannerType)
    }

    func presentLoginFlow() {
        NavigationManager.sharedManager.navigateTo(NavigationManager.onboardingFlow,
                                                   data: ["flow": OnboardingFlow.Flow.loggedOut])
    }

    func tableHeaderView(size: CGSize, onDismissBanner: @escaping () -> Void) -> UIView? {
        guard let viewModel = viewModel as? InformationalBannerViewModel else {
            return nil
        }
        self.onDismissBanner = onDismissBanner
        let headerView = UIView(frame: CGRect(origin: .zero, size: size))
        let bannerView = InformationalBannerView(viewModel: viewModel).themedUIView
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(bannerView)
        bannerView.anchorToAllSidesOf(view: headerView)
        return headerView
    }

    func bannerView() -> UIView? {
        guard let viewModel = viewModel as? InformationalBannerViewModel else {
            return nil
        }
        return InformationalBannerView(viewModel: viewModel).themedUIView
    }
}
