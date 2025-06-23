import AppIntents

@available(iOS 18.2, *)
struct AppEntityUserActivity {

    enum ActivityIdentifier: String {
        case playingEpisode = "au.com.shiftyjelly.podcasts.PlayingEpisode"

        func title<T: AppEntity>(for entity: T) -> String {
            switch self {
            case .playingEpisode:
                return "Playing \(entity.displayRepresentation.title)"
            }
        }
    }

    static func advertise<T: AppEntity>(entity: T, type: ActivityIdentifier) {
        let userActivity = NSUserActivity(activityType: ActivityIdentifier.playingEpisode.rawValue)
        userActivity.title = type.title(for: entity)
        let id = EntityIdentifier(for: entity)
        userActivity.isEligibleForPrediction = true
        userActivity.appEntityIdentifier = id
        userActivity.becomeCurrent()
    }
}
