import SwiftUI

struct RatePodcastView: View {
    @Binding var presented: Bool

    var body: some View {
        Group {
            Spacer()
            Button("dismiss") { self.presented = false }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .applyDefaultThemeOptions()
    }
}

#Preview {
    RatePodcastView(presented: .constant(true))
}
