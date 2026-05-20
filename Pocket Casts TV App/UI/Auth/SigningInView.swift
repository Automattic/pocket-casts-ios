import SwiftUI
import PocketCastsDataModel

fileprivate enum Layout {
    static let gridSize = CGFloat(272)
    static let qrSize = CGFloat(240)
}

struct SigningInView<ViewModel: SigningInViewModelProtocol>: View {
    @Environment(AppCoordinator.self) var coordinator

    @State private var model: ViewModel

    init(model: ViewModel = SigningInViewModel()) {
        self.model = model
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
            if let title = model.title {
                Text(title)
            }
            ProgressView(value: model.progress)
            Spacer()
            podcastGrid
            Spacer().frame(height: 100)
        }
        .task {
            model.sync()
        }
        .onChange(of: model.state) {
            if model.state == .finished {
                coordinator.state = .signedIn
            }
        }
    }

    var podcastGrid: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 24, content: {
                ForEach(model.podcasts) { podcast in
                    PodcastImage(uuid: podcast.uuid, size: .page)
                        .frame(width: Layout.gridSize, height: Layout.gridSize)
                }
            }).ignoresSafeArea()
        }
    }
}

#Preview {
    SigningInView(model: SigningInViewModelMock())
        .environment(AppCoordinator())
}
