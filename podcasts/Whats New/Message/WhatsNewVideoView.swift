import AVFoundation
import PocketCastsServer
import SwiftUI
import UIKit

/// A short demo video, muted and looping, over the poster the catalog published.
///
/// The poster sits under the video layer, which draws nothing until a frame is ready, so a video
/// that hasn't started — or that never loads — leaves the poster on screen.
struct WhatsNewVideoView: View {
    @EnvironmentObject private var theme: Theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var player: WhatsNewVideoPlayer

    let video: WhatsNewVideo
    let contentSize: CGSize

    /// Whether the page the video is on is the one on screen, so it stops when it's swiped away.
    let isVisible: Bool

    init(video: WhatsNewVideo, contentSize: CGSize, isVisible: Bool) {
        self.video = video
        self.contentSize = contentSize
        self.isVisible = isVisible
        _player = StateObject(wrappedValue: WhatsNewVideoPlayer(video: video))
    }

    var body: some View {
        let size = WhatsNewMediaLayout.size(aspectRatio: player.aspectRatio, in: contentSize)

        Button {
            player.toggle()
        } label: {
            ZStack {
                poster
                WhatsNewVideoLayerView(player: player.player)
                caption
                playIndicator
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(video.alt ?? L10n.whatsNewMessageVideo)
        .accessibilityAddTraits(.startsMediaSession)
        .onAppear { updatePlayback() }
        .onDisappear { player.tearDown() }
        .onChange(of: isVisible) { _, _ in updatePlayback() }
    }

    @ViewBuilder
    private var poster: some View {
        theme.primaryUi05

        if let posterUrl = video.posterUrl {
            // The poster keeps its own shape and fills the frame the video will play in.
            AsyncImageView(url: posterUrl,
                           cache: ImageManager.sharedManager.discoverCache,
                           aspectRatio: nil,
                           contentMode: .fill)
        }
    }

    /// What's being said right now, when the catalog published captions to say it with.
    @ViewBuilder
    private var caption: some View {
        if let caption = player.caption {
            VStack {
                Spacer(minLength: 0)

                Text(caption)
                    .font(size: 13, style: .footnote)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 4))
                    .padding(8)
            }
        }
    }

    /// Shown while the video is stopped, both as a hint that it plays and as something to aim at.
    @ViewBuilder
    private var playIndicator: some View {
        if !player.isPlaying {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 44))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .black.opacity(0.4))
        }
    }

    /// Plays the video while it's on screen, unless the user has asked the system to hold back on
    /// movement or is saving battery, in which case the poster waits for a tap instead.
    private func updatePlayback() {
        guard isVisible else {
            player.stop()
            return
        }
        guard !reduceMotion, !ProcessInfo.processInfo.isLowPowerModeEnabled else { return }
        player.play()
    }
}

/// Drives the `AVPlayer` behind a video block.
@MainActor
private final class WhatsNewVideoPlayer: ObservableObject {
    /// Whether the video is running, read from the player rather than from the last call into it,
    /// so a pause the app didn't ask for — backgrounding, an interruption — still shows the play
    /// button and takes a single tap to get going again.
    @Published private(set) var isPlaying = false

    @Published private(set) var caption: String?

    /// The video's shape, which starts at the widescreen these demos are recorded in and settles on
    /// whatever the asset turns out to be.
    @Published private(set) var aspectRatio: CGFloat = 16 / 9

    let player = AVPlayer()

    /// Whether the video was last asked to play, which is what the loop turns on rather than the
    /// player's own state: it's momentarily not playing at the end of every pass.
    private var shouldPlay = false

    private let video: WhatsNewVideo
    private var captions: WhatsNewVideoCaptions?
    private var timeObserver: Any?
    private var endObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var playbackObservation: NSKeyValueObservation?
    private var preparation: Task<Void, Never>?

    init(video: WhatsNewVideo) {
        self.video = video

        // The app is usually playing a podcast, and a demo has nothing to say over the top of it.
        // The audio is taken off the item as well, since muting alone still claims the session.
        player.isMuted = true
        player.allowsExternalPlayback = false
        player.preventsDisplaySleepDuringVideoPlayback = false
        // Looping is a seek back to the start, so the player is never asked to stop at the end and
        // never drops out of playing between passes.
        player.actionAtItemEnd = .none

        playbackObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { player, _ in
            let isPlaying = player.timeControlStatus != .paused
            Task { @MainActor [weak self] in self?.isPlaying = isPlaying }
        }
    }

    func play() {
        shouldPlay = true

        guard player.currentItem == nil else {
            player.play()
            return
        }
        prepare()
    }

    func stop() {
        shouldPlay = false
        player.pause()
    }

    func toggle() {
        isPlaying ? stop() : play()
    }

    /// AVFoundation traps on a player deallocated with a time observer still on it, and going away
    /// without the page disappearing first — a scene disconnect, say — never reaches `tearDown()`.
    deinit {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }

