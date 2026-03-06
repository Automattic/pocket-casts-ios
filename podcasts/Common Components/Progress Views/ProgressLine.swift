import UIKit

class ProgressLine: UIView {
    private static let sidePadding = 0 as CGFloat

    var indeterminant = false {
        didSet {
            progressLayer().shouldAnimate = indeterminant
        }
    }

    var showsBuffering = false {
        didSet {
            recalculatePositionRects(true)
        }
    }

    var progress: CGFloat = 0 {
        didSet {
            recalculatePositionRects(true)
        }
    }

    var buferredAmount: CGFloat = 0 {
        didSet {
            recalculatePositionRects(true)
        }
    }

    private let progressStyle: ThemeStyle = .playerHighlight01
    private let bufferStyle: ThemeStyle = .playerHighlight06
    private let bgTrackStyle: ThemeStyle = .playerHighlight07

    func updateColors() {
        let theme = Theme.sharedTheme.activeTheme
        backgroundColor = PlayerColorHelper.playerHighlightColor07(for: theme)
        progressLayer().bufferingColor = PlayerColorHelper.playerHighlightColor07(for: theme).cgColor
        progressLayer().progressColor = PlayerColorHelper.playerHighlightColor01(for: theme).cgColor

        progressLayer().setNeedsDisplay()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        recalculatePositionRects(false)
    }

    // MARK: - Position calculations

    private func recalculatePositionRects(_ animated: Bool) {
        let availableWidth = bounds.width - (ProgressLine.sidePadding * 2)
        let progressSize = progress * availableWidth
        let lineHeight = bounds.height

        if !animated {
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        }

        progressLayer().bgRect = CGRect(x: 0, y: 0, width: availableWidth, height: lineHeight)
        progressLayer().progressRect = CGRect(x: 0, y: 0, width: progressSize, height: lineHeight)
        if buferredAmount == 0 {
            progressLayer().bufferRect = CGRect.zero
        } else {
            progressLayer().bufferRect = CGRect(x: progressSize, y: 0, width: (availableWidth - progressSize) * buferredAmount, height: lineHeight)
        }

        if !animated {
            CATransaction.commit()
        }
    }

    // MARK: - Layer methods

    private func progressLayer() -> ProgressLineLayer {
        layer as! ProgressLineLayer
    }

    override class var layerClass: AnyClass {
        ProgressLineLayer.self
    }
}
