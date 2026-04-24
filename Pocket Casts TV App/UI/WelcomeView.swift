import SwiftUI

struct WelcomeView: View {
    @Environment(RootViewModel.self) var viewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image("pc-logo")
            Text("Welcome to Pocket Casts TV")
                .font(.title)
            Text("Your podcasts on the big screen")
                .font(.headline)
                .foregroundColor(Color.textSecondary)
            HStack {
                Button("Sign in") { viewModel.state = .signedIn }
                    .buttonStyle(.borderedProminent)
                Button("Create Free Account") { viewModel.state = .signedIn }
                    .buttonStyle(.borderedProminent)
            }
            Spacer()
            Button("Browse without an account") {
                viewModel.state = .browsing
            }
            .buttonStyle(.plain)
            .foregroundColor(Color.textSecondary)
        }
    }
}

#Preview {
    WelcomeView()
        .environment(RootViewModel())
}
