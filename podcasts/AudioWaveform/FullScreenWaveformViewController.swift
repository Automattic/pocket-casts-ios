import UIKit
import SwiftUI

/// Full-screen view controller that shows blurred artwork with animated waveform overlay
class FullScreenWaveformViewController: UIViewController {

    private let artwork: UIImage
    private let audioMeter = AudioMeterManager.shared

    private lazy var artworkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0.7
        return view
    }()

    private var waveformHostingController: UIHostingController<PlayerAudioWaveformView>?

    init(artwork: UIImage) {
        self.artwork = artwork
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupGestures()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        audioMeter.startMetering()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Don't stop metering here as it might still be needed by the player
    }

    private func setupUI() {
        view.backgroundColor = .black

        // Add artwork
        artworkImageView.image = artwork
        view.addSubview(artworkImageView)

        // Add blur overlay
        view.addSubview(blurView)

        // Setup waveform
        let primaryColor = Color(ThemeColor.playerContrast01())
        let highlightColor = Color(PlayerColorHelper.playerHighlightColor01(for: .dark))

        let waveformView = PlayerAudioWaveformView(
            audioMeter: audioMeter,
            barCount: 50,
            barWidth: 5,
            barSpacing: 5,
            primaryColor: primaryColor,
            secondaryColor: highlightColor
        )

        let hostingController = UIHostingController(rootView: waveformView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        waveformHostingController = hostingController

        // Setup constraints
        NSLayoutConstraint.activate([
            // Artwork fills the screen
            artworkImageView.topAnchor.constraint(equalTo: view.topAnchor),
            artworkImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            artworkImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            artworkImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Blur covers the artwork
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Waveform centered
            hostingController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hostingController.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            hostingController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4)
        ])
    }

    private func setupGestures() {
        // Tap to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissFullScreen))
        view.addGestureRecognizer(tapGesture)

        // Swipe down to dismiss
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissFullScreen))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
    }

    @objc private func dismissFullScreen() {
        dismiss(animated: true)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
