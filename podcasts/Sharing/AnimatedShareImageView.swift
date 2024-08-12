import SwiftUI
import PocketCastsDataModel

class AnimationProgress: ObservableObject {
    @Published var progress: Double = 0 // O-1
}

struct AnimatedShareImageView: AnimatableContent {
    let info: ShareImageInfo
    let style: ShareImageStyle

    @State var angle: Double = 0
    @ObservedObject var animationProgress: AnimationProgress = .init()

    var body: some View {
        ZStack {
            ShareImageView(info: info, style: style, angle: $angle)
                .onReceive(animationProgress.$progress) { progress in
                    let calculatedAngle = calculateAngle(progress: Float(progress))
                    angle = Double(calculatedAngle)
                }
                .scaleEffect(CGSize(width: 2.0, height: 2.0))
        }
    }

    func update(for progress: Double) {
        animationProgress.progress = progress
    }

    private func calculateAngle(progress: Float) -> Float {
        let speed: Float = 1
        let angle = (progress * 360 * speed).truncatingRemainder(dividingBy: 360)
        return angle
    }
}
