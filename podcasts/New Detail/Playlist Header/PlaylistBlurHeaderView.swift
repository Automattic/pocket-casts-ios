import SwiftUI

struct PlaylistBlurHeaderView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: PlaylistDetailViewModel

    var body: some View {
        GeometryReader { proxy in
            HStack {
                Spacer()
                PlaylistArtworkView(items: viewModel.images, imageSize: 168)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                .blur(radius: 60)
                Spacer()
            }
        }
    }
}
