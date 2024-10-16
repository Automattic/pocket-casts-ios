import SwiftUI
import PocketCastsDataModel

@MainActor
class AnimationProgress: ObservableObject {
    @Published var progress: Double = 0 // O-1
}

struct AnimatedShareImageView: AnimatableContent {
    let info: ShareImageInfo
    let style: ShareImageStyle
    let size: CGSize

    @State var angle: Double = 0
    @ObservedObject var animationProgress: AnimationProgress = .init()

    var body: some View {
        ShareImageView(info: info, style: style, angle: $angle)
            .frame(width: size.width, height: size.height)
            .onReceive(animationProgress.$progress) { progress in
                let calculatedAngle = calculateAngle(progress: Float(progress))
                angle = Double(calculatedAngle)
            }
    }

    func update(for progress: Double) {
        animationProgress.progress = progress
    }

    private func calculateAngle(progress: Float) -> Float {
        let speed: Float = 0.5
        let angle = (progress * 360 * speed).truncatingRemainder(dividingBy: 360)
        return angle
    }
}
