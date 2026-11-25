import SwiftUI

struct CircleButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused: Bool

    fileprivate enum Layout {
        static let size = CGFloat(72)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .frame(width: Layout.size, height: Layout.size)
            .background(isFocused ? Color.pcBackgroundActive : Color.pcBackgroundOverlay)
            .foregroundColor(isFocused ? .pcTextPrimaryActive : .pcTextPrimary)
            .clipShape(Circle())
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .background(Color.clear)
            .frame(width: Layout.size * 1.5, height: Layout.size)
    }
}
