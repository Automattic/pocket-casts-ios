import UIKit

@IBDesignable
class AnimatedImageButton: UIView {
    @IBInspectable var mainColor = UIColor.white.withAlphaComponent(0.5) {
        didSet {
            shapeLayer.strokeColor = mainColor.withAlphaComponent(0.3).cgColor
            textLayer.foregroundColor = mainColor.cgColor
            buttonImage?.tintColor = mainColor
        }
    }

    @IBInspectable var textColor = UIColor.white.withAlphaComponent(0.5) {
        didSet {
            textLayer.foregroundColor = textColor.cgColor
        }
    }

    @IBInspectable var buttonTitle: String = "" {
        didSet {
            textLayer.string = buttonTitle
            accessibilityLabel = buttonTitle
            invalidateIntrinsicContentSize()
        }
    }

    @IBInspectable var cornerRadius: CGFloat = 8

    private let imageSize: CGFloat = 23
    var buttonImage: UIImageView? {
        didSet {
            if let buttonImage = buttonImage {
                addSubview(buttonImage)
            }
        }
    }

    var buttonTapped: (() -> Void)?

    enum AnimationType { case rotate }

    private var shapeLayer = CAShapeLayer()
    private var textLayer = CATextLayer()

    private var lastCGRectRendered = CGRect.zero

    private var textFont: UIFont {
        UIFont.font(with: .subheadline, weight: .medium)
    }

    override var intrinsicContentSize: CGSize {
        let labelSize = (buttonTitle as NSString).size(withAttributes: [.font: textFont])
        let imageWidth = buttonImage?.frame.width ?? 0
        let width = labelSize.width + imageWidth + 38 // Margins and spacing
        let height = max(40, ceil(textFont.lineHeight) + 20) // Minimum height of 40, padding of 20
        return CGSize(width: width, height: height)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        enablePointerInteraction()
        registerForContentSizeCategoryChanges()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        enablePointerInteraction()
        registerForContentSizeCategoryChanges()
    }

    private func registerForContentSizeCategoryChanges() {
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }

    @objc private func contentSizeCategoryDidChange() {
        updateTextLayerFont()
        lastCGRectRendered = .zero
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    private func updateTextLayerFont() {
        textLayer.fontSize = textFont.pointSize
        textLayer.font = CGFont(textFont.fontName as CFString)
    }

    override func prepareForInterfaceBuilder() {
        awakeFromNib()
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

        let textHeight = ceil(textFont.lineHeight)
        let textY = (alteredRect.height - textHeight) / 2

        if let buttonImage = buttonImage {
            let imageY = (alteredRect.height - imageSize) / 2
            textLayer.frame = CGRect(x: imageSize, y: textY, width: alteredRect.width - (imageSize / 2), height: textHeight)
            buttonImage.frame = CGRect(x: 15, y: imageY, width: imageSize, height: imageSize)
        } else {
            textLayer.frame = CGRect(x: 0, y: textY, width: alteredRect.width, height: textHeight)
        }

        invalidateIntrinsicContentSize()
    }

    func setup() {
        clipsToBounds = true
        isUserInteractionEnabled = true

        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = mainColor.cgColor
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        shapeLayer.contentsScale = UIScreen.main.scale
        shapeLayer.lineWidth = 2.0
        layer.insertSublayer(shapeLayer, at: 0)

        textLayer.string = buttonTitle
        textLayer.foregroundColor = mainColor.cgColor
        textLayer.fontSize = textFont.pointSize
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.font = CGFont(textFont.fontName as CFString)
        textLayer.alignmentMode = CATextLayerAlignmentMode.center
        shapeLayer.addSublayer(textLayer)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tapRecognizer)

        isAccessibilityElement = true
        accessibilityTraits = [.button]
    }

    @objc private func tapped() {
        buttonTapped?()
    }

    func animateImage(animationType: AnimationType) {
        switch animationType {
        case .rotate:
            let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
            rotation.fromValue = 0
            rotation.toValue = (Double.pi * 2)
            rotation.duration = CFTimeInterval(1.0)
            rotation.repeatCount = Float.infinity
            buttonImage?.layer.add(rotation, forKey: nil)
        }
    }

    func stopAnimatingImage() {
        buttonImage?.layer.removeAllAnimations()
    }

    // MARK: - Touch handling

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
