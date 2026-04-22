#if DEBUG
import UIKit

class FingerprintDebugOverlay: UIView {

    private var entries: [FingerprintTimingManager.TimeMappingEntry] = []
    private var totalDuration: Double = 0
    private var playbackPosition: Double = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        layer.cornerRadius = 4
        clipsToBounds = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update() {
        entries = FingerprintTimingManager.shared.debugMappingSnapshot()
        totalDuration = FingerprintTimingManager.shared.totalDuration ?? 0
        playbackPosition = PlaybackManager.shared.currentTime()
        setNeedsDisplay()
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard totalDuration > 0 else { return }
        let x = gesture.location(in: self).x
        let time = Double(x / bounds.width) * totalDuration
        PlaybackManager.shared.seekTo(time: max(0, time))
    }

    override func draw(_ rect: CGRect) {
        guard totalDuration > 0 else { return }

        let ctx = UIGraphicsGetCurrentContext()

        for entry in entries {
            let x = CGFloat(entry.playbackTime / totalDuration) * rect.width
            let segmentWidth = max(CGFloat(2.0 / totalDuration) * rect.width, 2)

            let color: UIColor
            if entry.score >= FingerprintConstants.debugOverlayHighScoreThreshold {
                color = .systemGreen
            } else if entry.score >= FingerprintConstants.debugOverlayMediumScoreThreshold {
                color = .systemOrange
            } else {
                color = .systemRed
            }

            ctx?.setFillColor(color.cgColor)
            ctx?.fill(CGRect(x: x, y: 0, width: segmentWidth, height: rect.height))
        }

        if playbackPosition > 0 {
            let px = CGFloat(playbackPosition / totalDuration) * rect.width
            ctx?.setFillColor(UIColor.white.cgColor)
            ctx?.fill(CGRect(x: px - 1, y: 0, width: 2, height: rect.height))
        }
    }
}
#endif
