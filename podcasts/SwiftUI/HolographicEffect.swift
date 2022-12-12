import SwiftUI

/// Applies a holographic/foil/rainbow effect to its contents that moves with the device motion
struct HolographicEffect<Content>: View where Content: View {
    @StateObject var motion = MotionManager(options: .attitude)
    private var content: () -> Content
    private let geometry: GeometryProxy
    private let multiplier = 4.0

    init(geometry: GeometryProxy, @ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
        self.geometry = geometry
    }

    var body: some View {
        content()
            .foregroundColor(.clear)
            .background(gradientView)
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
        }
    }

    private var position: CGSize {
        CGSize(width: (motion.roll / .pi * multiplier) * geometry.size.height,
               height: (motion.pitch / .pi * multiplier) * geometry.size.width)
    }

    private func scale(_ size: CGSize) -> Double {
        max(geometry.size.width, geometry.size.height) / radius(size) * multiplier
    }

    private func radius(_ size: CGSize) -> Double {
        min(size.width, size.height) * 0.5
    }

    private let rainbowColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink
    ]
}
