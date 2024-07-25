import SwiftUI

struct PlayheadView: View {
    @Binding var position: CGFloat

    // Represents the true offset position. Any updates to `position` will be ignored will drag is occurring.
    @State private var realPosition: CGFloat = 0
    @State private var lastTranslation: CGFloat?

    var body: some View {
        Rectangle()
            .fill(Color.white)
            .offset(x: realPosition)
            .onTapGesture {} // This is needed to ensure parent ScrollView doesn't intercept
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let currentTranslation = value.translation.width
                        let delta = currentTranslation - (lastTranslation ?? 0)
                        realPosition = realPosition + delta
                        lastTranslation = currentTranslation
                    }
                    .onEnded { _ in
                        lastTranslation = nil
                        position = realPosition
                    }
            )
            .onChange(of: position) { position in
                // Only update playhead when not dragging
                if lastTranslation == nil {
                    realPosition = position
                }
            }
    }
}
