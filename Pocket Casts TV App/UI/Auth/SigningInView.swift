import SwiftUI

struct SigningInView: View {
    @Environment(AppCoordinator.self) var coordinator

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
                .foregroundStyle(Color.textPrimary)
            Text(L10n.tvSigningInSubtitle)
                .font(.headline)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            podcastGrid
            Spacer().frame(height: 100)
        }
        .task {
            model.sync()
        }
        .onChange(of: model.state) {
            coordinator.state = .signedIn
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
        .environment(AppCoordinator())
}
