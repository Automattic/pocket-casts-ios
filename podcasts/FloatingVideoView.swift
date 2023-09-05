
import AVFoundation
import UIKit

class FloatingVideoView: UIView {
    private let shadowView = UIView()
    private let videoView = VideoPlayerView()

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

        setupView()
    }

    private func setupView() {
        shadowView.removeFromSuperview()
        videoView.removeFromSuperview()

        backgroundColor = UIColor.clear

        videoView.videoSizeKnown = { [weak self] videoSize in
            guard let strongSelf = self, !strongSelf.videoHeightSet else { return }

            strongSelf.videoHeightSet = true

            let aspectRatio = videoSize.width / videoSize.height
            let currentHeight = strongSelf.videoView.bounds.height
            let newHeight = aspectRatio >= 1 ? aspectRatio * currentHeight : currentHeight

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
    }
}
