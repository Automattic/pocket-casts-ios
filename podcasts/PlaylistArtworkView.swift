import SwiftUI

struct PlaylistArtworkView: View {
    @EnvironmentObject var theme: Theme
    let images: [Image]

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                Rectangle()
                    .foregroundColor(theme.primaryUi05)
                if images.isEmpty {
                    Image("playlists_tab")
                        .renderingMode(.template)
                        .foregroundColor(theme.primaryIcon03)
                        .frame(width: size.width, height: size.height)
                } else {
                    switch images.count {
                    case 4:
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                images[0]
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                                images[1]
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                            }
                            HStack(spacing: 0) {
                                images[2]
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                                images[3]
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                            }
                        }
                    default:
                        images[0]
                            .resizable()
                            .scaledToFill()
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
