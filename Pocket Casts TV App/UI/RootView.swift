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
                .frame(maxWidth: .infinity)
                .transition(.opacity)
            case .welcome:
                WelcomeView()
                    .transition(.opacity)
            case .browsing, .signedIn:
                MainTabView()
                    .transition(.opacity)
            case .userSync:
                SigningInView()
                    .transition(.opacity)
            case .dataLossResync:
                DataLossResyncView()
                    .transition(.opacity)
            case .serverSignedOut:
                UserSignedOutView()
                    .transition(.opacity)
            }
        }
        .animation(.smooth, value: coordinator.state)
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
