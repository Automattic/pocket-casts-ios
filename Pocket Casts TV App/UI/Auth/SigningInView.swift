import SwiftUI
import Observation
import PocketCastsDataModel
import Kingfisher

fileprivate enum Layout {
    static let coverSize = CGFloat(272)
    static let cornerRadius = CGFloat(16)
    static let minRotation = 2.0
    static let maxRotation = 10.0
}

fileprivate enum Pacing {
    /// Minimum covers shown before we hand off, so a fast sync still reads as an animation.
    static let minCoversToShow = 6
    static let maxSimultaneous = 2
    static let stepInterval: Double = 0.8
    /// Fine-grained poll used before the first podcast has synced, so the first cover lands ASAP.
    static let warmUpInterval: Double = 0.1
    static let fadeDuration: Double = 0.6
    /// How many upcoming covers to keep mounted (hidden, loading) ahead of being shown.
    static let prefetchAhead = 3
    /// Upper bound on waiting for a cover's artwork, so a slow image never stalls the stack.
    static let maxPreloadWait: Double = 1.5
}

fileprivate struct StackedCover: Identifiable {
    /// Monotonic insertion id so the same podcast can appear more than once
    /// (when a small library is recycled) without colliding in `ForEach`.
    let id: Int
    let podcast: Podcast
    let rotation: Double
    /// Set once the artwork finishes loading (reported by the image view).
    var isLoaded = false
    /// Covers are mounted (and start loading) while hidden, then revealed once
    /// their artwork is ready.
    var isRevealed = false
}