    /// Puts the player back to how it started, so nothing is left loaded behind a page the reader
    /// has moved on from. Playing again loads it back.
    func tearDown() {
        stop()
        removeObservers()

        preparation?.cancel()
        preparation = nil
        statusObservation = nil
        caption = nil
        player.replaceCurrentItem(with: nil)
    }

    private func removeObservers() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        timeObserver = nil
        endObserver = nil
    }

    /// Loads the video the first time it's asked to play, so a page nobody swipes to fetches nothing.
    ///
    /// Nothing starts until the audio is off the item, since the point of the delay is to keep the
    /// player from ever asking for the audio session.
    private func prepare() {
        guard preparation == nil, let source = video.sources.first else { return }

        preparation = Task {
            let item = await silencedItem(for: source.url)
            guard !Task.isCancelled else { return }

            observe(item)
            player.replaceCurrentItem(with: item)
            preparation = nil

            if shouldPlay {
                player.play()
            }

            await loadAspectRatio()

            if let captionsUrl = video.captionsUrl {
                await loadCaptions(from: captionsUrl)
            }
        }
    }

    /// The video with its audio left out rather than turned down.
    ///
    /// A muted player still activates the shared audio session, which interrupts whatever the
    /// reader has playing in another app — the very thing muting is here to avoid. A stream is
    /// silenced by deselecting the audio it offers, a file by playing a copy of its video track
    /// alone.
    private func silencedItem(for url: URL) async -> AVPlayerItem {
        let asset = AVURLAsset(url: url)

        if let videoOnly = await videoOnlyCopy(of: asset) {
            return AVPlayerItem(asset: videoOnly)
        }

        let item = AVPlayerItem(asset: asset)
        if let audible = try? await asset.loadMediaSelectionGroup(for: .audible) {
            item.select(nil, in: audible)
        }
        return item
    }

    /// The asset's video track on its own, or `nil` for a stream, whose tracks aren't there to copy
    /// and which has media selection to turn its audio off with instead.
    private func videoOnlyCopy(of asset: AVURLAsset) async -> AVAsset? {
        guard let source = try? await asset.loadTracks(withMediaType: .video).first,
              let duration = try? await asset.load(.duration) else { return nil }

        let composition = AVMutableComposition()
        guard let track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              (try? track.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: source, at: .zero)) != nil
        else { return nil }

        // A copied track starts square-on, which would turn a video recorded on its side.
        if let transform = try? await source.load(.preferredTransform) {
            track.preferredTransform = transform
        }

        return composition
    }

    private func observe(_ item: AVPlayerItem) {
        endObserver = NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification,
                                                            object: item,
                                                            queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.replay() }
        }

        // A video that can't be played leaves the poster up, with the play button back for a retry.
        // The failed item goes with it, or the retry would find it still loaded and play nothing.
        statusObservation = item.observe(\.status) { [weak self] item, _ in
            guard item.status == .failed else { return }
            Task { @MainActor in self?.tearDown() }
        }
    }

    private func replay() {
        player.seek(to: .zero)
        guard shouldPlay else { return }
        player.play()
    }

    private func loadAspectRatio() async {
        guard let asset = player.currentItem?.asset,
              let track = try? await asset.loadTracks(withMediaType: .video).first,
              let size = try? await track.load(.naturalSize),
              let transform = try? await track.load(.preferredTransform)
        else { return }

        let displayed = CGRect(origin: .zero, size: size).applying(transform)
        guard displayed.width != 0, displayed.height != 0 else { return }

        aspectRatio = abs(displayed.width / displayed.height)
    }

    private func loadCaptions(from url: URL) async {
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let captions = WhatsNewVideoCaptions(data: data)
        else { return }

        self.captions = captions
        observeTime()
    }

    private func observeTime() {
        guard timeObserver == nil else { return }

        let interval = CMTime(seconds: 0.2, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.caption = self.captions?.text(at: time.seconds)
            }
        }
    }
}

/// Draws an `AVPlayer` with no controls of its own, since tapping the block is what plays it.
private struct WhatsNewVideoLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> VideoPlayerView {
        let view = VideoPlayerView()
        view.backgroundColor = .clear
        view.gravity = .resizeAspect
        view.player = player
        return view
    }

    func updateUIView(_ view: VideoPlayerView, context: Context) {
        view.player = player
    }
}

// MARK: - Previews

private extension WhatsNewVideo {
    /// A block pointing at Apple's public sample stream, so the video can be previewed on its own
    /// without going through a message.
    static var previewSample: WhatsNewVideo {
        let json = """
        {
          "type": "video",
          "sources": [
            { "url": "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8", "mimeType": "application/x-mpegURL" }
          ],
          "alt": "A sample video"
        }
        """
        return try! JSONDecoder().decode(WhatsNewVideo.self, from: Data(json.utf8))
    }
}

#Preview("A video block") {
    WhatsNewVideoView(video: .previewSample, contentSize: CGSize(width: 340, height: 600), isVisible: true)
        .setupDefaultEnvironment()
}

#Preview("A video block, stopped") {
    WhatsNewVideoView(video: .previewSample, contentSize: CGSize(width: 340, height: 600), isVisible: false)
        .setupDefaultEnvironment()
}
