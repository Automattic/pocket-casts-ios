import SwiftUI

/// Runs a closure only when the viewer is signed in. If they're signed out it
/// presents the create-account flow and runs the closure once the new account
/// has been created and synced.
///
/// Read it from the environment and call it like a function:
///
/// ```swift
/// @Environment(\.requireAccount) private var requireAccount
/// ...
/// Button(L10n.tvPodcastDetailFollowTitle) {
///     requireAccount { model.subscribe() }
/// }
/// ```
///
/// Install the backing flow once on a long-lived ancestor with
/// ``SwiftUI/View/requireAccountSupport()`` (e.g. the main tab view). Without it
/// the action falls back to running its closure immediately, so a misconfigured
/// call site never silently drops the work. Content presented in its own
/// `sheet`/`fullScreenCover` doesn't inherit the environment — re-apply
/// `requireAccountSupport()` inside it to gate actions there too.
struct RequireAccountAction {
    fileprivate let perform: (@escaping () -> Void) -> Void

    func callAsFunction(_ action: @escaping () -> Void) {
        perform(action)
    }
}

private struct RequireAccountKey: EnvironmentKey {
    // No gate installed: run the action immediately so it's never silently lost.
    static let defaultValue = RequireAccountAction { action in action() }
}

extension EnvironmentValues {
    var requireAccount: RequireAccountAction {
        get { self[RequireAccountKey.self] }
        set { self[RequireAccountKey.self] = newValue }
    }
}

extension View {
    /// Installs the create-account flow backing `@Environment(\.requireAccount)`.
    /// Apply once on an ancestor that outlives the actions it gates; descendants
    /// can then run sign-in-gated work without each owning a sheet and login check.
    func requireAccountSupport() -> some View {
        modifier(RequireAccountModifier())
    }
}

private struct RequireAccountModifier: ViewModifier {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var isShowingCreateAccount = false

    func body(content: Content) -> some View {
        content
            .environment(\.requireAccount, RequireAccountAction { action in
                if coordinator.userState.isLoggedIn {
                    action()
                } else {
                    // Park on the coordinator so the action survives the app-wide
                    // reset to `.userSync` that completing the flow triggers; it's
                    // replayed once syncing finishes (see AppCoordinator).
                    coordinator.pendingAccountAction = action
                    isShowingCreateAccount = true
                }
            })
            .sheet(isPresented: $isShowingCreateAccount, onDismiss: {
                // Completing the flow advances the app to `.userSync`; if it
                // hasn't, the viewer backed out — drop the parked action so it
                // can't fire later from an unrelated sign-in.
                guard case .userSync = coordinator.state else {
                    coordinator.pendingAccountAction = nil
                    return
                }
            }) {
                CreateAccountView(style: .modal)
                    .environment(coordinator)
            }
    }
}
