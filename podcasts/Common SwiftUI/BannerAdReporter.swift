/// Handles all Banner Ad reporting logic and provides `show` to present a bottom sheet to pick from reporting options
struct BannerAdReporter {
    enum ReportActionType: CaseIterable {
        case broken
        case malicious
        case tooOften
        case other

        var label: String {
            switch self {
            case .broken:
                return L10n.bannerAdsReportBroken
            case .malicious:
                return L10n.bannerAdsReportMalicious
            case .tooOften:
                return L10n.bannerAdsReportTooOften
            case .other:
                return L10n.bannerAdsReportOther
            }
        }

        var analyticsValue: String {
            switch self {
            case .broken:
                "broken"
            case .malicious:
                "malicious"
            case .tooOften:
                "too_often"
            case .other:
                "other"
            }
        }
    }

    /// Shows the ad reporting bottom sheet with options to report various problems with an ad
    static func show(for adID: String, from source: String) {
        func handle(action: ReportActionType) {
            AnalyticsHelper.bannerReport(adID: adID, reason: action.analyticsValue, location: source)
            Toast.show(L10n.bannerAdsReportConfirmation)
        }

        let reportOptions = OptionsPicker(title: nil)

        let removeAction = OptionAction(label: L10n.bannerAdsRemoveAds, icon: "unsubscribe") {
            NavigationManager.sharedManager.showUpsellView(from: SceneHelper.rootViewController()!, source: .bannerAd)
        }
        reportOptions.addAction(action: removeAction)

        let reportPicker = OptionsPicker(title: L10n.bannerAdsReportAdTitle)
        for action in ReportActionType.allCases {
            reportPicker.addAction(action: OptionAction(label: action.label) {
                handle(action: action)
            })
        }

        let reportAction = OptionAction(label: L10n.bannerAdsReportAd, icon: "show_notes") {
            reportPicker.show()
        }
        reportOptions.addAction(action: reportAction)

        reportOptions.show()
    }
}
