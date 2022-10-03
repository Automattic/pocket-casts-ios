import AVFoundation
import UIKit

class VideoPlayerView: UIView {
    var gravity = AVLayerVideoGravity.resizeAspect {
        didSet {
            playerLayer.videoGravity = gravity
        }
    }

    var player: AVPlayer? {
        didSet {
            playerLayer.player = player
        }
    }

    var videoSizeKnown: ((CGSize) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        listenForVideoSize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        listenForVideoSize()
    }

    private func listenForVideoSize() {
        playerLayer.addObserver(self, forKeyPath: "videoRect", options: .new, context: nil)
    }

    deinit {
        playerLayer.removeObserver(self, forKeyPath: "videoRect")
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "videoRect", playerLayer.videoRect.size != CGSize.zero else { return }

        if let videoSizeKnown = videoSizeKnown, player != nil {
            videoSizeKnown(playerLayer.videoRect.size)
        }
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }
}
