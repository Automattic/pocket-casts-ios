import UIKit

class BlurEffectView: UIVisualEffectView {
    private let blurIntensity: Double
    private let animator = UIViewPropertyAnimator(duration: 1, curve: .linear)

    init(blurIntensity: Double) {
        self.blurIntensity = blurIntensity
        super.init(effect: nil)
        animator.pausesOnCompletion = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        guard let superview = superview else { return }
        backgroundColor = .clear
        frame = superview.bounds //Or setup constraints instead
        setupBlur()
    }

    private func setupBlur() {
        animator.stopAnimation(true)
        effect = nil

        animator.addAnimations { [weak self] in
            self?.effect = UIBlurEffect(style: .dark)
        }
        animator.fractionComplete = blurIntensity
    }

    deinit {
        animator.stopAnimation(true)
    }
}
