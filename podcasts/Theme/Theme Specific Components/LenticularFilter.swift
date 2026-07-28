import Foundation

class LenticularFilter {
    private var window: UIWindow?
    private var rootController: LenticularViewController?

    private var showing = false

    func show() {
        // the overlay view we use interferes with gestures on iPads, and also is also a bit much on a screen that size, so don't show it
        if UIDevice.current.userInterfaceIdiom != .phone { return }

        if showing { return }
        showing = true

        rootController = LenticularViewController()
        window = SceneHelper.newMainScreenWindow()
        window?.rootViewController = rootController
        window?.windowLevel = .alert
        window?.isHidden = false
        window?.isUserInteractionEnabled = false
    }

    func hide() {
        if !showing { return }
        showing = false

        window?.isHidden = true

        rootController = nil
        window = nil
    }

    public func isShowing() -> Bool {
        showing
    }
}
