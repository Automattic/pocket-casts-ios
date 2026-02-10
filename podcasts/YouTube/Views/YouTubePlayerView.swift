import SafariServices
import SwiftUI
import UIKit

/// A view that plays YouTube videos using SFSafariViewController
/// This is the most reliable way to play YouTube videos in-app since
/// YouTube blocks playback in regular WKWebViews
struct YouTubePlayerView: View {
    let video: YouTubeVideo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SafariVideoPlayer(url: video.watchURL ?? URL(string: "https://youtube.com")!)
            .ignoresSafeArea()
            .onAppear {
                Analytics.track(.youTubeVideoOpened, properties: [
                    "feed_id": video.feedId,
                    "video_id": video.id
                ])
            }
    }
}

/// UIViewControllerRepresentable wrapper for SFSafariViewController
struct SafariVideoPlayer: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true

        let safari = SFSafariViewController(url: url, configuration: config)
        safari.preferredControlTintColor = .systemRed
        safari.dismissButtonStyle = .done

        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

/// Alternative: Open directly in YouTube app or Safari
struct YouTubeVideoOpener {
    /// Try to open in YouTube app, fall back to Safari
    static func openVideo(_ video: YouTubeVideo, from viewController: UIViewController? = nil) {
        guard let watchURL = video.watchURL else { return }

        // Try YouTube app first
        let youtubeAppURL = URL(string: "youtube://\(video.id)")!
        if UIApplication.shared.canOpenURL(youtubeAppURL) {
            UIApplication.shared.open(youtubeAppURL)
        } else if let vc = viewController {
            // Use SFSafariViewController for in-app experience
            let safari = SFSafariViewController(url: watchURL)
            safari.preferredControlTintColor = .systemRed
            vc.present(safari, animated: true)
        } else {
            // Fall back to opening in Safari
            UIApplication.shared.open(watchURL)
        }

        Analytics.track(.youTubeVideoOpened, properties: [
            "feed_id": video.feedId,
            "video_id": video.id
        ])
    }
}

/// UIKit view controller wrapper for presenting the player
class YouTubePlayerViewController: UIViewController {
    private let video: YouTubeVideo
    private var safariVC: SFSafariViewController?

    init(video: YouTubeVideo) {
        self.video = video
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let url = video.watchURL else {
            dismiss(animated: true)
            return
        }

        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true

        let safari = SFSafariViewController(url: url, configuration: config)
        safari.preferredControlTintColor = .systemRed
        safari.dismissButtonStyle = .done
        safari.delegate = self

        addChild(safari)
        view.addSubview(safari.view)
        safari.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            safari.view.topAnchor.constraint(equalTo: view.topAnchor),
            safari.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            safari.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            safari.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        safari.didMove(toParent: self)

        safariVC = safari

        Analytics.track(.youTubeVideoOpened, properties: [
            "feed_id": video.feedId,
            "video_id": video.id
        ])
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .allButUpsideDown
    }
}

extension YouTubePlayerViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true)
    }
}

// MARK: - Preview

#Preview {
    YouTubePlayerView(video: YouTubeVideo.preview())
}
