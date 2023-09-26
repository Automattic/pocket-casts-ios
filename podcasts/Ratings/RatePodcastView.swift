import SwiftUI

struct RatePodcastView: View {
    @Binding var presented: Bool

    var body: some View {
        Button("dismiss") { self.presented = false }
    }
}

#Preview {
    RatePodcastView(presented: .constant(true))
}
