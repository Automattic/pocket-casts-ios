
import UIKit

@IBDesignable
class ThemeableButton: UIView {
    var buttonStyle: ThemeStyle = .primaryInteractive01 {
        didSet {
            updateColors()
        }
    }

    var textStyle: ThemeStyle = .primaryInteractive02 {
        didSet {
            updateColors()
        }
    }

    @IBInspectable var buttonTitle: String = "" {
        didSet {
            textLayer.string = buttonTitle
            accessibilityLabel = buttonTitle
        }
    }

    @IBInspectable var shouldFill: Bool = false {
        didSet {
            shapeLayer.fillColor = fillColorForButton()
        }
    }

    @IBInspectable var cornerRadius: CGFloat = 12

    var buttonTapped: (() -> Void)?

    private var shapeLayer = CAShapeLayer()
    private var textLayer = CATextLayer()

    private var lastCGRectRendered = CGRect.zero

    override func prepareForInterfaceBuilder() {
        setup()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

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

        textLayer.frame = CGRect(x: 0, y: (alteredRect.height / 2) - 7, width: alteredRect.width, height: 18)
    }

    func setup() {
        clipsToBounds = true
        isUserInteractionEnabled = true

        shapeLayer.fillColor = fillColorForButton()
        shapeLayer.strokeColor = fillColorForButton()
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        shapeLayer.contentsScale = UIScreen.main.scale
        shapeLayer.lineWidth = 2.0
        layer.insertSublayer(shapeLayer, at: 0)

        let uiFont = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.semibold)
        textLayer.string = buttonTitle
        textLayer.foregroundColor = AppTheme.colorForStyle(textStyle).cgColor
        textLayer.fontSize = 15
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.font = CGFont(uiFont.fontName as CFString)
        textLayer.alignmentMode = CATextLayerAlignmentMode.center
        shapeLayer.addSublayer(textLayer)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tapRecognizer)

        isAccessibilityElement = true
        accessibilityTraits = [.button]

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
    }

    @objc private func themeDidChange() {
        updateColors()
    }

    private func updateColors() {
        textLayer.foregroundColor = AppTheme.colorForStyle(textStyle).cgColor
        shapeLayer.fillColor = fillColorForButton()
        shapeLayer.strokeColor = fillColorForButton()
    }

    private func fillColorForButton() -> CGColor {
        let color = shouldFill ? AppTheme.colorForStyle(buttonStyle) : UIColor.clear

        return color.cgColor
    }

    // MARK: - Touch handling

    @objc private func tapped() {
        buttonTapped?()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        shapeLayer.transform = CATransform3DMakeScale(0.95, 0.95, 0.95)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        shapeLayer.transform = CATransform3DIdentity
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        shapeLayer.transform = CATransform3DIdentity
    }
}
