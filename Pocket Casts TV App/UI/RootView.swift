import SwiftUI

struct RootView: View {
    @State private var coordinator = AppCoordinator()
    @State private var focusStore = FocusStore()

    var body: some View {
        ZStack {
            switch coordinator.state {
            case .loading:
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            case .welcome:
                WelcomeView()
            case .browsing, .signedIn:
                MainTabView()
            case .userSync:
                SigningInView()
            case .dataLossResync:
                DataLossResyncView()
            }
        }
        .animation(.easeInOut, value: coordinator.state)
        .environment(coordinator)
        .environment(focusStore)
        .task {
            await coordinator.load()
        }
        .ignoresSafeArea()
        .background(
            // Subtle "lit from above" gradient instead of a flat fill: makes the
            // page feel less plastic and lets focused-card shadows read against it.
            LinearGradient(
                colors: [Color.pcBackgroundTop, Color.pcBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    RootView()
}
