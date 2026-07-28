import SwiftUI

@Observable
class FocusStore {
    private(set) var focusedID: AnyHashable?
    private var holder: UUID?

    /// Marks `section` as focused on behalf of a specific item. The `holder`
    /// uniquely identifies the claimant so a later `relinquish` can tell
    /// whether the claim is still its own or has been replaced by a sibling.
    func claim(section: AnyHashable, holder: UUID) {
        self.holder = holder
        focusedID = section
    }

    /// Clears the focused section, but only if `holder` matches the current
    /// claimant. Lets a sibling in the same section take over without the
    /// outgoing item wiping the new claim during a focus handoff.
    func relinquish(holder: UUID) {
        guard self.holder == holder else { return }
        self.holder = nil
        focusedID = nil
    }
}

struct FocusObserving: ViewModifier {
    @Environment(FocusStore.self) var focusStore
    @FocusState private var isFocused: Bool
    @State private var identity = UUID()
    let section: AnyHashable

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onChange(of: isFocused) { _, newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    if newValue {
                        focusStore.claim(section: section, holder: identity)
                    } else {
                        focusStore.relinquish(holder: identity)
                    }
                }
            }
            // If this view is torn down (list recycling, tab swap) the
            // `isFocused` change to `false` may never fire, leaving the
            // section title stuck in the highlighted state. `relinquish`
            // checks the holder, so this won't wipe a sibling's claim.
            .onDisappear {
                focusStore.relinquish(holder: identity)
            }
    }
}

extension View {
    func setFocus(section: String) -> some View {
        modifier(FocusObserving(section: section))
    }
}
