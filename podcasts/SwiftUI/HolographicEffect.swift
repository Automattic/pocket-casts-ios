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
