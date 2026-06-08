import SwiftUI

@Observable
class FocusStore {
    var focusedID: AnyHashable?
}

struct FocusObserving: ViewModifier {
    @Environment(FocusStore.self) var focusStore
    @FocusState private var isFocused: Bool
    let section: AnyHashable

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onChange(of: isFocused) { _, newValue in
                if newValue {
                    print(section)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        focusStore.focusedID = section
                    }
                }
            }
    }
}

extension View {
    func setFocus(section: String) -> some View {
        modifier(FocusObserving(section: section))
    }
}
