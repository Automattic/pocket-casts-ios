import PocketCastsUtils
import SwiftUI

struct LinearProgressView: View {
    var tintColor: Color
    @Binding var progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Color.background
                    .clipShape(Capsule())

                tintColor
                    .clipShape(Capsule())
                    .frame(width: geo.size.width * progress)
            }
            .accessibilityLabel(L10n.accessibilityPercentCompleteFormat(progress.localized(.spellOut)))
        }
        .frame(height: 4)
    }
}
