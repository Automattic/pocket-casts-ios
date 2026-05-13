import UIKit

final class TVToast {
    static let shared = TVToast()

    private weak var overlayView: UIView?
    private var toastView: UIView?
    private var dismissTask: Task<Void, Never>?

    func configure(with overlayView: UIView?) {
        self.overlayView = overlayView
    }

    func show(_ message: String) {
        dismissTask?.cancel()
        toastView?.removeFromSuperview()

        guard let overlayView else { return }

        let label = PaddedLabel()
        label.text = message
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .white
        label.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        overlayView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.topAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.trailingAnchor, constant: -48)
        ])

        label.alpha = 0
        UIView.animate(withDuration: 0.3) {
            label.alpha = 1
        }

        toastView = label

        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            UIView.animate(withDuration: 0.3) {
                label.alpha = 0
            } completion: { _ in
                label.removeFromSuperview()
            }
        }
    }
}

private class PaddedLabel: UILabel {
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + 40, height: size.height + 24)
    }
}
