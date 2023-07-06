import SwiftUI

struct AutoplayWhatsNewHeader: View {
    @State private var scale: Double = 0
    @State var shouldRotate = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.init(hex: "03A9F4"), .init(hex: "50D0F1")], startPoint: .top, endPoint: .bottom)

            ZStack {
                Circle()
                    .foregroundStyle(.white)
                    .frame(width: 120, height: 120)

                Image("whatsnew_autoplay")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80)
                    .rotationEffect(shouldRotate ? .degrees(0) : .degrees(360))
            }
            .scaleEffect(scale)
        }
        .frame(height: 195)
        .onAppear {
            withAnimation(.spring().speed(0.5)) {
                scale = 1.5
            }

            withAnimation(.spring().speed(0.8)) {
                shouldRotate = true
            }

            withAnimation(.spring().speed(1)) {
                scale = 1
            }
        }
    }
}

struct AutoplayWhatsNewHeader_Previews: PreviewProvider {
    static var previews: some View {
        AutoplayWhatsNewHeader()
    }
}
