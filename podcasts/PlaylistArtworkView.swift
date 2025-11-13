import SwiftUI
import Kingfisher

struct PlaylistArtworkView: View {
    struct ImageItem {
        let id: String
        let url: URL
    }

    @EnvironmentObject var theme: Theme
    let items: [ImageItem]

    private let cornerRadius: CGFloat

    init(
        items: [ImageItem],
        cornerRadius: CGFloat = 4
    ) {
        self.items = items
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                Rectangle()
                    .foregroundColor(theme.primaryUi05)
                if items.isEmpty {
                    Image("playlist_list_icon")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(theme.primaryIcon03)
                        .frame(width: size.width * 0.4, height: size.height * 0.4)
                } else {
                    switch items.count {
                    case 4:
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                AsyncImageView(url: items[0].url, cacheKey: items[0].id)
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                                AsyncImageView(url: items[1].url, cacheKey: items[1].id)
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                            }
                            HStack(spacing: 0) {
                                AsyncImageView(url: items[2].url, cacheKey: items[2].id)
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                                AsyncImageView(url: items[3].url, cacheKey: items[3].id)
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                            }
                        }
                    default:
                        AsyncImageView(url: items[0].url, cacheKey: items[0].id)
                            .frame(width: size.width, height: size.height)
                            .clipped()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}
