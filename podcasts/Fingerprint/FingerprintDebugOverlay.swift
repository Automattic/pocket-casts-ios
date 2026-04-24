#if DEBUG
import UIKit

class FingerprintDebugOverlay: UIView {

    private var entries: [FingerprintTimingManager.TimeMappingEntry] = []
    private var rejections: [FingerprintTimingManager.TimeMappingEntry] = []
    private var totalDuration: Double = 0
    private var playbackPosition: Double = 0

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 9, weight: .semibold)
        label.textColor = .white
        // swiftlint:disable:next inverse_text_alignment
        label.textAlignment = .right
        label.shadowColor = .black
        label.shadowOffset = CGSize(width: 0, height: 1)
        label.isUserInteractionEnabled = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        layer.cornerRadius = 4
        clipsToBounds = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
        addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update() {
        entries = FingerprintTimingManager.shared.debugMappingSnapshot()
        rejections = FingerprintTimingManager.shared.debugRejectionsSnapshot()
        // Fingerprint generation may not have started yet (no context → nil duration).
        // Fall back to the episode's duration so the playback cursor and tap-to-seek
        // work regardless of fingerprint state.
        let fingerprintDuration = FingerprintTimingManager.shared.totalDuration ?? 0
        totalDuration = fingerprintDuration > 0 ? fingerprintDuration : PlaybackManager.shared.duration()
        playbackPosition = PlaybackManager.shared.currentTime()
        statusLabel.text = describe(state: FingerprintTimingManager.shared.state)
        setNeedsDisplay()
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard totalDuration > 0, bounds.width > 0 else { return }
        let x = gesture.location(in: self).x
        let time = Double(x / bounds.width) * totalDuration
        PlaybackManager.shared.seekTo(time: min(max(0, time), totalDuration))
    }

    override func draw(_ rect: CGRect) {
        guard totalDuration > 0 else { return }

        let ctx = UIGraphicsGetCurrentContext()

        // Backdrop spanning the whole timeline so processed-vs-remaining is visible
        // as the full-file walk fills coverage in.
        ctx?.setFillColor(UIColor.darkGray.withAlphaComponent(0.5).cgColor)
        ctx?.fill(rect)

        // Rejected-candidate ticks at half-height on the bottom — "matcher fired
        // here but the drift filter dropped it as noise". Drawn underneath the
        // accepted-match bars so any accepted segment visually covers its slot.
        let tickHeight = rect.height / 2
        let tickY = rect.height - tickHeight
        for entry in rejections {
            let x = CGFloat(entry.playbackTime / totalDuration) * rect.width
            let tickWidth = max(CGFloat(1.0 / totalDuration) * rect.width, 1.5)
            ctx?.setFillColor(UIColor.systemPurple.withAlphaComponent(0.75).cgColor)
            ctx?.fill(CGRect(x: x, y: tickY, width: tickWidth, height: tickHeight))
        }

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

    private func describe(state: FingerprintTimingManager.State) -> String {
        switch state {
        case .idle: return "idle"
        case .preparing: return "preparing"
        case .active(let coverage): return "active (\(coverage))"
        case .failed: return "failed"
        case .unavailable: return "unavailable"
        }
    }
}
#endif
