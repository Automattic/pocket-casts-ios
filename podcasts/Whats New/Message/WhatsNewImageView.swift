import PocketCastsServer
import SwiftUI

/// How big the image a What's New page is built around draws.
enum WhatsNewImageLayout {
    /// The share of a page the design gives its screenshot, which leaves room for the text beneath.
    private static let heightFraction: CGFloat = 0.52

    /// As wide as the page allows, but never so tall that it pushes what follows it off the page.
    static func size(aspectRatio: CGFloat, in contentSize: CGSize) -> CGSize {
        let height = min(maximumHeight(in: contentSize), contentSize.width / aspectRatio)
        return CGSize(width: height * aspectRatio, height: height)
    }

    /// The tallest an image of unknown shape can draw once it has loaded.
    static func maximumHeight(in contentSize: CGSize) -> CGFloat {
        contentSize.height * heightFraction
    }
}

/// The image a What's New page is built around, sized from the dimensions the catalog published so
/// the page doesn't reflow around it once it loads.
struct WhatsNewImageView: View {
    let image: WhatsNewImage
    let contentSize: CGSize

    var body: some View {
        let aspectRatio = image.aspectRatio.map { CGFloat($0) }
        let size = aspectRatio.map { WhatsNewImageLayout.size(aspectRatio: $0, in: contentSize) }

        AsyncImageView(url: image.url,
                       cache: ImageManager.sharedManager.discoverCache,
                       aspectRatio: aspectRatio,
                       contentMode: .fit)
            .frame(width: size?.width, height: size?.height)
            .frame(maxWidth: contentSize.width, maxHeight: WhatsNewImageLayout.maximumHeight(in: contentSize))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: .infinity)
            .accessibilityLabel(image.alt ?? "")
            .accessibilityAddTraits(.isImage)
            .accessibilityHidden(image.alt == nil)
    }
}
