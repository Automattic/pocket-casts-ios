import SwiftUI

struct PocketCastsLogoPill: View {
    @Binding var angle: Double

    var body: some View {
        HStack {
            Image("splashlogo")
                .resizable()
                .frame(width: 18, height: 18)
                .rotating(angle: $angle)
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
    @Binding var angle: Double

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
//            .onAppear {
//                withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
//                    angle = 360
//                }
//            }
    }
}

extension View {
    func rotating(angle: Binding<Double>) -> some View {
        self.modifier(RotationAnimationModifier(angle: angle))
    }
}

#Preview {
    PocketCastsLogoPill(angle: .constant(0))
}
