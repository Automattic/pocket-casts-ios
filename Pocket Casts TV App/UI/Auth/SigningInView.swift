import SwiftUI
import PocketCastsDataModel

fileprivate enum Layout {
    static let coverSize = CGFloat(272)
    static let qrSize = CGFloat(240)
    static let cornerRadius = CGFloat(16)
    static let minRotation = 2.0
    static let maxRotation = 10.0
}

fileprivate enum Pacing {
    static let totalCoversToShow = 8
    static let maxSimultaneous = 2
    static let stepInterval: Double = 0.8
    static let fadeDuration: Double = 0.6
}

fileprivate struct StackedCover: Identifiable {
    let podcast: Podcast
    let rotation: Double
    var id: String { podcast.uuid }
}

struct SigningInView<ViewModel: SigningInViewModelProtocol>: View {
    @Environment(AppCoordinator.self) var coordinator

    @State private var model: ViewModel
    @State private var displayedCovers: [StackedCover] = []
    @State private var nextIndex: Int = 0
    @State private var blackOverlayOpaque = true

    init(model: ViewModel = SigningInViewModel()) {
        self.model = model
    }

    var body: some View {
        ZStack {
            VStack(spacing: 96) {
                Spacer()
                VStack(spacing: 16) {
                    Text(L10n.tvSigningInTitle)
                        .font(.title)
                        .foregroundStyle(Color.textPrimary)
                    Text(L10n.tvSigningInSubtitle)
                        .font(.headline)
                        .foregroundStyle(Color.textSecondary)
                }
                podcastGrid
                Spacer()
            }
            Color.black
                .opacity(blackOverlayOpaque ? 1 : 0)
                .animation(.easeInOut(duration: Pacing.fadeDuration), value: blackOverlayOpaque)
                .allowsHitTesting(false)
                .ignoresSafeArea()
        }
        .task {
            await runSyncAnimation()
        }
    }

    private func runSyncAnimation() async {
        model.sync()

        // Fade in from black so the QR/sign-in screen doesn't flash through.
        blackOverlayOpaque = false

        let stepNanoseconds = UInt64(Pacing.stepInterval * 1_000_000_000)

        for _ in 0..<Pacing.totalCoversToShow {
            try? await Task.sleep(nanoseconds: stepNanoseconds)
            guard nextIndex < model.podcasts.count else { continue }
            let podcast = model.podcasts[nextIndex]
            let sign: Double = nextIndex.isMultiple(of: 2) ? -1 : 1
            let rotation = sign * Double.random(in: Layout.minRotation...Layout.maxRotation)
            nextIndex += 1
            if displayedCovers.count >= Pacing.maxSimultaneous {
                displayedCovers.removeFirst()
            }
            displayedCovers.append(StackedCover(podcast: podcast, rotation: rotation))
        }

        // Wait for the underlying sync to finish before moving on.
        while model.state != .finished {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        // Fade the whole screen to black before handing off to the home view.
        blackOverlayOpaque = true
        try? await Task.sleep(nanoseconds: UInt64(Pacing.fadeDuration * 1_000_000_000))

        coordinator.state = .signedIn
    }

    var podcastGrid: some View {
        ZStack {
            ForEach(displayedCovers) { cover in
                PodcastImage(uuid: cover.podcast.uuid, size: .page)
                    .frame(width: Layout.coverSize, height: Layout.coverSize)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
                    .rotationEffect(.degrees(cover.rotation))
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.6)
                            .combined(with: .opacity)
                            .animation(.interpolatingSpring(stiffness: 220, damping: 14)),
                        removal: .opacity.animation(.easeOut(duration: 0.5))
                    ))
            }
        }
        .frame(width: Layout.coverSize, height: Layout.coverSize)
    }
}

#Preview {
    SigningInView(model: SigningInViewModelMock())
        .environment(AppCoordinator())
}
