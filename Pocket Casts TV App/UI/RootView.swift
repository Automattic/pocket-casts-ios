import SwiftUI

@Observable
class RootViewModel {
    enum State {
        case loading
        case welcome
        case browsing
        case signedIn
    }

    var state: State = .welcome

    init() {

    }
}

struct RootView: View {
    @State private var viewModel = RootViewModel()

    var body: some View {
        switch viewModel.state {
        case .loading:
            VStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        case .welcome:
            WelcomeView().environment(viewModel)
        case .browsing, .signedIn:
            MainTabView()
        }
    }
}

#Preview {
    RootView()
}
