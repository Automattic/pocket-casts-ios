import UIKit

/// A horizontal bar that visualizes fingerprint matching confidence across the episode timeline.
/// - Black: no fingerprint data yet
/// - Green: high confidence (score >= 0.85)
/// - Orange: medium confidence (score >= 0.7)
/// - Red: low confidence (score < 0.7)
class FingerprintDebugOverlay: UIView {

    private var entries: [FingerprintTimingManager.TimeMappingEntry] = []
    private var totalDuration: Double = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        layer.cornerRadius = 4
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update() {
        entries = FingerprintTimingManager.shared.debugMappingSnapshot()
        totalDuration = FingerprintTimingManager.shared.totalDuration ?? 0
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard totalDuration > 0 else { return }

        let ctx = UIGraphicsGetCurrentContext()
        // Background is already black via backgroundColor

        for entry in entries {
            let x = CGFloat(entry.playbackTime / totalDuration) * rect.width
            let segmentWidth = max(CGFloat(2.0 / totalDuration) * rect.width, 2) // at least 2pt wide

            let color: UIColor
            if entry.score >= 0.85 {
                color = .systemGreen
            } else if entry.score >= 0.7 {
                color = .systemOrange
            } else {
                color = .systemRed
            }

            ctx?.setFillColor(color.cgColor)
            ctx?.fill(CGRect(x: x, y: 0, width: segmentWidth, height: rect.height))
        }
    }
}
