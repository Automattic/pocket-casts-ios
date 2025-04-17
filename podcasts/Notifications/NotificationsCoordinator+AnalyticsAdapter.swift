import Foundation

extension NotificationsCoordinator: AnalyticsAdapter {

    func track(name: String, properties: [AnyHashable: Any]?) {
        for notification in onboardingNotifications {
            if notification.checkCancelConditionsForEvent(name: name, properties: properties) {
                self.cancelNotification(notification)
            }
        }
    }

}

extension NotificationType {

    func checkCancelConditionsForEvent(name: String, properties: [AnyHashable: Any]?) -> Bool {
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
        case .onboardingStaffPicks:
            possibleConditions = [.discoverListShowAllTapped]
        }
        let eventMatch = possibleConditions.contains {
            $0.rawValue.toSnakeCaseFromCamelCase() == name
        }
        guard eventMatch else {
            return false
        }

        // check for properties
        switch self {
        case .onboardingStaffPicks:
            guard let properties, let listID = properties["list_id"] as? String else {
                return false
            }
            return listID == "staff-picks"
        default:
            return true
        }
    }
}
