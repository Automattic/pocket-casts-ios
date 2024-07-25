import SwiftUI

struct PocketCastsLogoPill: View {
    var body: some View {
        HStack {
            Image("splashlogo")
                .resizable()
                .frame(width: 18, height: 18)
                .rotating()
            Text("Pocket Casts")
                .padding(.trailing, 7)
                .font(Font.system(size: 12, weight: .semibold))
        }
        .padding(4)
        .foregroundStyle(.white)
        .background(Theme(previewTheme: .classic).primaryIcon01)
        .clipShape(Capsule())
    }
}

struct RotationAnimationModifier: ViewModifier {
    @State private var angle: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .onAppear {
                withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
    }
}

extension View {
    func rotating() -> some View {
        self.modifier(RotationAnimationModifier())
    }
}

#Preview {
    PocketCastsLogoPill()
}
