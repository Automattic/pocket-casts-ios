import Foundation
import PocketCastsServer

extension DeveloperMenuPage {
    static var tipsAndPrompts: DeveloperMenuPage {
        let tips: [DeveloperMenuItem] = [
            .action("Reset Informational Banners") {
                InformationalBannerType.allCases.forEach {
                    UserDefaults.standard.set(false, forKey: "kInformational\($0.rawValue.capitalized)Banner")
                }
            },
            .action("Reset Suggested Folders CTA") {
                Settings.suggestedFoldersUpsellCount = 0
                Settings.suggestedFoldersLastUpsellDate = nil
            },
            .action("Reset Referrals Tip") {
                Settings.shouldShowReferralsTip = true
            },
            .action("Reset Up Next Sort Tip") {
                Settings.shouldShowUpNextSortDurationTip = true
            },
            .action("Reset Cancel Subscription Survey") {
                Settings.subscriptionCancelledSurveyShown = false
            },
            .action("Reset What's New Read State", subtitle: "Local only") {
                WhatsNewManager.shared.resetReadState()
            }
        ]

        return DeveloperMenuPage(title: "Tips & Prompts", systemImage: "lightbulb", sections: [
            DeveloperMenuSection(items: [
                .action("Reset All Tips") {
                    for item in tips {
                        if case .action(let perform) = item.kind {
                            perform()
                        }
                    }
                }
            ]),
            DeveloperMenuSection(title: "Tips", items: tips),
            DeveloperMenuSection(title: "Launch", footer: "Shown on the next launch.", items: [
                .action("Reset Initial Onboarding Flow") {
                    Settings.shouldShowInitialOnboardingFlow = true
                },
                .action("Trigger Encourage Account Creation Modal") {
                    Settings.encourageAccountCreationReferenceDate = Date().addingTimeInterval(-Settings.encourageAccountCreationInterval)
                }
            ]),
            DeveloperMenuSection(title: "End of Year", items: EndOfYear.Year.allCases.compactMap(\.year).map { year in
                .action("Reset End of Year \(year) Modal and Badge") {
                    Settings.setHasShownModalForEndOfYear(false, year: year)
                    Settings.setShowBadgeForEndOfYear(true, year: year)
                }
            })
        ])
    }
}
