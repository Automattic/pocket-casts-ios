import SwiftUI
import PocketCastsDataModel

fileprivate enum Layout {
    static let gridSize = CGFloat(272)
    static let qrSize = CGFloat(240)
    static let gridSpacing = CGFloat(24)
    static let cornerRadius = CGFloat(16)
    static let fadeDuration = 0.8
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
            VStack(spacing: 16) {
                Text(L10n.tvSigningInTitle)
                    .font(.title)
                    .foregroundStyle(Color.textPrimary)
                Text(L10n.tvSigningInSubtitle)
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)
            }
            if let title = model.title {
                Text(title)
            }
            Spacer()
            podcastGrid
            Spacer().frame(height: 220)
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
        HStack(spacing: Layout.gridSpacing) {
            ForEach(0..<max(model.totalPodcastsToImport, 0), id: \.self) { index in
                podcastSlot(at: index)
            }
        }
    }

    @ViewBuilder
    private func podcastSlot(at index: Int) -> some View {
        let isLoaded = index < model.podcasts.count
        ZStack {
            Color.clear
            if isLoaded {
                PodcastImage(uuid: model.podcasts[index].uuid, size: .page)
                    .transition(.opacity.animation(.easeInOut(duration: Layout.fadeDuration)))
            }
        }
        .frame(width: Layout.gridSize, height: Layout.gridSize)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
    }
}

#Preview {
    SigningInView(model: SigningInViewModelMock())
        .environment(AppCoordinator())
}
