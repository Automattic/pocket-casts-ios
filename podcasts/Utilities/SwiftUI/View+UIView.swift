import SwiftUI

/// View extension that makes getting the UIView value easier
extension View {
    /// Returns a UIView after being wrapped in a UIHostingController
    var uiView: UIView {
        UIHostingController(rootView: self).view
    }

    /// Returns a UIView after being wrapped in the ThemedHostingController and having the theme environment setup
    var themedUIView: UIView {
        ThemedHostingController(rootView: self).view
    }

    func insertThemedUIView(in vc: UIViewController) -> UIView {
        let hostedVC = ThemedHostingController(rootView: self)
        vc.addChild(hostedVC)
        vc.view.addSubview(hostedVC.view)
        hostedVC.didMove(toParent: vc)
        return hostedVC.view
    }
}
