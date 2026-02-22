
import UIKit

class ShiftyRoundButton: UIView {
    @objc var strokeColor = UIColor.white.withAlphaComponent(0.5) {
        didSet {
            shapeLayer.strokeColor = strokeColor.cgColor
        }
    }

    @objc var buttonTitle: String = "" {
        didSet {
            textLayer.string = buttonTitle
            accessibilityLabel = buttonTitle
        }
    }

    @objc var isOn: Bool = false {
        didSet {
            shapeLayer.fillColor = fillColorForButton()
        }
    }

    @objc var enabled = true {
        didSet {
            if enabled {
                textLayer.foregroundColor = UIColor.white.cgColor
                shapeLayer.strokeColor = strokeColor.cgColor
                accessibilityHint = nil
            } else {
                textLayer.foregroundColor = UIColor.white.withAlphaComponent(0.5).cgColor
                shapeLayer.strokeColor = disabledFillColor.cgColor
                accessibilityHint = L10n.accessibilityDisabled
            }

            shapeLayer.fillColor = fillColorForButton()
        }
    }

    @objc var fillColor = UIColor.white.withAlphaComponent(0.30) {
        didSet {
            shapeLayer.fillColor = fillColorForButton()
        }
    }

    @objc var disabledFillColor = UIColor.white.withAlphaComponent(0.12) {
        didSet {
            shapeLayer.fillColor = fillColorForButton()
        }
    }

    @objc var textColor = UIColor.white {
        didSet {
            textLayer.foregroundColor = textColor.cgColor
        }
    }

    @objc var cornerRadius: CGFloat = 12

    var fontSize: CGFloat = 15 {
        didSet {
            updateTextLayerFont()
        }
    }

    var buttonTapped: (() -> Void)?

    private var shapeLayer = CAShapeLayer()
    private var textLayer = CATextLayer()

    private var lastCGRectRendered = CGRect.zero

    // MARK: - View Methods

    override func awakeFromNib() {
        super.awakeFromNib()

        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if lastCGRectRendered.equalTo(bounds) { return }

        lastCGRectRendered = bounds

        let alteredRect = CGRect(x: 2, y: 2, width: bounds.width - 6, height: bounds.height - 6)
        shapeLayer.frame = alteredRect
        shapeLayer.path = UIBezierPath(roundedRect: alteredRect, cornerRadius: cornerRadius).cgPath

        textLayer.frame = CGRect(x: 0, y: (alteredRect.height / 2) - (textLayer.fontSize / 2), width: alteredRect.width, height: alteredRect.height)
    }

    private func updateTextLayerFont() {
        let uiFont = UIFont.font(ofSize: fontSize, weight: .semibold, scalingWith: .largeTitle)
        textLayer.string = buttonTitle
        textLayer.foregroundColor = textColor.cgColor
        textLayer.fontSize = uiFont.pointSize
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.font = CGFont(uiFont.fontName as CFString)
        textLayer.alignmentMode = CATextLayerAlignmentMode.center
    }

    func setup() {
        clipsToBounds = true
        isUserInteractionEnabled = true

        shapeLayer.fillColor = fillColorForButton()
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        shapeLayer.contentsScale = UIScreen.main.scale
        shapeLayer.lineWidth = 2.0
        layer.insertSublayer(shapeLayer, at: 0)

        updateTextLayerFont()
        shapeLayer.addSublayer(textLayer)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tapRecognizer)

        isAccessibilityElement = true
        accessibilityTraits = [.button]
    }

    @objc private func tapped() {
        buttonTapped?()
    }

    private func fillColorForButton() -> CGColor {
        if !enabled {
            return disabledFillColor.cgColor
        }

        if isOn {
            return fillColor.cgColor
        }

        return UIColor.clear.cgColor
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !enabled { return }

        shapeLayer.transform = CATransform3DMakeScale(0.95, 0.95, 0.95)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !enabled { return }

        shapeLayer.transform = CATransform3DIdentity
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !enabled { return }

        shapeLayer.transform = CATransform3DIdentity
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory else { return }
        lastCGRectRendered = .zero
        updateTextLayerFont()
        setNeedsLayout()
    }
}
