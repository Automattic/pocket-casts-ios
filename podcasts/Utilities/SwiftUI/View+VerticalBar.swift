import SwiftUI

extension View {
    /// Keeps the toolbar items in the horizontal navigation bar instead of moving them to the
    /// vertical bar on iPhone Duo. Use it for sheets with a single button, such as Close.
    @ViewBuilder func verticalBarDisabled() -> some View {
        // The iOS 27.1 SDK
        #if canImport(SwiftUI, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            toolbarVerticalBehavior(.disabled)
        } else {
            self
        }
        #else
        self
        #endif
    }
}
