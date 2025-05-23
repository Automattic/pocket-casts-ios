import PocketCastsUtils
import SwiftUI
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

    private var bannerViewEdgeInsets: EdgeInsets {
        if case .listeningHistory = viewModel.bannerType {
            return .init(top: 22.0, leading: 16.0, bottom: 0, trailing: 16.0)
        }
        return .init(top: 16.0, leading: 16.0, bottom: 16.0, trailing: 16.0)
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
        Analytics.track(.informationalBannerViewDismissed, properties: ["source": viewModel.bannerType.rawValue.lowerSnakeCased()])
    }

    func presentLoginFlow() {
        NavigationManager.sharedManager.navigateTo(NavigationManager.onboardingFlow,
                                                   data: ["flow": OnboardingFlow.Flow.loggedOut])
        Analytics.track(.informationalBannerViewCreateAccountTap, properties: ["source": viewModel.bannerType.rawValue.lowerSnakeCased()])
    }

    func tableHeaderView(size: CGSize, onDismissBanner: @escaping () -> Void) -> UIView? {
        guard let viewModel = viewModel as? InformationalBannerViewModel else {
            return nil
        }
        self.onDismissBanner = onDismissBanner
        let headerView = UIView(frame: CGRect(origin: .zero, size: size))
        let bannerView = BannerView(
            model: viewModel,
            edgeInsets: bannerViewEdgeInsets
        ).themedUIView
        headerView.addSubview(bannerView)
        bannerView.anchorToAllSidesOf(view: headerView)
        return headerView
    }

    func bannerView() -> UIView? {
        guard let viewModel = viewModel as? InformationalBannerViewModel else {
            return nil
        }
        return BannerView(
            model: viewModel,
            edgeInsets: bannerViewEdgeInsets
        ).themedUIView
    }
}
