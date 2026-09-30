import PocketCastsServer
import SwiftUI

extension DeveloperMenuSection {
    static var tipsAndPrompts: DeveloperMenuSection {
        let tips: [DeveloperMenuItem] = [
            .action("Informational Banners") {
                InformationalBannerType.allCases.forEach {
                    UserDefaults.standard.set(false, forKey: "kInformational\($0.rawValue.capitalized)Banner")
                }
            },
            .action("Suggested Folders CTA") {
                Settings.suggestedFoldersUpsellCount = 0
                Settings.suggestedFoldersLastUpsellDate = nil
            },
            .action("Referrals Tip") {
                Settings.shouldShowReferralsTip = true
            },
            .action("Up Next Sort Tip") {
                Settings.shouldShowUpNextSortDurationTip = true
            },
            .action("Cancel Subscription Survey") {
                Settings.subscriptionCancelledSurveyShown = false
            }
        ]

        return DeveloperMenuSection(title: "Tips & Prompts", footer: "The onboarding flow and the account creation modal show on the next launch.", items: [
            .menu("Reset Tip", sections: [
                DeveloperMenuSection(items: [
                    .action("All Tips") {
                        for item in tips {
                            if case .action(let perform) = item.kind {
                                perform()
                            }
                        }
                    }
                ]),
                DeveloperMenuSection(items: tips)
            ]),
            .menu("Reset End of Year Modal and Badge", items: EndOfYear.Year.allCases.compactMap(\.year).map { year in
                .action(String(year)) {
                    Settings.setHasShownModalForEndOfYear(false, year: year)
                    Settings.setShowBadgeForEndOfYear(true, year: year)
                }
            }),
            .toggle("Show Initial Onboarding Flow", isOn: {
                Settings.shouldShowInitialOnboardingFlow
            }, set: { isOn in
                Settings.shouldShowInitialOnboardingFlow = isOn
            }),
            .action("Trigger Encourage Account Creation Modal") {
                Settings.encourageAccountCreationReferenceDate = Date().addingTimeInterval(-Settings.encourageAccountCreationInterval)
            }
        ])
    }

    static var notifications: DeveloperMenuSection {
        DeveloperMenuSection(title: "Notifications", items: [
            .toggle("Speed Up Notifications", isOn: {
                NotificationsGroup.speedUpNotifications
            }, set: { isOn in
                NotificationsGroup.speedUpNotifications = isOn
            }),
            .toggle("Log Schedule", isOn: {
                NotificationsCoordinator.shared.debugMode
            }, set: { isOn in
                NotificationsCoordinator.shared.debugMode = isOn
            })
        ])
    }

    @MainActor
    static var whatsNew: DeveloperMenuSection {
        var items: [DeveloperMenuItem] = []
        #if DEBUG
        let manager = WhatsNewManager.shared
        items.append(.toggle("Use Mock Catalog", isOn: {
            manager.usesMockCatalog
        }, set: { isOn in
            manager.usesMockCatalog = isOn
        }))
        if manager.usesMockCatalog {
            items.append(.toggle("Auto-Publish", subtitle: "A new message on each refresh", isOn: {
                manager.publishesMockMessageOnRefresh
            }, set: { isOn in
                manager.publishesMockMessageOnRefresh = isOn
            }))
        }
        items.append(.action("Reset", subtitle: "Mock catalog and read state") {
            manager.resetMockCatalog()
        }.disabled(!manager.usesMockCatalog))
        #endif
        items.append(.link("Actions") {
            List {
                DeveloperMenuSectionView(section: DeveloperMenuSection(footer: "Performs each action the way a message's button does.", items: WhatsNewAction.Kind.all.map { kind in
                    .action(kind.title, subtitle: kind.type) {
                        kind.perform()
                    }
                }))
            }
        })
        return DeveloperMenuSection(title: "What's New", items: items)
    }

    static var playlists: DeveloperMenuSection {
        DeveloperMenuSection(title: "Playlists", items: [
            .toggle("Debug Playlists Limit", subtitle: "Limits playlists to 6 episodes", isOn: {
                Settings.debugPlaylistsLimit != Constants.Limits.maxFilterItems
            }, set: { isOn in
                Settings.debugPlaylistsLimit = isOn ? 6 : Constants.Limits.maxFilterItems
            })
        ])
    }
}

private extension WhatsNewAction.Kind {
    /// Every action a message can carry.
    static let all: [Self] = [
        .createPlaylist,
        .openDiscover,
        .openPlaylists,
        .openPodcasts,
        .openProfile,
        .openSettings,
        .openUpNext,
        .openUpsell,
        .openLink(URL(string: "https://pocketcasts.com/")!)
    ]

    /// The action's type in words, such as "Open Up Next" for `open_up_next`.
    var title: String {
        type.split(separator: "_").map(\.capitalized).joined(separator: " ")
    }
}
