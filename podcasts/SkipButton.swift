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

    required init?(coder aDecoder: NSCoder) {
        animationView = LottieAnimationView(name: "skip_button")
        skipLabel = UILabel()

        super.init(coder: aDecoder)

        animationView.isUserInteractionEnabled = false
        animationView.animationSpeed = 1.3
        animationView.clipsToBounds = false

        skipLabel.textAlignment = .center
        skipLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
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
            animationView.heightAnchor.constraint(equalToConstant: 53),
            animationView.widthAnchor.constraint(equalToConstant: 45),
            xConstraint,
            animationView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addSubview(skipLabel)
        skipLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            skipLabel.leadingAnchor.constraint(equalTo: animationView.leadingAnchor),
            skipLabel.trailingAnchor.constraint(equalTo: animationView.trailingAnchor),
            skipLabel.bottomAnchor.constraint(equalTo: animationView.bottomAnchor),
            skipLabel.topAnchor.constraint(equalTo: animationView.topAnchor, constant: 8)
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
}
