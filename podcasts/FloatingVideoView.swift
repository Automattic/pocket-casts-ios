
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

    private var videoWidthConstraint: NSLayoutConstraint!
    private var videoHeightConstraint: NSLayoutConstraint!
    private var videoSize: CGSize?
    private var lastSizeLayedOut: CGSize = .zero

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

        if lastSizeLayedOut == bounds.size { return }

        lastSizeLayedOut = bounds.size
        updateVideoViewSize()
    }

    private func setupView() {
        backgroundColor = UIColor.clear

        videoView.videoSizeKnown = { [weak self] videoSize in
            guard let strongSelf = self, strongSelf.videoSize != videoSize else { return }

            strongSelf.videoSize = videoSize
            strongSelf.updateVideoViewSize()
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

        videoWidthConstraint = videoView.widthAnchor.constraint(equalToConstant: bounds.width)
        videoHeightConstraint = videoView.heightAnchor.constraint(equalToConstant: bounds.height)
        NSLayoutConstraint.activate([
            videoView.centerXAnchor.constraint(equalTo: centerXAnchor),
            videoView.centerYAnchor.constraint(equalTo: centerYAnchor),
            videoWidthConstraint,
            videoHeightConstraint
        ])
        shadowView.anchorToAllSidesOf(view: videoView)
    }

    private func updateVideoViewSize() {
        guard bounds.width > 0, bounds.height > 0 else { return }

        let fittedSize: CGSize
        if let videoSize, videoSize.width > 0, videoSize.height > 0 {
            fittedSize = AVMakeRect(aspectRatio: videoSize, insideRect: bounds).size
        } else {
            fittedSize = bounds.size
        }

        videoWidthConstraint.constant = fittedSize.width
        videoHeightConstraint.constant = fittedSize.height
    }
}
