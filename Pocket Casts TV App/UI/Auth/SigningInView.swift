import SwiftUI

@Observable
class SigningInViewModel {
    var podcasts: [MockPodcast] = MockData.makePodcasts()
}

struct SigningInView: View {
    @Environment(RootViewModel.self) var viewModel

    @State private var model = SigningInViewModel()

    enum Layout {
        static let gridSize = CGFloat(272)
        static let qrSize = CGFloat(240)
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(ImageResource.pcLogo)
            Text(L10n.tvSigningInTitle)
                .font(.title)
            Text(L10n.tvSigningInSubtitle)
                .font(.headline)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            podcastGrid
            Spacer().frame(height: 100)
        }
    }

    var podcastGrid: some View {
        HStack(spacing: 24, content: {
            ForEach(model.podcasts) { podcast in
                Image(podcast.image)
                    .resizable()
                    .frame(width: Layout.gridSize, height: Layout.gridSize)
            }
        }).ignoresSafeArea()
    }
}

#Preview {
    SigningInView()
        .environment(RootViewModel())
}
