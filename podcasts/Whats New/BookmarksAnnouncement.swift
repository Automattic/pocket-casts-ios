import SwiftUI
import PocketCastsServer
import PocketCastsUtils


// MARK: - BookmarksWhatsNewHeader

struct BookmarksWhatsNewHeader: View {
    var body: some View {
        Image("whatsnew-bookmarks")
    }
}

// MARK: - BookmarkAnnouncementViewModel

class BookmarkAnnouncementViewModel {
    let feature: PaidFeature
    let buildEnvironment: BuildEnvironment
    let activeTier: SubscriptionTier

    // We use a lazy var here instead of subclassing to only get the product info if needed
    private lazy var upgradeModel = BookmarksUpgradeViewModel(feature: .bookmarks,
                                                              source: .whatsNew,
                                                              upgradeSource: "whats_new")
    private let userDefaults: UserDefaults

    init(feature: PaidFeature = .bookmarks,
         buildEnvironment: BuildEnvironment = .current,
         activeTier: SubscriptionTier = SubscriptionHelper.activeTier,
         userDefaults: UserDefaults = .standard) {
        self.feature = feature
        self.buildEnvironment = buildEnvironment
        self.activeTier = activeTier
        self.userDefaults = userDefaults
    }

    // MARK: - Checks to display the different announcements

    /// Show the full release what's new to anyone who hasn't seen it in early access
    var isReleaseAnnouncementEnabled: Bool {
        !userDefaults.bool(forKey: Constants.seenKey)
    }

    /// Will display the subscription badge in early access and when not unlocked in full release
    var displayTier: SubscriptionTier {
        return feature.isUnlocked ? .none : feature.tier
    }

    // MARK: - Titles

    var upgradeOrEnableButtonTitle: String {
        feature.isUnlocked ? enableButtonTitle : upgradeModel.upgradeLabel
    }

    // If there is an currently playing episode we show the try it now button, if not we show enable it now
    var enableButtonTitle: String {
        if PlaybackManager.shared.currentEpisode() != nil {
            return L10n.tryItNow
        }

        return L10n.enableItNow
    }

    // MARK: - Actions

    func markAsSeen() {
        userDefaults.setValue(true, forKey: Constants.seenKey)
    }

    /// Handles when the what's new action button is tapped
    func enableAction() {
        // If the feature isn't unlocked, then show the upgrade view
        guard feature.isUnlocked else {
            upgradeModel.showUpgrade()
            return
        }

        // Show the player
        if PlaybackManager.shared.currentEpisode() != nil {
            AnnouncementFlow.current = .bookmarksPlayer
            NavigationManager.sharedManager.miniPlayer?.openFullScreenPlayer()
            return
        }

        // Show the headphone controls
        AnnouncementFlow.current = .bookmarksProfile
        NavigationManager.sharedManager.navigateTo(NavigationManager.settingsProfileKey, data: nil)
    }

    private enum Constants {
        static let seenKey = "WhatsNew.Bookmarks.EarlyAccess.Seen"
    }
}
