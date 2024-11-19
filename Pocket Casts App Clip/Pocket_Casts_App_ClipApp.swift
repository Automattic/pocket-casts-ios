import SwiftUI
import PocketCastsServer

@main
struct Pocket_Casts_App_ClipApp: App {
    init() {
        ServerConfig.shared.syncDelegate = ServerSyncManager.shared
        ServerConfig.shared.playbackDelegate = PlaybackManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }

    }
}
