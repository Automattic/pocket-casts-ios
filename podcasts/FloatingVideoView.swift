import AVFoundation
import UIKit

class FloatingVideoView: UIView {
    private static let fullScreenButtonSize: CGFloat = 36
    private static let fullScreenButtonInset: CGFloat = 8

    private let shadowView = UIView()
    private let videoView = VideoPlayerView()

    var onFullScreenTapped: (() -> Void)?

    var player: AVPlayer? {
        didSet {
            videoView.player = player
        }
    }

    private var videoHeightConstraint: NSLayoutConstraint!
    private var videoHeightSet = false
    private var lastWidthLayedOut: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if lastWidthLayedOut == bounds.width { return }

        lastWidthLayedOut = bounds.width
        videoHeightSet = false
    }

    private func setupView() {
        backgroundColor = UIColor.clear

        videoView.videoSizeKnown = { [weak self] videoSize in
            guard let strongSelf = self, !strongSelf.videoHeightSet else { return }

            strongSelf.videoHeightSet = true

            let aspectRatio = videoSize.height / videoSize.width
            let currentWidth = strongSelf.videoView.bounds.width
            let newHeight = aspectRatio * currentWidth
            strongSelf.videoHeightConstraint.constant = newHeight
        }

        // setup shadow
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 1)
        shadowView.layer.shadowOpacity = 0.1
        shadowView.layer.shadowRadius = 8
        shadowView.layer.cornerRadius = 8
        shadowView.layer.masksToBounds = false
        shadowView.backgroundColor = UIColor.black.withAlphaComponent(0.1)

        // setup video view
        videoView.translatesAutoresizingMaskIntoConstraints = false
        videoView.clipsToBounds = true
        videoView.layer.cornerRadius = 8
        videoView.layer.masksToBounds = true
        videoView.backgroundColor = UIColor.clear

        addSubview(shadowView)
        addSubview(videoView)

        videoHeightConstraint = videoView.heightAnchor.constraint(equalToConstant: bounds.height)
        NSLayoutConstraint.activate([
            videoView.leadingAnchor.constraint(equalTo: leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: trailingAnchor),
            videoView.centerYAnchor.constraint(equalTo: centerYAnchor),
            videoHeightConstraint
        ])
        shadowView.anchorToAllSidesOf(view: videoView)

        #if !APPCLIP
            setupFullScreenButton()
        #endif
    }

    #if !APPCLIP
        private lazy var fullScreenButton: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(UIImage(named: "fullscreen-video"), for: .normal)
            button.tintColor = UIColor.white
            button.accessibilityLabel = L10n.playerVideoFullScreen
            button.addTarget(self, action: #selector(fullScreenButtonTapped), for: .touchUpInside)

            return button
        }()

        private lazy var fullScreenButtonBackground: UIVisualEffectView = {
            let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.layer.cornerRadius = Self.fullScreenButtonSize / 2
            backgroundView.clipsToBounds = true

            return backgroundView
        }()

        private func setupFullScreenButton() {
            addSubview(fullScreenButtonBackground)
            fullScreenButtonBackground.contentView.addSubview(fullScreenButton)
            fullScreenButton.anchorToAllSidesOf(view: fullScreenButtonBackground.contentView)

            // Keep the button inside our bounds for videos taller than the space we have, otherwise
            // it would sit outside the area that receives touches.
            let bottomInsideBounds = fullScreenButtonBackground.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.fullScreenButtonInset)
            bottomInsideBounds.priority = .defaultHigh

            NSLayoutConstraint.activate([
                fullScreenButtonBackground.widthAnchor.constraint(equalToConstant: Self.fullScreenButtonSize),
                fullScreenButtonBackground.heightAnchor.constraint(equalToConstant: Self.fullScreenButtonSize),
                fullScreenButtonBackground.trailingAnchor.constraint(equalTo: videoView.trailingAnchor, constant: -Self.fullScreenButtonInset),
                fullScreenButtonBackground.bottomAnchor.constraint(lessThanOrEqualTo: videoView.bottomAnchor, constant: -Self.fullScreenButtonInset),
                bottomInsideBounds
            ])
        }

        @objc private func fullScreenButtonTapped() {
            onFullScreenTapped?()
        }
    #endif
}
