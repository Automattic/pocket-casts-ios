import UIKit
import SwiftUI

class ToastManager {
    static let shared = ToastManager()
    private init() {}

    private var currentToast: UIHostingController<ToastView>?
    private var dismissTask: Task<Void, Never>?

    func show(_ message: String, duration: TimeInterval = 3.0) {
        Task { @MainActor in
            dismissTask?.cancel()
            currentToast?.view.removeFromSuperview()

            guard let hostView = ToastWindow.shared?.rootViewController?.view else { return }

            let toastVC = UIHostingController(rootView: ToastView(message: message))
            guard let toast = toastVC.view else {
                return
            }
            toast.translatesAutoresizingMaskIntoConstraints = false
            hostView.addSubview(toast)
            currentToast = toastVC

            UIAccessibility.post(notification: .announcement, argument: message)

            NSLayoutConstraint.activate([
                toast.trailingAnchor.constraint(equalTo: hostView.safeAreaLayoutGuide.trailingAnchor, constant: 0),
                toast.topAnchor.constraint(equalTo: hostView.safeAreaLayoutGuide.topAnchor, constant: -80),
                toast.widthAnchor.constraint(lessThanOrEqualTo: hostView.widthAnchor, multiplier: 0.6)
            ])

            toast.alpha = 0
            toast.transform = CGAffineTransform(translationX: 300, y: 0)
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
                    if self?.currentToast?.view === toast {
                        self?.currentToast = nil
                    }
                }
            }
        }
    }
}
