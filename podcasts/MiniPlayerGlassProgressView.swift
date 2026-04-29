import UIKit

final class MiniPlayerGlassProgressView: UIView {
    var playbackProgress: CGFloat = 0 {
        didSet {
            if playbackProgress != oldValue { setNeedsLayout() }
        }
    }

    var downloadProgress: CGFloat = 0 {
        didSet {
            if downloadProgress != oldValue { setNeedsLayout() }
        }
    }

    var tintColorOverride: UIColor = .black {
        didSet { applyColors() }
    }

    private let trackLayer = CALayer()
    private let downloadLayer = CALayer()
    private let playbackLayer = CALayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(trackLayer)
        layer.addSublayer(downloadLayer)
        layer.addSublayer(playbackLayer)
        applyColors()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func applyColors() {
        trackLayer.backgroundColor = tintColorOverride.withAlphaComponent(0.10).cgColor
        downloadLayer.backgroundColor = tintColorOverride.withAlphaComponent(0.25).cgColor
        playbackLayer.backgroundColor = tintColorOverride.cgColor
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

        let clampedDownload = max(0, min(1, downloadProgress))
        downloadLayer.frame = CGRect(x: 0, y: 0, width: width * clampedDownload, height: height)
        downloadLayer.cornerRadius = radius

        let clampedPlayback = max(0, min(1, playbackProgress))
        playbackLayer.frame = CGRect(x: 0, y: 0, width: width * clampedPlayback, height: height)
        playbackLayer.cornerRadius = radius

        CATransaction.commit()
    }
}
