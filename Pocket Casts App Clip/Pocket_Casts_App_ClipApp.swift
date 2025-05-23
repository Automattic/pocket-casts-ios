import SwiftUI
import PocketCastsServer
import AutomatticTracks

@main
struct Pocket_Casts_App_ClipApp: App {

    @UIApplicationDelegateAdaptor private var appDelegate: AppClipAppDelegate

    init() {
        ServerConfig.shared.syncDelegate = ServerSyncManager.shared
        ServerConfig.shared.playbackDelegate = PlaybackManager.shared

        ServerSettings.setSkipBackTime(10, syncChange: false)
        ServerSettings.setSkipForwardTime(45, syncChange: false)

        Analytics.register(adapters: [AnalyticsLoggingAdapter(), TracksAdapter()])
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                NowPlayingView()
                    .background(Color(UIColor.systemBackground))
            }
            .onAppear {
                Analytics.track(.appClipOpened)
            }
        }
    }
}
