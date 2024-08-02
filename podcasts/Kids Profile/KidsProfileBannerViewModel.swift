import Foundation

class KidsProfileBannerViewModel {
    var onCloseButtonTap: (() -> Void)? = nil
    var onRequestEarlyAccessTap: (() -> Void)? = nil

    func closeButtonTap() {
        Settings.shouldHideBanner = true
        onCloseButtonTap?()
    }

    func requestEarlyAccessTap() {
        onRequestEarlyAccessTap?()
    }
}
