import UIKit

extension UIViewController {
    /// Whether this view controller is presented as a sheet that runs under the status bar,
    /// as sheets do under the status pill in iPhone Duo's vertical bar.
    var isSheetUnderStatusBar: Bool {
        guard presentingViewController != nil,
              !isBeingDismissed,
              sheetPresentationController != nil,
              let view = viewIfLoaded,
              let window = view.window else {
            return false
        }
        return view.convert(view.bounds, to: window).intersects(window.statusBarArea)
    }
}

extension UIWindow {
    /// The part of the window the status bar draws over: across the top, or at the top
    /// of the vertical bar that iPhone Duo reports as a side safe area inset.
    var statusBarArea: CGRect {
        Self.statusBarArea(
            bounds: bounds,
            safeAreaInsets: safeAreaInsets,
            statusBarFrame: windowScene?.statusBarManager?.statusBarFrame ?? .zero
        )
    }

    static func statusBarArea(bounds: CGRect, safeAreaInsets insets: UIEdgeInsets, statusBarFrame: CGRect) -> CGRect {
        guard insets.top == 0 else {
            return statusBarFrame
        }
        if insets.right > 0 {
            return CGRect(x: bounds.maxX - insets.right, y: bounds.minY, width: insets.right, height: insets.right)
        }
        if insets.left > 0 {
            return CGRect(x: bounds.minX, y: bounds.minY, width: insets.left, height: insets.left)
        }
        return statusBarFrame
    }
}
