import SwiftUI

struct GiveRatingsWhatsNewHeader: View {
    @State private var moving = false
    @State private var show = false

    private let publisher = Timer.publish(every: 6, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1..<6) { i in
                getStar(delay: Constants.animationInDelay + Double(i)*Constants.animationInDelay2)
            }
        }
        .frame(width: Constants.frameW)
        .onAppear {
            animate()
        }
        .onReceive(publisher) { _ in
            animate()
        }
    }

    var star: some View {
        Image("whatsnew_star")
            .offset(y: moving ? 0 : Constants.starMinY)
    }

    private func getStar(delay: Double) -> some View {
        VStack {
            star
                .animation(
                    .interpolatingSpring(stiffness: Constants.animationStiffness, damping: Constants.animationDamping)
                    .delay(TimeInterval(delay)),
                    value: moving
                )
        }
        .frame(width: Constants.starSize, height: Constants.starSize)
        .opacity(show ? 1 : 0)
        .animation(
            .linear(duration: Constants.animationDuration)
            .delay(TimeInterval(delay)),
            value: show
        )
    }

    private func animate() {
        moving.toggle()
        show.toggle()

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.animationOutDelay) {
            moving.toggle()
            show.toggle()
        }
    }

    private enum Constants {
        static let starSize = 40.0
        static let starMinY = -7.0

        static let frameW = 200.0

        static let animationInDelay = 0.2
        static let animationInDelay2 = 0.1
        static let animationOutDelay = 4.0
        static let animationDuration = 0.2
        static let animationStiffness = 300.0
        static let animationDamping = 10.0
    }
}

#Preview {
    GiveRatingsWhatsNewHeader()
}
