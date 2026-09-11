import PocketCastsServer
import SwiftUI

/// How big the image a What's New page is built around draws.
enum WhatsNewImageLayout {
    /// The share of a page the design gives its screenshot, which leaves room for the text beneath.
    private static let heightFraction: CGFloat = 0.52

    /// As wide as the page allows, but never so tall that it pushes what follows it off the page.
    static func size(aspectRatio: CGFloat, in contentSize: CGSize) -> CGSize {
        let height = min(contentSize.height * heightFraction, contentSize.width / aspectRatio)
        return CGSize(width: height * aspectRatio, height: height)
    }
}

/// The image a What's New page is built around, sized from the dimensions the catalog published so
/// the page doesn't reflow around it once it loads.
struct WhatsNewImageView: View {
    let image: WhatsNewImage
    let contentSize: CGSize

    var body: some View {
        let size = WhatsNewImageLayout.size(aspectRatio: image.aspectRatio, in: contentSize)

        AsyncImageView(url: image.url,
                       cache: ImageManager.sharedManager.discoverCache,
                       aspectRatio: image.aspectRatio,
                       contentMode: .fit)
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: .infinity)
            .accessibilityLabel(image.alt)
            .accessibilityAddTraits(.isImage)
    }
}
