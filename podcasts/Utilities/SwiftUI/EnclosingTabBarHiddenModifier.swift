import SwiftUI
import UIKit

extension View {
    /// Hides the enclosing tab bar and mini player while `hidden` is true, matching the
    /// screens that present a `MultiSelectFooterView`. It resolves the SwiftUI view's host
    /// controller and forwards to `setEnclosingTabBarHidden`, which is a no-op on iOS 18
    /// and earlier, or when the view isn't inside a tab bar controller (e.g. the player).
    func enclosingTabBarHidden(_ hidden: Bool) -> some View {
        modifier(EnclosingTabBarHiddenModifier(hidden: hidden))
    }
}

private struct EnclosingTabBarHiddenModifier: ViewModifier {
    let hidden: Bool
    @State private var host: UIViewController?

    func body(content: Content) -> some View {
        content
            .background(
                HostControllerResolver { resolved in
                    host = resolved
                    if hidden {
                        resolved.setEnclosingTabBarHidden(true, animated: false)
                    }
                }
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
            )
            .onChange(of: hidden) {
                host?.setEnclosingTabBarHidden(hidden, animated: true)
            }
            .onAppear {
                if hidden {
                    host?.setEnclosingTabBarHidden(true, animated: false)
                }
            }
            .onDisappear {
                host?.setEnclosingTabBarHidden(false, animated: true)
            }
    }
}
