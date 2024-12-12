import SwiftUI

/// Apply a bottom padding whenever the mini player is visible
public struct MiniPlayerSafeAreaInset: ViewModifier {
    @State var isMiniPlayerVisible: Bool = false

    public func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: Constants.Values.miniPlayerOffset) // Adjust the bottom inset
            }
            .onAppear {
                isMiniPlayerVisible = (PlaybackManager.shared.currentEpisode() != nil)
            }
            .ignoresSafeArea(.keyboard)
            .onReceive(NotificationCenter.default.publisher(for: Constants.Notifications.miniPlayerDidAppear), perform: { _ in
                isMiniPlayerVisible = true
            })
            .onReceive(NotificationCenter.default.publisher(for: Constants.Notifications.miniPlayerDidDisappear), perform: { _ in
                isMiniPlayerVisible = false
            })
    }
}

// Create an extension for easier usage
public extension View {
    func miniPlayerSafeAreaInset() -> some View {
        self.modifier(MiniPlayerSafeAreaInset())
    }
}
