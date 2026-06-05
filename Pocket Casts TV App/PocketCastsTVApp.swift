import SwiftUI

@main
struct PocketCastsTVApp: App {
    @Environment(\.scenePhase) private var scenePhase

    private let appLifecycleAnalytics = AppLifecycleAnalytics()

    init() {
        AnalyticsSetup.setupIfNeeded()
        _ = appLifecycleAnalytics.checkApplicationInstalledOrUpgraded()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, newPhase in
            appLifecycleAnalytics.handle(scenePhase: newPhase)
        }
    }
}
