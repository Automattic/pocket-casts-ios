import Foundation

extension NotificationsCoordinator: AnalyticsAdapter {

    func track(name: String, properties: [AnyHashable: Any]?) {
        updateDailyReminders(name: name, properties: properties)
        updateReEngagementNotifications(name: name, properties: properties)
        updateRecommendationNotifications(name: name, properties: properties)
    }

    func updateDailyReminders(name: String, properties: [AnyHashable: Any]?) {
        guard NotificationsGroup.dailyReminders.isEnabled else {
            return
        }
        for notification in NotificationsGroup.dailyReminders.notifications {
            if notification.checkCancelConditionsForEvent(name: name, properties: properties) {
                markNotification(notification)
                self.cancelNotification(notification)
            }
        }
    }

    func updateReEngagementNotifications(name: String, properties: [AnyHashable: Any]?) {
        guard NotificationsGroup.newFeaturesAndTips.isEnabled else {
            return
        }
        // Check if need to cancel an existing notification
        for notification in NotificationsGroup.newFeaturesAndTips.notifications {
            if notification.checkCancelConditionsForEvent(name: name, properties: properties) {
                cancelNotification(notification)
            }
        }

        let event: AnalyticsEvent = .applicationClosed
        if event.rawValue.toSnakeCaseFromCamelCase() == name {
            updateNotifications(for: .newFeaturesAndTips)
        }
    }

    func updateRecommendationNotifications(name: String, properties: [AnyHashable: Any]?) {
        guard NotificationsGroup.recommendations.isEnabled else {
            return
        }
        var shouldUpdateNotifications = false
        for notification in NotificationsGroup.recommendations.notifications {
            if notification.checkCancelConditionsForEvent(name: name, properties: properties) {
                shouldUpdateNotifications = true
            }
        }
        if shouldUpdateNotifications {
            updateNotifications(for: .recommendations)
        }
    }
}

extension NotificationType {

    func checkCancelConditionsForEvent(name: String, properties: [AnyHashable: Any]?) -> Bool {
        var possibleConditions: Set<AnalyticsEvent>

        switch self {
        case .reengagementWeekly:
            possibleConditions = [.applicationOpened]
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
        case .recommendationsTrending, .recommendationsYouMightLike:
            possibleConditions = [.discoverListShowAllTapped]
        case .upsell:
            possibleConditions = [.purchaseSuccessful]
        case .newFeatureSuggestedFolders:
            possibleConditions = [.suggestedFoldersPageShown]
        case .reengagementDownloads:
            possibleConditions = [.downloadsShown]
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
        case .recommendationsTrending:
                guard let properties, let listID = properties["list_id"] as? String else {
                    return false
                }
                return listID == "trending"
        case .recommendationsYouMightLike:
                guard let properties, let listID = properties["list_id"] as? String else {
                    return false
                }
                return listID == "recommendations_user"
        default:
            return true
        }
    }
}
