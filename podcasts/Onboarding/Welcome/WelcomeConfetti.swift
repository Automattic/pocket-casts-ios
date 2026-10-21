import SwiftUI

struct WelcomeConfetti: View {
    let type: WelcomeConfettiEmitter.ConfettiType

    var body: some View {
        GeometryReader { proxy in
            WelcomeConfettiEmitter(type: type, frame: proxy.frame(in: .local)).ignoresSafeArea()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .ignoresSafeArea().zIndex(1000)
    }
}

// MARK: - Confetti 🎉

struct WelcomeConfettiEmitter: UIViewRepresentable {
    let type: ConfettiType
    let frame: CGRect
    let afterDelay: TimeInterval

    enum ConfettiType {
        case normal
        case plus
    }

    init(type: ConfettiType, frame: CGRect, afterDelay: TimeInterval = 0.5) {
        self.type = type
        self.frame = frame
        self.afterDelay = afterDelay
    }

    func makeUIView(context: Context) -> UIView {
        let hostView = UIView(frame: frame)

        DispatchQueue.main.asyncAfter(deadline: .now() + afterDelay) {
            let completion: ConfettiView.AnimationCompletion = { confettiView in
                confettiView.removeFromSuperview()
            }

            let confetti = (type == .plus) ? PlusConfettiView.self : NormalConfettiView.self
            confetti.cleanupAndAnimate(on: hostView, frame: frame, onAnimationCompletion: completion)
        }

        return hostView
    }

    func updateUIView(_ uiView: UIView, context: Context) { }

    private class PlusConfettiView: ConfettiView {
        override func emitConfetti() {
            guard let icon = UIImage(named: "confetti-plus") else {
                return
            }

            // Add more to the emitter
            var particles: [Particle] = []
            for _ in 0..<10 {
                particles.append(Particle(image: icon))
            }

            var config = PlusConfettiView.EmitterConfig()
            config.scaleRange = 1.2

            self.emit(with: particles, config: config)
        }
    }

    private class NormalConfettiView: ConfettiView {
        override func emitConfetti() {
            var images: [Particle] = []

            // Generate the particles
            for i in 1..<21 {
                let fileName = "confetti-shape-\(i)"
                if let image = UIImage(named: fileName) {
                    images.append(Particle(image: image))
                }
            }

            self.emit(with: images, config: NormalConfettiView.EmitterConfig())
        }
    }
}