struct SigningInView<ViewModel: SigningInViewModelProtocol>: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var model: ViewModel
    /// Mounted covers — both those warming up (hidden, loading) and those revealed.
    @State private var covers: [StackedCover] = []
    @State private var nextCoverID: Int = 0
    @State private var podcastCursor: Int = 0
    @State private var revealedCount: Int = 0
    @State private var blackOverlayOpaque = true

    init(model: ViewModel = SigningInViewModel()) {
        self.model = model
    }

    var body: some View {
        ZStack {
            VStack(spacing: 96) {
                Spacer()
                VStack(spacing: 16) {
                    Text(L10n.tvSigningInTitleNew)
                        .font(.title)
                        .foregroundStyle(Color.pcTextPrimary)
                    Text(L10n.tvSigningInSubtitle)
                        .font(.headline)
                        .foregroundStyle(Color.pcTextSecondary)
                }
                podcastGrid
                Spacer()
            }
            Color.pcBackgroundSunken
                .opacity(blackOverlayOpaque ? 1 : 0)
                .animation(reduceMotion ? nil : .smooth, value: blackOverlayOpaque)
                .allowsHitTesting(false)
                .ignoresSafeArea()
        }
        .task {
            Analytics.track(.signInSyncShown)
            await runSyncAnimation()
        }
    }

    @MainActor
    private func runSyncAnimation() async {
        model.sync()

        // Fade in from black so the QR/sign-in screen doesn't flash through.
        blackOverlayOpaque = false

        // Keep revealing covers until the underlying sync finishes. For large
        // libraries this runs well past the first batch, so the stack keeps
        // moving instead of freezing while the sync continues in the background.
        while !Task.isCancelled {
            // Mount the next few covers hidden so their artwork starts loading
            // ahead of being shown.
            replenishWarmingCovers()

            let next = covers.first(where: { !$0.isRevealed })
            let syncFinished = model.state == .finished
            let shownEnough = revealedCount >= Pacing.minCoversToShow

            // Done once the sync has finished and we've either shown enough covers
            // or run out of podcasts to reveal — the latter covers an empty account
            // and libraries smaller than `minCoversToShow`, which can never reach it.
            if syncFinished && (shownEnough || next == nil) {
                break
            }

            guard let next else {
                // Podcasts are still syncing in — poll quickly so the first cover
                // appears as soon as one is available rather than after a full step.
                try? await Task.sleep(for: .seconds(Pacing.warmUpInterval))
                continue
            }

            // The cover view is already mounted and loading; reveal it once its
            // artwork is ready so it animates in fully loaded instead of flashing
            // the placeholder, or after a timeout so a slow image never stalls us.
            await waitUntilLoaded(next.id)
            if Task.isCancelled { return }
            reveal(next.id)
            try? await Task.sleep(for: .seconds(Pacing.stepInterval))
        }
        if Task.isCancelled { return }

        // Fade the whole screen to black before handing off to the home view.
        blackOverlayOpaque = true
        try? await Task.sleep(for: .seconds(Pacing.fadeDuration))
        if Task.isCancelled { return }

        coordinator.state = .signedIn
    }

    /// Mounts upcoming covers (hidden) so they begin loading before they're shown,
    /// cycling back through already-synced podcasts when the sync hasn't produced
    /// new ones yet so the stack never stalls.
    private func replenishWarmingCovers() {
        let podcasts = model.podcasts
        guard !podcasts.isEmpty else { return }
        var needed = Pacing.prefetchAhead - covers.filter { !$0.isRevealed }.count
        while needed > 0, let podcast = takeNextDistinctPodcast(from: podcasts) {
            let sign: Double = nextCoverID.isMultiple(of: 2) ? -1 : 1
            let rotation = sign * Double.random(in: Layout.minRotation...Layout.maxRotation)
            covers.append(StackedCover(id: nextCoverID, podcast: podcast, rotation: rotation))
            nextCoverID += 1
            needed -= 1
        }
    }

    /// Advances the cursor to the next podcast that isn't already on screen, cycling
    /// through the list so covers progress and never duplicate a visible one. Returns
    /// nil when every synced podcast is currently mounted (e.g. a tiny library that
    /// hasn't finished syncing), in which case we simply wait for more to arrive.
    private func takeNextDistinctPodcast(from podcasts: [Podcast]) -> Podcast? {
        let mounted = Set(covers.map { $0.podcast.uuid })
        for _ in 0..<podcasts.count {
            let candidate = podcasts[podcastCursor % podcasts.count]
            podcastCursor += 1
            if !mounted.contains(candidate.uuid) {
                return candidate
            }
        }
        return nil
    }

    /// Waits until the cover's artwork has loaded (reported by the image view),
    /// or until `maxPreloadWait` elapses so a slow image never freezes the stack.
    private func waitUntilLoaded(_ id: Int) async {
        var elapsed = 0.0
        while covers.first(where: { $0.id == id })?.isLoaded != true,
              elapsed < Pacing.maxPreloadWait,
              !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Pacing.warmUpInterval))
            elapsed += Pacing.warmUpInterval
        }
    }

    private func markLoaded(_ id: Int) {
        guard let index = covers.firstIndex(where: { $0.id == id }) else { return }
        covers[index].isLoaded = true
    }

    /// Reveals the cover and retires the oldest ones beyond `maxSimultaneous`.
    private func reveal(_ id: Int) {
        guard let index = covers.firstIndex(where: { $0.id == id }) else { return }
        covers[index].isRevealed = true
        revealedCount += 1

        let revealed = covers.filter(\.isRevealed)
        guard revealed.count > Pacing.maxSimultaneous else { return }
        let stale = Set(revealed.dropLast(Pacing.maxSimultaneous).map(\.id))
        covers.removeAll { stale.contains($0.id) }
    }

    private func imageURL(for podcast: Podcast) -> URL {
        ImageManager.sharedManager.podcastUrl(imageSize: .page, uuid: podcast.uuid)
    }

    var podcastGrid: some View {
        ZStack {
            ForEach(covers) { cover in
                coverImage(for: cover)
                    .frame(width: Layout.coverSize, height: Layout.coverSize)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
                    .scaleEffect(scale(for: cover))
                    .rotationEffect(.degrees(rotation(for: cover)))
                    .opacity(cover.isRevealed ? 1 : 0)
                    .animation(revealAnimation, value: cover.isRevealed)
                    // Covers are revealed in place; only their removal needs a transition.
                    .transition(.asymmetric(insertion: .identity, removal: .opacity.animation(.easeOut(duration: 0.5))))
                    .accessibilityHidden(true)
            }
        }
        .frame(width: Layout.coverSize, height: Layout.coverSize)
    }

    /// The displayed image view also drives loading: it starts fetching as soon as
    /// the cover is mounted (while hidden) and reports completion so the cover can
    /// be revealed once its artwork is ready.
    private func coverImage(for cover: StackedCover) -> some View {
        KFImage(imageURL(for: cover.podcast))
            .placeholder { _ in
                if let placeholder = ImageManager.sharedManager.placeHolderImage(.page) {
                    Image(uiImage: placeholder)
                        .resizable()
                }
            }
            .onSuccess { _ in markLoaded(cover.id) }
            .onFailure { _ in markLoaded(cover.id) }
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    private func scale(for cover: StackedCover) -> CGFloat {
        if reduceMotion { return 1 }
        return cover.isRevealed ? 1 : 0.6
    }

    private func rotation(for cover: StackedCover) -> Double {
        if reduceMotion { return cover.rotation }
        return cover.isRevealed ? cover.rotation : 0
    }

    private var revealAnimation: Animation {
        reduceMotion
            ? .easeInOut(duration: 0.4)
            : .interpolatingSpring(stiffness: 220, damping: 14)
    }
}

#Preview {
    SigningInView(model: SigningInViewModelMock())
        .environment(AppCoordinator())
}
