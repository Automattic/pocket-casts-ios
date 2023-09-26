import SwiftUI

struct RatePodcastView: View {
    @ObservedObject var viewModel: RatePodcastViewModel

    init(viewModel: RatePodcastViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            Spacer()
            Button("dismiss") { viewModel.presented = false }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .applyDefaultThemeOptions()
    }
}

#Preview {
    RatePodcastView(viewModel: RatePodcastViewModel(presented: .constant(true)))
        .environmentObject(Theme.sharedTheme)
}
