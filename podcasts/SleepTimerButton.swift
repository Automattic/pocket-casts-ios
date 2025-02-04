#if !APPCLIP
import Lottie
#endif
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
#if APPCLIP
    private var animationView: UIImageView
#else
    private var animationView: LottieAnimationView
#endif

    override var tintColor: UIColor! {
        didSet {
#if APPCLIP
            animationView.tintColor = tintColor
#else
            let colorValues = tintColor.getRGBA()
            let colorProvider = ColorValueProvider(LottieColor(r: colorValues[0], g: colorValues[1], b: colorValues[2], a: colorValues[3] * 2))
            animationView.setValueProvider(colorProvider, keypath: AnimationKeypath(keypath: "**.Fill 1.Color"))
            animationView.setValueProvider(colorProvider, keypath: AnimationKeypath(keypath: "**.Fill 2.Color"))
            animationView.setValueProvider(colorProvider, keypath: AnimationKeypath(keypath: "**.Fill 3.Color"))
#endif
        }
    }

    override init(frame: CGRect) {
#if APPCLIP
        animationView = UIImageView(image: UIImage(named: "ac-sleep-button"))
        animationView.isUserInteractionEnabled = false
        animationView.tintColor = .white
        animationView.contentMode = .scaleAspectFit
#else
        animationView = LottieAnimationView(name: "sleep_button")
        animationView.isUserInteractionEnabled = false
        animationView.animationSpeed = 1.0
        animationView.currentProgress = 0.5
#endif
        

        animationView.transform = CGAffineTransform(scaleX: scaleAmount, y: scaleAmount)

        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
#if APPCLIP
        animationView = UIImageView(image: UIImage(named: "sleep_button"))
        animationView.isUserInteractionEnabled = false
#else
        animationView = LottieAnimationView(name: "sleep_button")
        animationView.isUserInteractionEnabled = false
        animationView.animationSpeed = 1.0
        animationView.currentProgress = 0.5
#endif

        animationView.transform = CGAffineTransform(scaleX: scaleAmount, y: scaleAmount)

        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        setupAnimation()
    }

    func setupAnimation() {
        animationView.translatesAutoresizingMaskIntoConstraints = false
#if !APPCLIP
        animationView.loopMode = .loop
#endif
        addSubview(animationView)

        animationView.anchorToAllSidesOf(view: self)
    }

    private func animateToOn() {
#if !APPCLIP
        animationView.currentProgress = 0.5
        animationView.play()
#endif
    }

    private func animateToOff() {
#if !APPCLIP
        animationView.stop()
        animationView.currentProgress = 0.5
#endif
    }
}
