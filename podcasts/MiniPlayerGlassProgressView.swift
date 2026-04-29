import UIKit

final class MiniPlayerGlassProgressView: UIView {
    var playbackProgress: CGFloat = 0 {
        didSet {
            if playbackProgress != oldValue { setNeedsLayout() }
        }
    }

    var tintColorOverride: UIColor = .black {
        didSet { playbackLayer.backgroundColor = tintColorOverride.cgColor }
    }

    private let trackLayer = CALayer()
    private let playbackLayer = CALayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(trackLayer)
        layer.addSublayer(playbackLayer)
        trackLayer.backgroundColor = UIColor.gray.withAlphaComponent(0.3).cgColor
        playbackLayer.backgroundColor = tintColorOverride.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let width = bounds.width
        let height = bounds.height
        let radius = height / 2

        trackLayer.frame = bounds
        trackLayer.cornerRadius = radius

        let clampedPlayback = max(0, min(1, playbackProgress))
        playbackLayer.frame = CGRect(x: 0, y: 0, width: width * clampedPlayback, height: height)
        playbackLayer.cornerRadius = radius

        CATransaction.commit()
    }
}
