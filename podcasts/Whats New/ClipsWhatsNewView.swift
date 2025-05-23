import SwiftUI

struct ClipsWhatsNewView: View {
    @State private var isVisible = false

    enum Constants {
        static var previewSize: CGSize = CGSize(width: 138, height: 175)
        static var fadeInDuration: Double = 0.8 // Used for fade-in of preview + delay of logos
    }

    let logos = [
        AnimatedLogoImageView.Logo(image: "whatsnew_clips_tumblr", distance: (x: -30, y: -46), from: Constants.previewSize.midPoint),
        AnimatedLogoImageView.Logo(image: "whatsnew_clips_whatsapp", distance: (x: 32, y: -53), from: Constants.previewSize.midPoint),
        AnimatedLogoImageView.Logo(image: "whatsnew_clips_instagram", distance: (x: 40, y: 10), from: Constants.previewSize.midPoint),
        AnimatedLogoImageView.Logo(image: "whatsnew_clips_telegram", distance: (x: -40, y: 0), from: Constants.previewSize.midPoint)
    ]

    var body: some View {
        ZStack {
            ForEach(Array(logos.enumerated()), id: \.self.element.image) { (idx, logo) in
                AnimatedLogoImageView(logo: logo, index: idx, delay: Constants.fadeInDuration)
            }
            VStack {
                Spacer()
                Image("whatsnew_clip_preview")
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.previewSize.width, height: Constants.previewSize.height)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 10) // Move 10 points up
                    .animation(.easeIn(duration: Constants.fadeInDuration), value: isVisible)
                Spacer()
            }
        }
        .onAppear {
            isVisible = true
        }
    }
}

struct AnimatedLogoImageView: View {
    struct Logo {
        let image: String
        let offset: (x: CGFloat, y: CGFloat)

        init(image: String, distance: (x: CGFloat, y: CGFloat), from point: CGPoint) {
            self.image = image
            self.offset = (x: point.x.adjust(by: distance.x), y: point.y.adjust(by: distance.y))
        }
    }

    let logo: Logo
    /// The index of the current logo, used in combination with `Constants.logoDelay` to determine when to begin animation
    let index: Int
    /// A delay until the logo animation should begin
    let delay: Double

    enum Constants {
        /// The delay in between logos animating in
        static var logoDelay: TimeInterval = 0.1
        /// The delay in between loops of the logo animations
        static var loopDelay: TimeInterval = 3
    }

    @State private var animatedOut = false

    var body: some View {
        Image(logo.image)
            .resizable()
            .scaledToFit()
            .frame(height: 40)
            .offset(x: animatedOut ? logo.offset.x : 0, y: animatedOut ? logo.offset.y : 0)
            .opacity(animatedOut ? 1 : 0)
            .animation(.interpolatingSpring(duration: 0.3, bounce: 0.55).delay(delay + (Double(index) * Constants.logoDelay)), value: animatedOut)
            .onAppear {
                startLoopingAnimation()
            }
    }

    private func startLoopingAnimation() {
        withAnimation {
            animatedOut.toggle()
        }

        // Loop the animation with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.loopDelay) {
            startLoopingAnimation()
        }
    }
}

fileprivate extension CGSize {
    /// The center point of this CGSize
    var midPoint: CGPoint {
        let rect = CGRect(origin: .zero, size: self)
        return CGPoint(x: rect.midX, y: rect.midY)
    }
}

fileprivate extension FloatingPoint {
    /// Adjusts this value by a given value by adding the absolute value of `by` and then multiplying by the sign of the `by` value.
    /// - Parameter by: The value to increase this value by. The `sign` of this value is then applied to that increased value.
    /// - Returns: The adjusted value
    func adjust(by: Self) -> Self {
        return (by.sign == .minus ? -1 : 1) * (self + abs(by))
    }
}
