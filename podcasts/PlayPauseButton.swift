import Lottie
import UIKit

class PlayPauseButton: BasePlayPauseButton {
    private let circleView = UIView()

    // Used to animate given LottieAnimationView doesn't animate with UIView.animate
    private var snapshot: UIView?

    private var circleSizeConstraints: [NSLayoutConstraint] = []

    /// When set, pins the visible circle (and its Lottie animation) to this size,
    /// decoupling the visual size from the button's tap target.
    var visualSize: CGFloat? {
        didSet { updateCircleSizeConstraints() }
    }

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
            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        updateCircleSizeConstraints()

        animation.translatesAutoresizingMaskIntoConstraints = false
        addSubview(animation)
        NSLayoutConstraint.activate([
            animation.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            animation.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
            animation.widthAnchor.constraint(equalTo: circleView.widthAnchor, multiplier: 0.48),
            animation.heightAnchor.constraint(equalTo: circleView.heightAnchor, multiplier: 0.48)
        ])
    }

    private func updateCircleSizeConstraints() {
        guard circleView.superview != nil else { return }
        NSLayoutConstraint.deactivate(circleSizeConstraints)
        if let visualSize {
            circleSizeConstraints = [
                circleView.widthAnchor.constraint(equalToConstant: visualSize),
                circleView.heightAnchor.constraint(equalToConstant: visualSize)
            ]
        } else {
            circleSizeConstraints = [
                circleView.widthAnchor.constraint(equalTo: widthAnchor),
                circleView.heightAnchor.constraint(equalTo: heightAnchor)
            ]
        }
        NSLayoutConstraint.activate(circleSizeConstraints)
    }

    // When using UIVIew.animate LottieAnimationView doesn't play nice with it
    // Here we snapshot the view to provide a smooth animation
    func prepareForAnimateTransition() {
        guard let snapshot = snapshotView(afterScreenUpdates: false) else { return }

        snapshot.translatesAutoresizingMaskIntoConstraints = false
        addSubview(snapshot)
        NSLayoutConstraint.activate([
            snapshot.widthAnchor.constraint(equalTo: widthAnchor),
            snapshot.heightAnchor.constraint(equalTo: heightAnchor),
            snapshot.centerXAnchor.constraint(equalTo: centerXAnchor),
            snapshot.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        self.snapshot = snapshot
    }

    func finishedTransition() {
        snapshot?.removeFromSuperview()
    }
}
