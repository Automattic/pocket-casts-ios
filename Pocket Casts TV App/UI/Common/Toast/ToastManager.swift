@Observable
class ToastManager {
    static let shared = ToastManager()
    private init() {}

    func show(_ message: String, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async {
            guard let hostView = ToastWindow.shared.rootViewController?.view else { return }

            let toast = ToastView(message: message)
            hostView.addSubview(toast)

            // Position: bottom-center (common tvOS pattern)
            NSLayoutConstraint.activate([
                toast.trailingAnchor.constraint(equalTo: hostView.trailingAnchor, constant: -48),
                toast.topAnchor.constraint(equalTo: hostView.topAnchor, constant: 48),
                toast.widthAnchor.constraint(lessThanOrEqualTo: hostView.widthAnchor, multiplier: 0.6)
            ])

            // Animate in
            toast.alpha = 0
            toast.transform = CGAffineTransform(translationX: 0, y: 20)
            UIView.animate(withDuration: 0.3) {
                toast.alpha = 1
                toast.transform = .identity
            }

            // Animate out and remove
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                UIView.animate(withDuration: 0.3, animations: {
                    toast.alpha = 0
                    toast.transform = CGAffineTransform(translationX: 0, y: 20)
                }) { _ in
                    toast.removeFromSuperview()
                }
            }
        }
    }
}
