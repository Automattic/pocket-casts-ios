import SwiftUI

@Observable
class FocusStore {
    var focusedID: String?
}

struct FocusObserving: ViewModifier {
    @Environment(FocusStore.self) var focusStore
    @FocusState private var isFocused: Bool
    let section: String

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onChange(of: isFocused) { _, newValue in
                if newValue {
                    focusStore.focusedID = section
                } else if focusStore.focusedID == section {
                    focusStore.focusedID = nil
                }
            }
    }
}

extension View {
    func setFocus(section: String) -> some View {
        modifier(FocusObserving(section: section))
    }
}
