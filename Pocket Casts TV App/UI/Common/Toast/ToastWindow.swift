import UIKit
import SwiftUI

class ToastWindow: UIWindow {
    private static var instance: ToastWindow?

    static var shared: ToastWindow? {
        if let instance { return instance }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
        else { return nil }
        let window = ToastWindow(windowScene: scene)
        instance = window
        return window
    }

    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        self.windowLevel = .alert + 1
        self.isHidden = false
        self.backgroundColor = .clear
        self.rootViewController = ToastHostViewController()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self.rootViewController?.view ? nil : view
    }
}

class ToastHostViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }
}
