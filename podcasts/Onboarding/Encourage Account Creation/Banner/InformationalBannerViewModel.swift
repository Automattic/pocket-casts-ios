import Foundation

protocol InformationalBannerPresenting {
    var bannerType: InformationalBannerType { get }
    var onCloseBannerTap: (() -> Void)? { get set }
    var onCreateFreeAccountTap: (() -> Void)? { get set }

    func closeBanner()
    func createFreeAccount()
}

extension InformationalBannerPresenting {
    func closeBanner() {
        onCloseBannerTap?()
    }

    func createFreeAccount() {
        onCreateFreeAccountTap?()
    }
}

class InformationalBannerViewModel: BannerModel, InformationalBannerPresenting {
    let bannerType: InformationalBannerType

    var onCloseBannerTap: (() -> Void)? = nil
    var onCreateFreeAccountTap: (() -> Void)? = nil

    init(bannerType: InformationalBannerType, invertedColor: Bool? = nil) {
        self.bannerType = bannerType
        super.init(
            title: bannerType.title,
            message: bannerType.description,
            action: L10n.eacInformationalBannerCreateAccount,
            iconName: bannerType.iconName,
            invertedColor: invertedColor ?? (bannerType == .profile))
        setupBinding()
    }

    private func setupBinding() {
        setupBinding { [weak self] in
            self?.onCreateFreeAccountTap?()
        } onCloseTap: { [weak self] in
            self?.onCloseBannerTap?()
        }
    }
}
