import Lottie
import UIKit

class NowPlayingAnimationView: UIView {
    var animating = false {
        didSet {
            // check for a state we're already in
            if animating == oldValue { return }

            if animating {
                animateToOn()
            } else {
                animateToOff()
            }
        }
    }

    private var animationView: LottieAnimationView

    required init?(coder aDecoder: NSCoder) {
        animationView = LottieAnimationView(name: "nowplaying")

        super.init(coder: aDecoder)
    }

    func setFillColor(_ color: UIColor) {
        let keypath = AnimationKeypath(keys: ["**", "Fill 1", "**", "Color"])
        let colorProvider = ColorValueProvider(color.lottieColorValue)
        animationView.setValueProvider(colorProvider, keypath: keypath)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        animationView.isUserInteractionEnabled = false
        animationView.isHidden = true
        animationView.loopMode = .loop
        animationView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(animationView)

        animationView.anchorToAllSidesOf(view: self)
    }

    private func animateToOn() {
        animationView.isHidden = false
        animationView.play()
    }

    private func animateToOff() {
        animationView.isHidden = true
        animationView.stop()
    }
}
