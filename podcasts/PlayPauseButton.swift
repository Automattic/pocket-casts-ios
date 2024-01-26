import Lottie
import UIKit

class PlayPauseButton: BasePlayPauseButton {
    private let circleView = UIView()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        backgroundColor = UIColor.clear

        circleView.clipsToBounds = true
        circleView.isUserInteractionEnabled = false
        circleView.backgroundColor = circleColor
    }

    var circleColor = UIColor.white {
        didSet {
            circleView.backgroundColor = circleColor
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        circleView.layer.cornerRadius = 0.5 * circleView.bounds.width
    }

    override func place(animation: LottieAnimationView) {
        circleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(circleView)
        NSLayoutConstraint.activate([
            circleView.widthAnchor.constraint(equalTo: widthAnchor),
            circleView.heightAnchor.constraint(equalTo: heightAnchor),
            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        animation.translatesAutoresizingMaskIntoConstraints = false
        addSubview(animation)
        NSLayoutConstraint.activate([
            animation.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            animation.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
            animation.widthAnchor.constraint(equalTo: circleView.widthAnchor, multiplier: 0.48),
            animation.heightAnchor.constraint(equalTo: circleView.heightAnchor, multiplier: 0.48)
        ])
    }
}
