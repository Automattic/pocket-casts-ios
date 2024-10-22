import Foundation
import PocketCastsDataModel
import PocketCastsServer

/// Build the list of stories for End of Year alongside the data
class EndOfYearStoriesBuilder {
    private let dataManager: DataManager

    private var model: StoryModel

    private var hasActiveSubscription: () -> Bool

    private let sync: (() -> Bool)?

    init(dataManager: DataManager = DataManager.sharedManager, model: StoryModel, sync: (() -> Bool)? = YearListeningHistory.sync, hasActiveSubscription: @escaping () -> Bool = SubscriptionHelper.hasActiveSubscription) {
        self.dataManager = dataManager
        self.model = model
        self.sync = sync
        self.hasActiveSubscription = hasActiveSubscription
    }

    /// Call this method to build the list of stories and the data provider
    func build() async {
        await withCheckedContinuation { continuation in

            let modelType = type(of: model)

            // Check if the user has the full listening history for this year
            if SyncManager.isUserLoggedIn(), !Settings.hasSyncedEpisodesForPlayback(year: modelType.year) || (Settings.hasSyncedEpisodesForPlayback(year: modelType.year) && Settings.hasSyncedEpisodesForPlaybackAsPlusUser(year: modelType.year) != hasActiveSubscription()) {
                let syncedWithSuccess = sync?()

                if syncedWithSuccess == true {
                    Settings.setHasSyncedEpisodesForPlayback(true, year: modelType.year)
                    Settings.setHasSyncedEpisodesForPlaybackAsPlusUser(hasActiveSubscription(), year: modelType.year)
                } else {
                    continuation.resume()
                    return
                }
            }

            model.populate(with: dataManager)

            continuation.resume()
        }
    }
}

protocol StoryModel {
    init()
    static var year: Int { get }
    var numberOfStories: Int { get }
    func populate(with dataManager: DataManager)
    func story(for storyNumber: Int) -> any StoryView
    func isInteractiveView(for storyNumber: Int) -> Bool
    func isReady() -> Bool
}
