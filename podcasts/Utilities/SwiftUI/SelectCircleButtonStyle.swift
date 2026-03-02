import SwiftUI

struct SelectCircleButtonStyle: ButtonStyle {
    @EnvironmentObject private var theme: Theme

    @Binding var selected: Bool

    var stroke: StrokeStyle = StrokeStyle(lineWidth: 2)
    var multiSelectButtonSize: CGFloat = 24
    var checkSize: CGFloat = 22

    func makeBody(configuration: Configuration) -> some View {
        Circle()
            .inset(by: 1)
            .stroke(style: stroke)
            .frame(width: multiSelectButtonSize, height: multiSelectButtonSize)
            .overlay(
                ZStack {
                    Circle().fill(theme.primaryIcon01)

                    Image("discover_tick")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: checkSize)
                        .foregroundStyle(theme.primaryInteractive02)
                }
                .opacity(selected ? 1 : 0)
                .animation(.linear(duration: 0.1), value: selected)
            )
            .contentShape(Circle())
            .onChange(of: configuration.isPressed) { pressed in
                if pressed {
                    selected.toggle()
                }
            }
            .foregroundStyle(theme.primaryIcon01)
    }
}
