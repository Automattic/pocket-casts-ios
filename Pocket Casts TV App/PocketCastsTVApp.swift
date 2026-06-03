import SwiftUI

@main
struct PocketCastsTVApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AnalyticsSetup.setupIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, newPhase in
            TVAppLifecycleAnalytics.shared.handle(scenePhase: newPhase)
        }
    }
}
