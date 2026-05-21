import SwiftUI

struct RootView: View {
    @State private var coordinator = AppCoordinator()
    @State private var toastManager = ToastManager.shared

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
            }
        }
        .environment(coordinator)
        .environment(toastManager)
        .task {
            await coordinator.load()
        }
    }
}

#Preview {
    RootView()
}
