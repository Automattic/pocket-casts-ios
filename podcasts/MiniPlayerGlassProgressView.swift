import SwiftUI
import UIKit

final class MiniPlayerGlassProgressView: UIView {
    var playbackProgress: CGFloat = 0 {
        didSet {
            if playbackProgress != oldValue { setNeedsLayout() }
        }
    }

    var bufferedAmount: CGFloat = 0 {
        didSet {
            guard bufferedAmount != oldValue else { return }
            setNeedsLayout()
            updateBufferColor()
        }
    }

    var indeterminate: Bool = false {
        didSet {
            guard indeterminate != oldValue else { return }
            updateBufferVisibility()
            indeterminateLayer.isHidden = !indeterminate
            if indeterminate {
                startIndeterminateAnimation()
            } else {
                indeterminateLayer.removeAllAnimations()
            }
        }
    }

    var tintColorOverride: UIColor = .black {
        didSet { applyTintColor() }
    }

    private let trackLayer = CALayer()
    private let playbackLayer = CALayer()
    private let bufferLayer = CALayer()
    private let indeterminateLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.masksToBounds = true
        layer.addSublayer(trackLayer)
        layer.addSublayer(bufferLayer)
        layer.addSublayer(playbackLayer)
        layer.addSublayer(indeterminateLayer)
        trackLayer.backgroundColor = MiniPlayerGlassProgressView.trackColor.cgColor
        bufferLayer.backgroundColor = MiniPlayerGlassProgressView.bufferColor.cgColor
        bufferLayer.isHidden = true
        indeterminateLayer.isHidden = true
        indeterminateLayer.startPoint = CGPoint(x: 0, y: 0.5)
        indeterminateLayer.endPoint = CGPoint(x: 1, y: 0.5)
        applyTintColor()
    }

    private static let trackColor = UIColor.gray.withAlphaComponent(0.28)
    private static let bufferColor = UIColor.gray.withAlphaComponent(0.30)

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

        layer.cornerRadius = radius
        trackLayer.frame = bounds
        trackLayer.cornerRadius = radius

        let clampedPlayback = max(0, min(1, playbackProgress))
        let progressWidth = width * clampedPlayback
        playbackLayer.frame = CGRect(x: 0, y: 0, width: progressWidth, height: height)
        playbackLayer.cornerRadius = radius

        updateBufferVisibility()
        if !bufferLayer.isHidden {
            let clampedBuffer = max(0, min(1, bufferedAmount))
            bufferLayer.frame = CGRect(x: 0, y: 0, width: width * clampedBuffer, height: height)
            bufferLayer.cornerRadius = radius
        }

        if indeterminate {
            if indeterminateLayer.animation(forKey: "shimmer") == nil {
                startIndeterminateAnimation()
            }
        }

        CATransaction.commit()
    }

    private func applyTintColor() {
        playbackLayer.backgroundColor = tintColorOverride.cgColor
        let edge = UIColor.white.withAlphaComponent(0).cgColor
        let peak = UIColor.white.withAlphaComponent(0.55).cgColor
        indeterminateLayer.colors = [edge, peak, edge]
        indeterminateLayer.locations = [0, 0.5, 1]
    }

    private func updateBufferVisibility() {
        bufferLayer.isHidden = indeterminate || bufferedAmount <= 0
    }

    private func updateBufferColor() {
        let target = bufferedAmount >= 1 ? Self.trackColor : Self.bufferColor
        let current = bufferLayer.backgroundColor
        guard current != target.cgColor else { return }

        let animation = CABasicAnimation(keyPath: "backgroundColor")
        animation.fromValue = current
        animation.toValue = target.cgColor
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        bufferLayer.add(animation, forKey: "bufferColorFade")
        bufferLayer.backgroundColor = target.cgColor
    }

    private func startIndeterminateAnimation() {
        indeterminateLayer.removeAllAnimations()

        let width = bounds.width
        let height = bounds.height
        guard width > 0, height > 0 else { return }

        let gradientWidth = width
        indeterminateLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        indeterminateLayer.bounds = CGRect(x: 0, y: 0, width: gradientWidth, height: height)
        indeterminateLayer.position = CGPoint(x: -gradientWidth / 2, y: height / 2)

        let animation = CABasicAnimation(keyPath: "position.x")
        animation.fromValue = -gradientWidth / 2
        animation.toValue = width + gradientWidth / 2
        animation.duration = 1.4
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.repeatCount = .greatestFiniteMagnitude
        indeterminateLayer.add(animation, forKey: "shimmer")
    }
}

private struct GlassProgressPreview: UIViewRepresentable {
    var progress: CGFloat = 0
    var bufferedAmount: CGFloat = 0
    var indeterminate: Bool = false
    var tint: UIColor = .systemPurple

    func makeUIView(context: Context) -> MiniPlayerGlassProgressView {
        MiniPlayerGlassProgressView()
    }

    func updateUIView(_ view: MiniPlayerGlassProgressView, context: Context) {
        view.tintColorOverride = tint
        view.playbackProgress = progress
        view.bufferedAmount = bufferedAmount
        view.indeterminate = indeterminate
    }
}

private struct GlassProgressPreviewRow<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.caption)
                .frame(width: 120, alignment: .leading)
            content()
                .frame(width: 44, height: 5)
        }
    }
}

#Preview("States") {
    VStack(alignment: .leading, spacing: 16) {
        GlassProgressPreviewRow(label: "Empty") {
            GlassProgressPreview(progress: 0)
        }
        GlassProgressPreviewRow(label: "40%") {
            GlassProgressPreview(progress: 0.4)
        }
        GlassProgressPreviewRow(label: "Complete") {
            GlassProgressPreview(progress: 1)
        }
        GlassProgressPreviewRow(label: "With buffer") {
            GlassProgressPreview(progress: 0.3, bufferedAmount: 0.5)
        }
        GlassProgressPreviewRow(label: "Buffer only") {
            GlassProgressPreview(progress: 0, bufferedAmount: 0.6)
        }
        GlassProgressPreviewRow(label: "Indeterminate") {
            GlassProgressPreview(indeterminate: true)
        }
        GlassProgressPreviewRow(label: "Custom tint") {
            GlassProgressPreview(progress: 0.6, tint: .systemOrange)
        }
    }
    .padding()
}

#Preview("Inline width") {
    VStack(alignment: .leading, spacing: 16) {
        GlassProgressPreview(progress: 0.4)
            .frame(width: 34, height: 5)
        GlassProgressPreview(progress: 0.4, bufferedAmount: 0.5)
            .frame(width: 34, height: 5)
        GlassProgressPreview(indeterminate: true)
            .frame(width: 34, height: 5)
    }
    .padding()
}
