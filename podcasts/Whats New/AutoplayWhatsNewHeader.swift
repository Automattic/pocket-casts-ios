import SwiftUI

struct AutoplayWhatsNewHeader: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.init(hex: "03A9F4"), .init(hex: "50D0F1")], startPoint: .top, endPoint: .bottom)

            Circle()
                .foregroundStyle(.white)
                .frame(width: 120, height: 120)
                .overlay (
                    Image("whatsnew_autoplay")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80)
                        .rotationEffect(animate ? .degrees(720) : .degrees(0))
                )
                .scaleEffect(animate ? 1 : 0.1)
                .opacity(animate ? 1 : 0)
                .animation(.interpolatingSpring(mass: 1, stiffness: 600, damping: 15).delay(0.3), value: animate)
        }
        .frame(height: 195)
        .onAppear {
            animate = true
        }
    }
}

struct AutoplayWhatsNewHeader_Previews: PreviewProvider {
    static var previews: some View {
        AutoplayWhatsNewHeader()
    }
}
