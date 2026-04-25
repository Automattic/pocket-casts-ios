import SwiftUI

struct WelcomeView: View {
    @Environment(RootViewModel.self) var viewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image("pc-logo")
            Text(L10n.tvWelcomeTitle)
                .font(.title)
            Text(L10n.tvWelcomeSubtitle)
                .font(.headline)
                .foregroundColor(Color.textSecondary)
            HStack {
                Button(L10n.tvWelcomeSignIn) { viewModel.state = .signedIn }
                    .buttonStyle(.borderedProminent)
                Button(L10n.tvWelcomeCreateFreeAccount) { viewModel.state = .signedIn }
                    .buttonStyle(.borderedProminent)
            }
            Spacer()
            Button(L10n.tvWelcomeBrowseWithoutAccount) {
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
