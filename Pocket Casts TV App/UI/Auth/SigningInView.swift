import SwiftUI
import Combine

@Observable
class SigningInViewModel {
    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case waiting
        case finished
    }
    var state: State = .waiting

    var podcasts: [MockPodcast] = MockData.makePodcasts()

    func sync() {
        cancellable = Timer.publish(every: 5.0, on: .main, in: .common)
                    .autoconnect()
                    .sink { [weak self] _ in
                        guard let self else { return }
                        state = .finished
                    }
    }
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
        .task {
            model.sync()
        }
        .onChange(of: model.state) {
            viewModel.state = .signedIn
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
