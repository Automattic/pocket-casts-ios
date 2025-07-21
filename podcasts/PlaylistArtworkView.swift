import SwiftUI

struct PlaylistArtworkView: View {
    @EnvironmentObject var theme: Theme
    let urls: [URL]

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
                                image(url: urls[0])
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                                image(url: urls[1])
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                            }
                            HStack(spacing: 0) {
                                image(url: urls[2])
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                                image(url: urls[3])
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                            }
                        }
                    default:
                        image(url: urls[0])
                            .frame(width: size.width, height: size.height)
                            .clipped()
                    }
                }
            }
            .cornerRadius(4)
            .clipped()
        }
    }

    @ViewBuilder
    func image(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                Color.clear
            }
        }
    }
}
