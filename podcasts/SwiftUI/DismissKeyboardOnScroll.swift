import SwiftUI

extension UIApplication {
    func endEditing(_ force: Bool) {
        (connectedScenes.first as? UIWindowScene)?.windows.filter { $0.isKeyWindow }.first?.endEditing(force)
    }
}

public struct DismissKeyboardOnScroll: ViewModifier {
    var gesture = DragGesture().onChanged { _ in
        UIApplication.shared.endEditing(true)
    }
    public func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .scrollDismissesKeyboard(.interactively)
        } else {
            content
                .highPriorityGesture(gesture)
        }
    }
}

