import SwiftUI

/// Apply a bottom padding whenever the mini player is visible
public struct MiniPlayerPadding: ViewModifier {
    @State var isMiniPlayerVisible: Bool = false

    public func body(content: Content) -> some View {
        content
            .padding(.bottom, isMiniPlayerVisible ? Constants.Values.miniPlayerOffset - 2 : 0).onAppear {
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
