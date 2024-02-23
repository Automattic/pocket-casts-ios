import Lottie
import UIKit

class SleepTimerButton: UIButton {
    var scaleAmount: CGFloat = 1.5 {
        didSet {
            animationView.transform = CGAffineTransform(scaleX: scaleAmount, y: scaleAmount)
        }
    }

    var sleepTimerOn = false {
        didSet {
            // check for a state we're already in
            if sleepTimerOn == oldValue { return }

            if sleepTimerOn {
                animateToOn()
            } else {
                animateToOff()
            }
        }
    }

    private var animationView: LottieAnimationView

    override var tintColor: UIColor! {
        didSet {
            let colorValues = tintColor.getRGBA()
            let colorProvider = ColorValueProvider(LottieColor(r: colorValues[0], g: colorValues[1], b: colorValues[2], a: colorValues[3] * 2))
            animationView.setValueProvider(colorProvider, keypath: AnimationKeypath(keypath: "**.Fill 1.Color"))
            animationView.setValueProvider(colorProvider, keypath: AnimationKeypath(keypath: "**.Fill 2.Color"))
            animationView.setValueProvider(colorProvider, keypath: AnimationKeypath(keypath: "**.Fill 3.Color"))
        }
    }

    override init(frame: CGRect) {
        animationView = LottieAnimationView(name: "sleep_button")
        animationView.isUserInteractionEnabled = false
        animationView.animationSpeed = 1.0
        animationView.currentProgress = 0.5

        animationView.transform = CGAffineTransform(scaleX: scaleAmount, y: scaleAmount)

        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        animationView = LottieAnimationView(name: "sleep_button")
        animationView.isUserInteractionEnabled = false
        animationView.animationSpeed = 1.0
        animationView.currentProgress = 0.5

        animationView.transform = CGAffineTransform(scaleX: scaleAmount, y: scaleAmount)

        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        setupAnimation()
    }

    func setupAnimation() {
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.loopMode = .loop
        addSubview(animationView)

        animationView.anchorToAllSidesOf(view: self)
    }

    private func animateToOn() {
        animationView.currentProgress = 0.5
        animationView.play()
    }

    private func animateToOff() {
        animationView.stop()
        animationView.currentProgress = 0.5
    }
}
