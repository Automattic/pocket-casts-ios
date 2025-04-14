import Foundation

extension NotificationsCoordinator: AnalyticsAdapter {

    func track(name: String, properties: [AnyHashable: Any]?) {
        for notification in onboardingNotifications {
            if notification.checkCancelConditionsForEvent(name: name) {
                self.cancelNotification(notification)
            }
        }
    }

}

extension NotificationType {

    func checkCancelConditionsForEvent(name: String) -> Bool {
        var possibleConditions: Set<AnalyticsEvent>

        switch self {
        case .onboardingSignUp:
            possibleConditions = [.userSignedIn, .userAccountCreated]
        case .onboardingImport:
            possibleConditions = [.settingsImportShown, .onboardingImportShown]
        case .onboardingThemes:
            possibleConditions = [.settingsAppearanceThemeChanged]
        case .onboardingUpNext:
            possibleConditions = [.episodeAddedToUpNext, .episodeBulkAddToUpNext]
        case .onboardingFilters:
            possibleConditions = [.filterCreated]
        case .onboardingUpsell:
            possibleConditions  = [.purchaseSuccessful]
        }
        return possibleConditions.contains {
            $0.rawValue.toSnakeCaseFromCamelCase() == name
        }
    }
}
