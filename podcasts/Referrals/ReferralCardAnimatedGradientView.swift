import SwiftUI

struct ReferralCardAnimatedGradientView: View {

    enum AnimationPosition {
        case topLeading
        case bottomLeading
        case bottomTrailing
        case topTrailing

        var verticalPosition: CGFloat {
            switch self {
            case .topLeading:
                return -1
            case .bottomLeading:
                return +1
            case .bottomTrailing:
                return +1
            case .topTrailing:
                return -1
            }
        }

        var horizontalPosition: CGFloat {
            switch self {
            case .topLeading:
                return -1
            case .bottomLeading:
                return -1
            case .bottomTrailing:
                return +1
            case .topTrailing:
                return +1
            }
        }
    }

    let animationSequence: [AnimationPosition] = [.topLeading, .topTrailing, .bottomTrailing, .bottomLeading]

    @State private var currentAnimationPosition: Int = 0
    @State private var currentAnimation: AnimationPosition = .topLeading

    private func nextAnimation() {
        currentAnimationPosition += 1
        if currentAnimationPosition < animationSequence.count {
            currentAnimation = animationSequence[currentAnimationPosition]
            return
        }
        currentAnimationPosition = 0
        currentAnimation = animationSequence[currentAnimationPosition]
    }

    var body: some View {
        GeometryReader(content: { geometry in
            ZStack() {
                LinearGradient(
                    stops: Constants.gradientStops,
                    startPoint: UnitPoint(x: 0.12, y: 0),
                    endPoint: UnitPoint(x: 0.89, y: 0.95)
                )
                .clipShape(Circle())
                .blur(radius: 30)
                .opacity(0.75)
                .ignoresSafeArea()
                .offset(x: currentAnimation.horizontalPosition * geometry.size.width / 2,
                        y: currentAnimation.verticalPosition * geometry.size.height / 2)
                LinearGradient(
                    stops: Constants.gradientStops,
                    startPoint: UnitPoint(x: 0.29, y: 0.19),
                    endPoint: UnitPoint(x: 0.87, y: 1.18)
                )
                .clipShape(Circle())
                .blur(radius: 30)
                .opacity(0.75)
                .ignoresSafeArea()
                .offset(x: -1 * currentAnimation.horizontalPosition * geometry.size.width / 2,
                        y: -1 * currentAnimation.verticalPosition * geometry.size.height / 2)
                .rotationEffect(Angle(degrees: 1.45))
                .opacity(0.75)
            }
            .animation(.easeInOut(duration: Constants.animationDuration), value: currentAnimation)
            .task {
                Task {
                    while true {
                        nextAnimation()
                        try await Task.sleep(nanoseconds: UInt64(Constants.animationDuration) * 1_000_000_000)
                    }
                }
            }
            .background(.black)
        })
        .clipped()
    }

    enum Constants {
        static let gradientStops: [Gradient.Stop] = [
            Gradient.Stop(color: Color(red: 0.25, green: 0.11, blue: 0.92), location: 0.00),
            Gradient.Stop(color: Color(red: 0.68, green: 0.89, blue: 0.86), location: 0.24),
            Gradient.Stop(color: Color(red: 0.87, green: 0.91, blue: 0.53), location: 0.50),
            Gradient.Stop(color: Color(red: 0.91, green: 0.35, blue: 0.26), location: 0.76),
            Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.1), location: 1.00),
        ]

        static let animationDuration: TimeInterval = 5
    }
}

#Preview {
    Rectangle()
        .foregroundColor(.blue.opacity(0.2))
        .background {
            ReferralCardAnimatedGradientView()
        }
        .overlay(alignment: .bottomLeading) {
            Text("Sergio").padding()
        }
        .cornerRadius(15)
        .frame(width: 315, height: 200)

}
