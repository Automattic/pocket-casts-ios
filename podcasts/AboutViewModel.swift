import Foundation

class AboutViewModel: ObservableObject {
    @Published var shouldShowWhatsNew: Bool = false
    @Published var whatsNewInfo: WhatsNewInfo?

    var whatsNewText: String {
        L10n.whatsNewInVersion(Settings.appVersion())
    }

    init() {
        whatsNewInfo = WhatsNewHelper.extractWhatsNewInfo()

        shouldShowWhatsNew = Settings.appVersion() == whatsNewInfo?.versionNo
    }

    func track(action: AboutAction) {
        switch action {
        case .rateUs:
            Analytics.track(.rateUsTapped, properties: ["source": "about"])
        case .shareWithFriends:
            Analytics.track(.settingsAboutShareWithFriendsTapped)
        case .website:
            Analytics.track(.settingsAboutWebsiteTapped)
        case .instagram:
            Analytics.track(.settingsAboutInstagramTapped)
        case .twitter:
            Analytics.track(.settingsAboutTwitterTapped)
        case .automatticFamily:
            Analytics.track(.settingsAboutAutomatticFamilyTapped)
        case .workWithUs:
            Analytics.track(.settingsAboutWorkWithUsTapped)
        }
    }

    enum AboutAction {
        case rateUs
        case shareWithFriends
        case website
        case instagram
        case twitter
        case automatticFamily
        case workWithUs
    }
}
