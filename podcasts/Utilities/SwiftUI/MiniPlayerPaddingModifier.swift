import SwiftUI

/// Apply a bottom padding whenever the mini player is visible
public struct MiniPlayerSafeAreaInset: ViewModifier {
    @State var isMiniPlayerVisible: Bool = false
    let multipler: CGFloat

    init(multipler: CGFloat) {
        self.multipler = multipler
    }

    public func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // Adjust the bottom inset only when the mini player is visible
                Color.clear
                    .frame(height: (isMiniPlayerVisible ? Constants.Values.miniPlayerOffset : 0) * multipler)
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
    func miniPlayerSafeAreaInset(multiplier: CGFloat = 1) -> some View {
        self.modifier(MiniPlayerSafeAreaInset(multipler: multiplier))
    }
}
