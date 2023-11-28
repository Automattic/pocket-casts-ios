import Foundation

protocol AnalyticsSourceProvider {
    /// Used to define the source view for the various analytics actions
    var analyticsSource: AnalyticsSource { get }
}

enum AnalyticsSource: String, AnalyticsDescribable {
    case appIconMenu = "app_icon_menu"
    case carPlay = "carplay"
    case chooseFolder = "choose_folder"
    case chromecast
    case discover
    case discoverCategory = "discover_category"
    case discoverEpisodeList = "discover_episode_list"
    case discoverRankedList = "discover_ranked_list"
    case downloads
    case downloadStatus = "download_status"
    case episodeDetail = "episode_detail"
    case episodeStatus = "episode_status"
    case files
    case filters
    case incomingShareList = "incoming_share_list"
    case listeningHistory = "listening_history"
    case mediaType = "media_type"
    case miniplayer
    case noFiles = "no_files"
    case noFilters = "no_filters"
    case nowPlayingWidget = "now_playing_widget"
    case player
    case playerPlaybackEffects = "player_playback_effects"
    case playerSkipForwardLongPress = "player_skip_forward_long_press"
    case podcastScreen = "podcast_screen"
    case podcastSettings = "podcast_settings"
    case podcastsList = "podcasts_list"
    case profile
    case releaseDate = "release_date"
    case siri
    case starred
    case sync
    case upNext = "up_next"
    case userEpisode = "user_episode"
    case videoPlayerSkipForwardLongPress = "video_player_skip_forward_long_press"
    case playbackFailed = "playback_failed"
    case watch
    case bookmark
    case interactiveWidget = "interactive_widget"
    case unknown

    var analyticsDescription: String { rawValue }
}

class AnalyticsCoordinator {
    /// Sometimes the playback source can't be inferred, just inform it here
    var currentSource: AnalyticsSource?

    #if !os(watchOS)
        var currentAnalyticsSource: AnalyticsSource {
            if let currentSource = currentSource {
                self.currentSource = nil
                return currentSource
            }

            return (getTopViewController() as? AnalyticsSourceProvider)?.analyticsSource ?? .unknown
        }

        func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
            // Only dispatch async on the main thread if needed
            guard Thread.isMainThread else {
                DispatchQueue.main.async {
                    self.track(event, properties: properties)
                }
                return
            }

            let defaultProperties: [String: Any] = ["source": currentAnalyticsSource]
            let mergedProperties = defaultProperties.merging(properties ?? [:]) { current, _ in current }
            Analytics.track(event, properties: mergedProperties)
        }

    func getTopViewController(base: UIViewController? = SceneHelper.rootViewController()) -> UIViewController? {
            guard UIApplication.shared.applicationState == .active else {
                return nil
            }

            if let nav = base as? UINavigationController {
                return getTopViewController(base: nav.visibleViewController)
            } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
                return getTopViewController(base: selected)
            } else if let presented = base?.presentedViewController {
                return getTopViewController(base: presented)
            }
            return base
        }
    #else
        /// NOOP track event to preventing needing to wrap all the events in #if checks
        func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {}
    #endif
}
