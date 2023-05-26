import SwiftUI

/// Applies a holographic/foil/rainbow effect to its contents that moves with the device motion
struct HolographicEffect<Content>: View where Content: View {
    @StateObject var motion = MotionManager(options: .attitude)

    var parentSize: CGSize = UIScreen.main.bounds.size
    var mode: Mode = .background
    let content: () -> Content

    private let multiplier = 4.0

    var body: some View {
        content()
            .foregroundColor(mode == .background ? .clear : nil)
            .overlay(mode == .overlay ? gradientView.blendMode(.overlay) : nil)
            .background(mode == .background ? gradientView : nil)
            .onAppear() {
                motion.start()
            }.onDisappear() {
                motion.stop()
            }
    }

    @ViewBuilder
    private var gradientView: some View {
        GeometryReader { proxy in
            // make tighter rings
            let colors = rainbowColors + rainbowColors + rainbowColors
            RadialGradient(colors: colors, center: .center, startRadius: 0, endRadius: radius(proxy.size))
                .scaleEffect(scale(proxy.size))
                .offset(position)
                .mask(content())
        }.allowsHitTesting(false)
    }

    enum Mode {
        case overlay, background
    }

    private var position: CGSize {
        CGSize(width: (motion.roll / .pi * multiplier) * parentSize.height,
               height: (motion.pitch / .pi * multiplier) * parentSize.width)
    }

    private func scale(_ size: CGSize) -> Double {
        max(parentSize.width, parentSize.height) / radius(size) * multiplier
    }

    private func radius(_ size: CGSize) -> Double {
        min(size.width, size.height) * 0.5
    }

    private let rainbowColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink
    ]
}

// MARK: - Glossy Effect

/// Simulates a lighting reflection effect that makes the contents look glossier
struct GlossyEffect<Content: View>: View {
    @StateObject var motion = MotionManager(options: .attitude)
    let content: () -> Content

    var body: some View {
        content()
            .overlay(gradientView)
            .onAppear { motion.start() }
            .onDisappear() { motion.stop() }
    }

    @ViewBuilder
    private var gradientView: some View {
        GeometryReader { proxy in
            RadialGradient(colors: colors, center: .center, startRadius: 0, endRadius: radius(proxy.size))
                .scaleEffect(scale(proxy.size) * 2)
                .offset(x: CGFloat(-motion.roll * 5) * proxy.size.width,
                        y: CGFloat(-motion.pitch * 3) * proxy.size.height*0.2)
                .mask(alignment: .center, content)
                .opacity(0.3)
        }.allowsHitTesting(false)
    }

    private func scale(_ size: CGSize) -> Double {
        max(size.width, size.height) / radius(size) * 4
    }

    private func radius(_ size: CGSize) -> Double {
        min(size.width, size.height) * 0.5
    }

    private let colors: [Color] = [
        // The clear colors in the beginning reduces the shiny effect initially
        .white.opacity(0.0),
        .white.opacity(0.0),
        .white.opacity(0.0),

        // Create a glossy band
        .white.opacity(0.5),
        .white.opacity(0.3),
        .white.opacity(0.2),

        // More clear colors to create a banding effect
        .white.opacity(0.0),
        .white.opacity(0.0),

        // Create another glossy band
        .white.opacity(0.5),
        .white.opacity(0.3),
        .white.opacity(0.2),

        // More clear colors to create a banding effect
        .white.opacity(0.0),
        .white.opacity(0.0),
    ]
}

struct HolographicEffect_Previews: PreviewProvider {
    static var previews: some View {
        PreviewContent()
    }

    struct PreviewContent: View {
        var body: some View {
            VStack(spacing: 20) {
                Text("Holographic Effect")
                HolographicEffect(mode: .background) {
                    Image("heart")
                        .renderingMode(.template)
                }
                .padding()
                .background(Color.black)


                Text("Glossy Effect")
                GlossyEffect {
                    Image("AppIcon-Default")
                        .cornerRadius(20)
                        .shadow(radius: 5)
                }
            }
        }
    }
}
