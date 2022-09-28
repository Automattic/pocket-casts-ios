import Lottie
import UIKit

class EffectsButton: UIButton {
    var effectsOn = false {
        didSet {
            // check for a state we're already in
            if effectsOn == oldValue { return }

            if effectsOn {
                setImage(UIImage(named: "effects-on"), for: .normal)
            } else {
                setImage(UIImage(named: "effects-off"), for: .normal)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setImage(UIImage(named: "effects-off"), for: .normal)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setImage(UIImage(named: "effects-off"), for: .normal)
    }
}
