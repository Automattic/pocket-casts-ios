import Foundation
import PocketCastsServer

extension DeveloperMenuPage {
    static var notifications: DeveloperMenuPage {
        DeveloperMenuPage(title: "Notifications", systemImage: "bell", sections: [
            DeveloperMenuSection(items: [
                .action("Speed Up Notifications") {
                    NotificationsGroup.speedUpNotifications = true
                },
                .action("Log Schedule") {
                    NotificationsCoordinator.shared.debugMode = true
                }
            ])
        ])
    }

    static var debugOptions: DeveloperMenuPage {
        var items: [DeveloperMenuItem] = [
            .link("Survey Debug Info") {
                SurveyDebugInfoView()
            },
            .toggle("Debug Playlists Limit", subtitle: "Limits playlists to 6 episodes", isOn: {
                Settings.debugPlaylistsLimit != Constants.Limits.maxFilterItems
            }, set: { isOn in
                Settings.debugPlaylistsLimit = isOn ? 6 : Constants.Limits.maxFilterItems
            })
        ]
        #if DEBUG
        items.append(.toggle("What's New Mock Catalog", isOn: {
            WhatsNewManager.shared.usesMockCatalog
        }, set: { isOn in
            WhatsNewManager.shared.usesMockCatalog = isOn
        }))
        #endif
        return DeveloperMenuPage(title: "Debug Options", systemImage: "slider.horizontal.3", sections: [
            DeveloperMenuSection(items: items)
        ])
    }
}
