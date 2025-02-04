#if !APPCLIP
import Lottie
#endif
import UIKit

class BasePlayPauseButton: UIButton {
    private static let animationSpeed = 1.0 as CGFloat

    private enum PlayState { case playing, paused, notSet }

    private var currentState = PlayState.notSet
#if APPCLIP
    var animationView: UIImageView!
#else
    var animationView: LottieAnimationView!
#endif

    var isPlaying = false {
        didSet {
            // check for a state we're already in
            if isPlaying, currentState == .playing { return }
            if !isPlaying, currentState == .paused { return }

            if currentState == .notSet {
                currentState = isPlaying ? .playing : .paused
#if !APPCLIP
                animationView.currentProgress = isPlaying ? 0 : 0.5
#endif
            } else if isPlaying {
                animateToPlaying()
            } else {
                animateToPaused()
            }
#if APPCLIP
            animationView.image = playButtonIcon(isPlaying: currentState == .playing)
#endif
            isAccessibilityElement = true
            accessibilityLabel = isPlaying ? L10n.pause : L10n.play
            accessibilityIdentifier = "play pause button"
        }
    }

    var playButtonColor: UIColor = .white {
        didSet {
#if APPCLIP
            animationView.tintColor = .white
#else
            let colorValues = playButtonColor.getRGBA()
            let colorProvider = ColorValueProvider(LottieColor(r: colorValues[0], g: colorValues[1], b: colorValues[2], a: colorValues[3]))
            animationView.setValueProvider(colorProvider, keypath: AnimationKeypath(keypath: "**.Fill 1.Color"))
            animationView.setValueProvider(colorProvider, keypath: AnimationKeypath(keypath: "**.Stroke 1.Color"))
#endif
        }
    }

#if APPCLIP
    func playButtonIcon(isPlaying: Bool = false) -> UIImage? {
        isPlaying ? UIImage(named: "ac-play-button-pause") :  UIImage(named: "ac-play-button-play")
    }
#endif

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
#if APPCLIP
        animationView = UIImageView(image: playButtonIcon())
        animationView.isUserInteractionEnabled = false
        animationView.tintColor = .white
#else
        animationView = LottieAnimationView(name: animationName())
        animationView.isUserInteractionEnabled = false
        animationView.animationSpeed = BasePlayPauseButton.animationSpeed
#endif
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
#if APPCLIP
    func place(animation: UIImageView) {}
#else
    func place(animation: LottieAnimationView) {}
#endif
    func animationName() -> String {
        "player_play_button"
    }

    private func animate(from: CGFloat, to: CGFloat, changingToState: PlayState) {
        currentState = changingToState
#if !APPCLIP
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
#endif
    }
}
