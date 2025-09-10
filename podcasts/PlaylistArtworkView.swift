import SwiftUI
import Kingfisher

struct PlaylistArtworkView: View {
    struct ImageItem {
        let id: String
        let url: URL
    }

    @EnvironmentObject var theme: Theme
    let items: [ImageItem]

    private let imageSize: Int

    init(
        items: [ImageItem],
        imageSize: Int
    ) {
        self.items = items
        self.imageSize = imageSize
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                Rectangle()
                    .foregroundColor(theme.primaryUi05)
                if items.isEmpty {
                    Image("playlists_tab")
                        .renderingMode(.template)
                        .foregroundColor(theme.primaryIcon03)
                        .frame(width: size.width, height: size.height)
                } else {
                    switch items.count {
                    case 4:
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                AsyncImageView(url: items[0].url, cacheKey: items[0].id, size: imageSize)
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                                AsyncImageView(url: items[1].url, cacheKey: items[1].id, size: imageSize)
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                            }
                            HStack(spacing: 0) {
                                AsyncImageView(url: items[2].url, cacheKey: items[2].id, size: imageSize)
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                                AsyncImageView(url: items[3].url, cacheKey: items[3].id, size: imageSize)
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                            }
                        }
                    default:
                        AsyncImageView(url: items[0].url, cacheKey: items[0].id, size: imageSize)
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
