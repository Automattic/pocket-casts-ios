import SwiftUI

struct RootView: View {
    @State private var coordinator = AppCoordinator()

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
        }.environment(coordinator)
    }
}

#Preview {
    RootView()
}
