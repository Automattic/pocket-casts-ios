import SwiftUI
import Observation
import PocketCastsDataModel

fileprivate enum Layout {
    static let coverSize = CGFloat(272)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                .animation(reduceMotion ? nil : .easeInOut(duration: Pacing.fadeDuration), value: blackOverlayOpaque)
                .allowsHitTesting(false)
                .ignoresSafeArea()
        }
        .task {
            await runSyncAnimation()
        }
    }

    @MainActor
    private func runSyncAnimation() async {
        model.sync()

        // Fade in from black so the QR/sign-in screen doesn't flash through.
        blackOverlayOpaque = false

        let stepNanoseconds = UInt64(Pacing.stepInterval * 1_000_000_000)

        for _ in 0..<Pacing.totalCoversToShow {
            try? await Task.sleep(nanoseconds: stepNanoseconds)
            if Task.isCancelled { return }
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
        await waitForSyncCompletion()
        if Task.isCancelled { return }

        // Fade the whole screen to black before handing off to the home view.
        blackOverlayOpaque = true
        try? await Task.sleep(nanoseconds: UInt64(Pacing.fadeDuration * 1_000_000_000))
        if Task.isCancelled { return }

        coordinator.state = .signedIn
    }

    @MainActor
    private func waitForSyncCompletion() async {
        guard model.state != .finished else { return }

        await withCheckedContinuation { continuation in
            observeSyncState(continuation: continuation)
        }
    }

    @MainActor
    private func observeSyncState(continuation: CheckedContinuation<Void, Never>) {
        withObservationTracking {
            _ = model.state
        } onChange: {
            Task { @MainActor in
                if model.state == .finished {
                    continuation.resume()
                } else {
                    observeSyncState(continuation: continuation)
                }
            }
        }
    }

    var podcastGrid: some View {
        ZStack {
            ForEach(displayedCovers) { cover in
                PodcastImage(uuid: cover.podcast.uuid, size: .page)
                    .frame(width: Layout.coverSize, height: Layout.coverSize)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
                    .rotationEffect(.degrees(cover.rotation))
                    .transition(coverTransition)
            }
        }
        .frame(width: Layout.coverSize, height: Layout.coverSize)
    }

    private var coverTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .scale(scale: 0.6)
                .combined(with: .opacity)
                .animation(.interpolatingSpring(stiffness: 220, damping: 14)),
            removal: .opacity.animation(.easeOut(duration: 0.5))
        )
    }
}

#Preview {
    SigningInView(model: SigningInViewModelMock())
        .environment(AppCoordinator())
}
