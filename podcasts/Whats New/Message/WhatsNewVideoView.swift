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
    @Published private(set) var isPlaying = false
    @Published private(set) var caption: String?

    /// The video's shape, which starts at the widescreen these demos are recorded in and settles on
    /// whatever the asset turns out to be.
    @Published private(set) var aspectRatio: CGFloat = 16 / 9

    let player = AVPlayer()

    private let video: WhatsNewVideo
    private var captions: WhatsNewVideoCaptions?
    private var timeObserver: Any?
    private var endObserver: Any?
    private var statusObservation: NSKeyValueObservation?

    init(video: WhatsNewVideo) {
        self.video = video

        // The app is usually playing a podcast, and a demo has nothing to say over the top of it.
        player.isMuted = true
        player.allowsExternalPlayback = false
        player.preventsDisplaySleepDuringVideoPlayback = false
    }

    func play() {
        prepareIfNeeded()
        guard player.currentItem != nil else { return }

        player.play()
        isPlaying = true
    }

    func stop() {
        player.pause()
        isPlaying = false
    }

    func toggle() {
        isPlaying ? stop() : play()
    }

    /// Puts the player back to how it started, so nothing is left loaded behind a page the reader
    /// has moved on from. Playing again loads it back.
    func tearDown() {
        stop()

        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        timeObserver = nil
        endObserver = nil
        statusObservation = nil
        caption = nil
        player.replaceCurrentItem(with: nil)
    }

    /// Loads the video the first time it's asked to play, so a page nobody swipes to fetches nothing.
    private func prepareIfNeeded() {
        guard player.currentItem == nil, let source = video.sources.first else { return }

        let item = AVPlayerItem(url: source.url)
        player.replaceCurrentItem(with: item)

        endObserver = NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification,
                                                            object: item,
                                                            queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.replay() }
        }

        // A video that can't be played leaves the poster up, with the play button back for a retry.
        statusObservation = item.observe(\.status) { [weak self] item, _ in
            guard item.status == .failed else { return }
            Task { @MainActor in self?.stop() }
        }

        Task { await loadAspectRatio() }

        if let captionsUrl = video.captionsUrl {
            Task { await loadCaptions(from: captionsUrl) }
        }
    }

    private func replay() {
        player.seek(to: .zero)
        guard isPlaying else { return }
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
    /// A block pointing at Apple's public sample stream, so the preview has something that plays:
    /// the mock catalog's media URLs are made up, like the rest of the fixture.
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
