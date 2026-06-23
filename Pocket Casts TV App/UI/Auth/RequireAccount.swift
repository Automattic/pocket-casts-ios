import SwiftUI

/// Runs a closure only when the viewer is signed in; otherwise presents the
/// create-account flow and drops the closure (they can trigger it again once
/// signed in). Read from the environment and call it like a function:
///
/// ```swift
/// @Environment(\.requireAccount) private var requireAccount
/// requireAccount { model.subscribe() }
/// ```
///
/// Install the backing flow on a long-lived ancestor with
/// ``SwiftUI/View/requireAccountSupport()``; without it the closure just runs
/// immediately. Content in its own `sheet`/`fullScreenCover` doesn't inherit the
/// environment — re-apply `requireAccountSupport()` there to gate it too.
struct RequireAccountAction {
    fileprivate let perform: (@escaping () -> Void) -> Void

    func callAsFunction(_ action: @escaping () -> Void) {
        perform(action)
    }
}

private struct RequireAccountKey: EnvironmentKey {
    // No gate installed: run immediately so the action is never silently dropped.
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
    /// Apply once on an ancestor that outlives the actions it gates.
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
                    isShowingCreateAccount = true
                }
            })
            .sheet(isPresented: $isShowingCreateAccount) {
                CreateAccountView(style: .modal)
                    .environment(coordinator)
            }
    }
}
