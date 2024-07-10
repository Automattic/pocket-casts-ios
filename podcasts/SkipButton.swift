import Lottie
import UIKit

class SkipButton: UIButton {
    private static let buttonPadding: CGFloat = 20

    var skipBack = false {
        didSet {
            if skipBack {
                animationView.transform = CGAffineTransform.identity
            } else {
                animationView.transform = animationView.transform.scaledBy(x: -1, y: 1)
            }
        }
    }

    var skipAmount = 0 {
        didSet {
            skipLabel.text = "\(skipAmount)"
        }
    }

    var longPressed: (() -> Void)?

    override var tintColor: UIColor! {
        didSet {
            skipLabel.textColor = tintColor

            let colorValues = tintColor.getRGBA()
            let colorProvider = ColorValueProvider(LottieColor(r: colorValues[0], g: colorValues[1], b: colorValues[2], a: colorValues[3]))
            animationView.setValueProvider(colorProvider, keypath: AnimationKeypath(keypath: "**.Fill 1.Color"))
            animationView.setValueProvider(colorProvider, keypath: AnimationKeypath(keypath: "**.Stroke 1.Color"))
        }
    }

    private var animationView: LottieAnimationView
    private let skipLabel: UILabel

    private var currentSize: Size = .large

    private lazy var animationHeightAnchor = animationView.heightAnchor.constraint(equalToConstant: Size.large.sizes.height)
    private lazy var animationWidthAnchor = animationView.widthAnchor.constraint(equalToConstant: Size.large.sizes.width)
    private lazy var skipLabelCenterYAnchor = skipLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: Size.large.sizes.topPadding / 2)
    private lazy var skipLabelXConstraint = skipBack ? trailingAnchor.constraint(equalTo: skipLabel.trailingAnchor, constant: SkipButton.buttonPadding) : skipLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: SkipButton.buttonPadding)

    required init?(coder aDecoder: NSCoder) {
        animationView = LottieAnimationView(name: "skip_button")
        skipLabel = UILabel()

        super.init(coder: aDecoder)

        animationView.isUserInteractionEnabled = false
        animationView.animationSpeed = 1.3
        animationView.clipsToBounds = false

        skipLabel.textAlignment = .center
        skipLabel.font = UIFont.systemFont(ofSize: Size.large.sizes.fontSize, weight: .medium)
        skipLabel.textColor = UIColor.white

        addTarget(self, action: #selector(playAnimation), for: .touchUpInside)

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(buttonLongPressed(_:)))
        addGestureRecognizer(longPressGesture)
    }

    deinit {
        removeTarget(self, action: #selector(playAnimation), for: .touchUpInside)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        setupViews()
    }

    func setupViews() {
        animationView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(animationView)

        let xConstraint = skipBack ? trailingAnchor.constraint(equalTo: animationView.trailingAnchor, constant: SkipButton.buttonPadding) : animationView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: SkipButton.buttonPadding)
        NSLayoutConstraint.activate([
            animationHeightAnchor,
            animationWidthAnchor,
            xConstraint,
            animationView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addSubview(skipLabel)
        skipLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            skipLabel.heightAnchor.constraint(equalToConstant: Size.large.sizes.height),
            skipLabel.widthAnchor.constraint(equalToConstant: Size.large.sizes.width),
            skipLabelXConstraint,
            skipLabelCenterYAnchor
        ])
    }

    @objc private func buttonLongPressed(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else { return }

        longPressed?()
    }

    @objc private func playAnimation() {
        animationView.currentProgress = 0
        animationView.play()
    }

    func changeSize(to size: Size) {
        currentSize = size
        let sizes = currentSize.sizes
        animationHeightAnchor.constant = sizes.height
        animationWidthAnchor.constant = sizes.width
        skipLabelCenterYAnchor.constant = sizes.topPadding / 2

        let labelScale = UIFont.systemFont(ofSize: sizes.fontSize, weight: .medium).pointSize / skipLabel.font.pointSize
        skipLabel.transform = .init(scaleX: labelScale, y: labelScale)

        let subtract = currentSize == .small ? (Size.large.sizes.width - Size.small.sizes.width) / 2 : 0
        skipLabelXConstraint.constant = SkipButton.buttonPadding - subtract
    }

    // When using UIVIew.animate LottieAnimationView doesn't play nice with it
    // Here we snapshot the view to provide a smooth animation
    func prepareForAnimateTransition(withBackground: UIColor?) {
        guard let lottieView = subviews.first as? LottieAnimationView,
              let snapshot = lottieView.snapshotView(afterScreenUpdates: false) else { return }

        let multiplier = currentSize == .large ? Size.large.sizes.width / Size.large.sizes.height : Size.large.sizes.height / Size.large.sizes.width

        snapshot.translatesAutoresizingMaskIntoConstraints = false
        snapshot.backgroundColor = withBackground
        subviews.first?.addSubview(snapshot)
        NSLayoutConstraint.activate([
            snapshot.widthAnchor.constraint(equalTo: lottieView.widthAnchor, multiplier: multiplier),
            snapshot.heightAnchor.constraint(equalTo: lottieView.heightAnchor),
            snapshot.centerXAnchor.constraint(equalTo: lottieView.centerXAnchor),
            snapshot.centerYAnchor.constraint(equalTo: lottieView.centerYAnchor)
        ])

        animationView.clipsToBounds = true
    }

    func finishedTransition() {
        guard let lottieView = subviews.first else { return }


        animationView.clipsToBounds = false
        lottieView.subviews.first?.removeFromSuperview()
    }

    enum Size {
        case small
        case large

        var sizes: (width: CGFloat, height: CGFloat, fontSize: CGFloat, topPadding: CGFloat) {
            self == .small ? (32, 32, 10, 5) : (45, 53, 14, 8)
        }
    }
}
