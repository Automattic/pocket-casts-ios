import SwiftUI

struct ReferralCardAnimatedGradientView: View {

    @StateObject var motion = MotionManager(options: .attitude)

    private var position: CGSize {
        let size = CGSize(width: motion.roll / (.pi / 2),
                          height: motion.pitch / (.pi / 2))
        return size
    }

    var body: some View {
        GeometryReader(content: { geometry in
            let offsetX = geometry.size.width / 2.5
            let offsetY = geometry.size.height / 4
            let motionScale = geometry.size.width / 5
            ZStack() {
                LinearGradient(
                    stops: Constants.gradientStops,
                    startPoint: UnitPoint(x: 0.12, y: 0),
                    endPoint: UnitPoint(x: 0.89, y: 0.95)
                )
                .clipShape(Circle())
                .blur(radius: geometry.size.height / Constants.blurFactor)
                .opacity(Constants.opacity)
                .ignoresSafeArea()
                .offset(x: -1 * offsetX + (position.width * motionScale),
                        y: -1 * offsetY + (position.height * motionScale))
                LinearGradient(
                    stops: Constants.gradientStops,
                    startPoint: UnitPoint(x: 0.29, y: 0.19),
                    endPoint: UnitPoint(x: 0.87, y: 1.18)
                )
                .clipShape(Circle())
                .blur(radius: geometry.size.height / Constants.blurFactor)
                .rotationEffect(Angle(degrees: 1.45))
                .opacity(Constants.opacity)
                .ignoresSafeArea()
                .offset(x: offsetX - (position.width * motionScale),
                        y: offsetY - (position.height * motionScale))
            }
            .animation(.easeInOut(duration: Constants.animationDuration), value: motion.pitch)
            .background(Constants.backgroundColor)
        })
        .clipped()
        .onAppear() {
            motion.start()
        }
        .onDisappear() {
            motion.stop()
        }
    }

    enum Constants {
        static let gradientStops: [Gradient.Stop] = [
            Gradient.Stop(color: Color(red: 0.25, green: 0.11, blue: 0.92), location: 0.00),
            Gradient.Stop(color: Color(red: 0.68, green: 0.89, blue: 0.86), location: 0.24),
            Gradient.Stop(color: Color(red: 0.87, green: 0.91, blue: 0.53), location: 0.50),
            Gradient.Stop(color: Color(red: 0.91, green: 0.35, blue: 0.26), location: 0.76),
            Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.1), location: 1.00),
        ]
        static let backgroundColor = Color.black
        static let animationDuration: TimeInterval = 5
        static let opacity = CGFloat(0.75)
        static let positionFactor = CGFloat(2.0)
        static let blurFactor = CGFloat(10)
    }
}

#Preview {
    Rectangle()
        .foregroundColor(.clear)
        .background {
            ReferralCardAnimatedGradientView()
        }
        .overlay(alignment: .bottomLeading) {
            Text("Sergio").padding()
        }
        .cornerRadius(15)
        .frame(width: 315, height: 200)

}
