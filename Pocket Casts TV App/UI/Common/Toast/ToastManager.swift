import UIKit

class ToastManager {
    static let shared = ToastManager()
    private init() {}

    private var currentToast: ToastView?
    private var dismissTask: Task<Void, Never>?

    func show(_ message: String, duration: TimeInterval = 3.0) {
        Task { @MainActor in
            dismissTask?.cancel()
            currentToast?.removeFromSuperview()

            guard let hostView = ToastWindow.shared?.rootViewController?.view else { return }

            let toast = ToastView(message: message)
            hostView.addSubview(toast)
            currentToast = toast

            NSLayoutConstraint.activate([
                toast.trailingAnchor.constraint(equalTo: hostView.trailingAnchor, constant: -48),
                toast.topAnchor.constraint(equalTo: hostView.topAnchor, constant: 48),
                toast.widthAnchor.constraint(lessThanOrEqualTo: hostView.widthAnchor, multiplier: 0.6)
            ])

            toast.alpha = 0
            toast.transform = CGAffineTransform(translationX: 0, y: 20)
            UIView.animate(withDuration: 0.3) {
                toast.alpha = 1
                toast.transform = .identity
            }

            dismissTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(duration))
                guard !Task.isCancelled else { return }
                UIView.animate(withDuration: 0.3, animations: {
                    toast.alpha = 0
                    toast.transform = CGAffineTransform(translationX: 0, y: 20)
                }) { _ in
                    toast.removeFromSuperview()
                    if self?.currentToast === toast {
                        self?.currentToast = nil
                    }
                }
            }
        }
    }
}
