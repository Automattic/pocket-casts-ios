import SwiftUI

extension UIApplication {
    func endEditing(_ force: Bool) {
        (connectedScenes.first as? UIWindowScene)?.windows.filter { $0.isKeyWindow }.first?.endEditing(force)
    }
}

public struct DismissKeyboardOnScroll: ViewModifier {
    var gesture = DragGesture().onChanged { value in
        let velocity = CGSize(
            width: value.predictedEndLocation.x - value.location.x,
            height: value.predictedEndLocation.y - value.location.y
        )

        if abs(velocity.height) > 30 {
            UIApplication.shared.endEditing(true)
        }
    }

    public func body(content: Content) -> some View {
        content
            .simultaneousGesture(gesture)
    }
}
