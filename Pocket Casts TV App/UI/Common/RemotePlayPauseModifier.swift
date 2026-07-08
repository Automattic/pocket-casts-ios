import SwiftUI

private struct RemotePlayPauseModifier: ViewModifier {

    @Environment(AppCoordinator.self) var coordinator: AppCoordinator?

    func body(content: Content) -> some View {
        content
            .onPlayPauseCommand {
                coordinator?.remotePlayPauseToggle()
            }
    }
}

extension View {
    func remotePlayPause() -> some View {
        modifier(RemotePlayPauseModifier())
    }
}
