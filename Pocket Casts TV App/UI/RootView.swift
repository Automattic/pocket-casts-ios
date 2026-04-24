import SwiftUI

@Observable
class RootViewModel {
    var isLoading: Bool = false
    var isSignedIn: Bool = false

    init() {
        isLoading = false
        isSignedIn = true
    }
}

struct RootView: View {
    @State private var viewModel = RootViewModel()

    var body: some View {
        if viewModel.isLoading {
            VStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        } else {
            if viewModel.isSignedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    RootView()
}
