import SwiftUI

@main
struct PocketCastsTVApp: App {
    @Environment(\.scenePhase) private var scenePhase

    private let appLifecycleAnalytics = AppLifecycleAnalytics()
    private let backgroundPlaybackManagement = BackgroundPlaybackManagement()

    init() {
        // Before anything opens the database, so a requested wipe hits a closed file.
        DataLossSimulator.simulateIfRequested()

        AnalyticsSetup.setupIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
            .task {
                appLifecycleAnalytics.didBecomeActive()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            appLifecycleAnalytics.handle(scenePhase: newPhase)
            backgroundPlaybackManagement.handle(scenePhase: newPhase)
        }
    }
}
