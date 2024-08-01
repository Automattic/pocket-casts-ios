import Foundation

class KidsProfileBannerViewModel {
    var onCloseButtonTap: (() -> Void)? = nil
    var onRequestEarlyAccessTap: (() -> Void)? = nil

    func closeButtonTap() {
        UserDefaults.standard.setValue(true, forKey: Constants.UserDefaults.kidsProfile.shouldHideBanner)
        onCloseButtonTap?()
    }

    func requestEarlyAccessTap() {
        onRequestEarlyAccessTap?()
    }
}
