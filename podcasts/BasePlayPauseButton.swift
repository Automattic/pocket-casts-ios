import Lottie
import UIKit

class BasePlayPauseButton: UIButton {
    private static let animationSpeed = 1.0 as CGFloat

    private enum PlayState { case playing, paused, notSet }

    private var currentState = PlayState.notSet
    var animationView: LottieAnimationView!

    var isPlaying = false {
        didSet {
            // check for a state we're already in
            if isPlaying, currentState == .playing { return }
            if !isPlaying, currentState == .paused { return }

            if currentState == .notSet {
                currentState = isPlaying ? .playing : .paused
                animationView.currentProgress = isPlaying ? 0 : 0.5
            } else if isPlaying {
                animateToPlaying()
            } else {
                animateToPaused()
            }

            isAccessibilityElement = true
            accessibilityLabel = isPlaying ? L10n.pause : L10n.play
            accessibilityIdentifier = "play pause button"
        }
    }

    var playButtonColor: UIColor = .white {
        didSet {
            let colorValues = playButtonColor.getRGBA()
            let colorProvider = ColorValueProvider(LottieColor(r: colorValues[0], g: colorValues[1], b: colorValues[2], a: colorValues[3]))
            animationView.setValueProvider(colorProvider, keypath: AnimationKeypath(keypath: "**.Fill 1.Color"))
            animationView.setValueProvider(colorProvider, keypath: AnimationKeypath(keypath: "**.Stroke 1.Color"))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        animationView = LottieAnimationView(name: animationName())
        animationView.isUserInteractionEnabled = false
        animationView.animationSpeed = BasePlayPauseButton.animationSpeed
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        place(animation: animationView)
    }

    func animationCenter() -> CGPoint {
        animationView.center
    }

    private func animateToPlaying() {
        animate(from: 0.5, to: 1.0, changingToState: .playing)
    }

    private func animateToPaused() {
        animate(from: 0, to: 0.5, changingToState: .paused)
    }

    func place(animation: LottieAnimationView) {}
    func animationName() -> String {
        "player_play_button"
    }

    private func animate(from: CGFloat, to: CGFloat, changingToState: PlayState) {
        currentState = changingToState

        // only run the animation if our app is foregrounded, otherwise just change the state
        if UIApplication.shared.applicationState == .active {
            animationView.currentProgress = from
            animationView.play(fromProgress: from, toProgress: to) { [weak self] completed in
                if !completed {
                    self?.animationView.currentProgress = to
                }
            }
        } else {
            animationView.currentProgress = to
        }
    }
}
