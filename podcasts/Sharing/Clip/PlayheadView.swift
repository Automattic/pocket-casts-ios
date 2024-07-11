import SwiftUI

struct PlayheadView: View {
    @Binding var position: CGFloat
    var onChanged: (CGFloat) -> Void

    var body: some View {
        Rectangle()
            .fill(Color.white)
            .offset(x: position)
            .onTapGesture {} // This is needed to ensure parent ScrollView doesn't intercept
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        onChanged(value.location.x)
                    }
            )
    }
}
