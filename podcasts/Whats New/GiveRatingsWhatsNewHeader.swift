import SwiftUI

struct GiveRatingsWhatsNewHeader: View {
    @State private var moving = false
    @State private var show = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1..<6) { i in
                getStar(delay: 0.2 + Double(i)*0.1)
            }
        }
        .frame(width: 200.0)
        .onAppear {
            moving.toggle()
            show.toggle()

            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                moving.toggle()
                show.toggle()
            }
        }
    }

    var star: some View {
        Image("whatsnew_star")
            .offset(y: moving ? 0 : -7)
    }

    private func getStar(delay: Double) -> some View {
        VStack {
            star
                .animation(
                    .interpolatingSpring(stiffness: 300, damping: 10)
                    .delay(TimeInterval(delay)),
                    value: moving
                )
        }
        .frame(width: 40.0, height: 40.0)
        .opacity(show ? 1 : 0)
        .animation(
            .linear(duration: 0.2)
            .delay(TimeInterval(delay)),
            value: show
        )
    }
}

#Preview {
    GiveRatingsWhatsNewHeader()
}
