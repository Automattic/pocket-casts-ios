import Foundation

enum InformationalBannerType: String {
    case filters
    case listenHistory
    case profile

    var iconName: String {
        switch self {
        case .filters:
            return "filter"
        case .listenHistory:
            return "listen_history"
        case .profile:
            return "profile"
        }
    }

    var title: String {
        switch self {
        case .filters:
            return "Keep your filters in sync"
        case .listenHistory:
            return "Keep track of what you’ve played"
        case .profile:
            return "Your shows, on any device"
        }
    }

    var description: String {
        switch self {
        case .filters:
            return "Create a free account to sync your filters on any device."
        case .listenHistory:
            return "Create a free account to sync your listening history everywhere."
        case .profile:
            return "Create a free account to sync your shows and listen anywhere."
        }
    }
}

class InformationalBannerViewModel {
    let bannerType: InformationalBannerType

    var onCloseBannerTap: (() -> Void)? = nil
    var onCreateFreeAccountTap: (() -> Void)? = nil

    private let userDefaults: UserDefaults

    init(bannerType: InformationalBannerType, userDefaults: UserDefaults = .standard) {
        self.bannerType = bannerType
        self.userDefaults = userDefaults
    }

    func shouldShowBanner() -> Bool {
        return !userDefaults.bool(forKey: "kInformational\(bannerType.rawValue.capitalized)Banner")
    }

    func closeBanner() {
        onCloseBannerTap?()
        // Add Analytics
        userDefaults.set(true, forKey: "kInformational\(bannerType.rawValue.capitalized)Banner")
    }

    func createFreeAccount() {
        onCreateFreeAccountTap?()
        // Add Analytics
    }
}
