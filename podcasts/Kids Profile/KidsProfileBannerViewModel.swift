import Foundation

class KidsProfileBannerViewModel {
    var onCloseButtonTap: (() -> Void)? = nil
    var onRequestEarlyAccessTap: (() -> Void)? = nil

    func closeButtonTap() {
        onCloseButtonTap?()
    }

    func requestEarlyAccessTap() {
        onRequestEarlyAccessTap?()
    }
}
