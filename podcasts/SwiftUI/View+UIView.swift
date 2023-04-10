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
}
