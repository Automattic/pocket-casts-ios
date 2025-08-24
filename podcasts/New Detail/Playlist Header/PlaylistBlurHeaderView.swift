import SwiftUI

struct PlaylistBlurHeaderView: View {
    @EnvironmentObject var theme: Theme
    @StateObject var viewModel: PlaylistDetailViewModel

    var body: some View {
        GeometryReader { proxy in
            HStack {
                Spacer()
                PlaylistArtworkView(urls: viewModel.imageURLs, imageSize: 168)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                .blur(radius: 60)
                Spacer()
            }
        }
    }
}
