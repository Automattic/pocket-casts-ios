import SwiftUI
import PocketCastsServer
import AutomatticTracks

@main
struct Pocket_Casts_App_ClipApp: App {
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
                ContentView()
                    .background(Color(UIColor.systemBackground))

//                    .padding(.top, 60)
            }
            .onAppear {
                Analytics.track(.appClipOpened)
            }
        }
    }
}
