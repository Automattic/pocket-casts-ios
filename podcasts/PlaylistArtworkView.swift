import SwiftUI
import Kingfisher

struct PlaylistArtworkView: View {
    @EnvironmentObject var theme: Theme
    let urls: [URL]

    private let imageSize: Int

    init(
        urls: [URL],
        imageSize: Int
    ) {
        self.urls = urls
        self.imageSize = imageSize
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                Rectangle()
                    .foregroundColor(theme.primaryUi05)
                if urls.isEmpty {
                    Image("playlists_tab")
                        .renderingMode(.template)
                        .foregroundColor(theme.primaryIcon03)
                        .frame(width: size.width, height: size.height)
                } else {
                    switch urls.count {
                    case 4:
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                AsyncImageView(url: urls[0], size: imageSize)
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                                AsyncImageView(url: urls[1], size: imageSize)
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                            }
                            HStack(spacing: 0) {
                                AsyncImageView(url: urls[2], size: imageSize)
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                                AsyncImageView(url: urls[3], size: imageSize)
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                            }
                        }
                    default:
                        AsyncImageView(url: urls[0], size: imageSize)
                            .frame(width: size.width, height: size.height)
                            .clipped()
                    }
                }
            }
            .cornerRadius(4)
            .clipped()
        }
    }
}
