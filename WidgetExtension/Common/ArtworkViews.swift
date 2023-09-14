import SwiftUI

struct LargeArtworkView: View {
    @State var imageData: Data?

    var showShadow: Bool = true

    var body: some View {
        ZStack {
            if showShadow {
                Rectangle()
                    .foregroundColor(Color.nowPlayingShadowColor)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxHeight: 74)
                    .cornerRadius(9)
                    .secondaryShadow()
            }

            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxHeight: 74)
                    .cornerRadius(8)
                    .if(showShadow) { view in
                        view.artworkShadow()
                    }
            } else {
                Image("no-podcast-artwork")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxHeight: 74)
                    .cornerRadius(8)
                    .if(showShadow) { view in
                        view.artworkShadow()
                    }
            }
        }
    }
}

struct SmallArtworkView: View {
    @State var imageData: Data?
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.nowPlayingShadowColor)
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(5)
                .secondaryShadow()
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(4)
                    .artworkShadow()
            } else {
                Image("no-podcast-artwork")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(4)
                    .artworkShadow()
            }
        }
    }
}

struct ArtworkShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.nowPlayingShadowColor.opacity(0.08), radius: 16, x: 0, y: 3)
    }
}

struct SecondaryShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.nowPlayingShadowColor.opacity(0.25), radius: 2, x: 0, y: 1)
    }
}

extension View {
    func artworkShadow() -> some View {
        modifier(ArtworkShadow())
    }

    func secondaryShadow() -> some View {
        modifier(SecondaryShadow())
    }
}

extension Color {
    static let nowPlayingShadowColor = Color("NowPlayingShadow")
}
