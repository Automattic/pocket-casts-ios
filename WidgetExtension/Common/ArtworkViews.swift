import PocketCastsUtils
import SwiftUI
import UIKit

private func widgetArtworkImage(from imageData: Data?, accented: Bool) -> UIImage? {
    guard let imageData, let image = UIImage(data: imageData) else { return nil }
    guard accented else { return image }
    return WidgetArtworkCache.tintedImage(for: imageData, source: image)
}

private func widgetPlaceholderImage(accented: Bool) -> UIImage {
    let base = UIImage(named: "no-podcast-artwork-transparent")
        ?? UIImage(named: "no-podcast-artwork")
        ?? UIImage()
    return accented ? base.withRenderingMode(.alwaysTemplate) : base
}

/// Caches the result of converting podcast artwork into a luminance-based template,
/// so the expensive pixel pass doesn't run on every SwiftUI body recomputation.
private enum WidgetArtworkCache {
    private static let cache: NSCache<NSData, UIImage> = {
        let cache = NSCache<NSData, UIImage>()
        cache.countLimit = 32
        return cache
    }()

    static func tintedImage(for imageData: Data, source: UIImage) -> UIImage? {
        let key = imageData as NSData
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let processed = source.addingAlphaFromLuminance()?.withRenderingMode(.alwaysTemplate) else {
            return nil
        }
        cache.setObject(processed, forKey: key)
        return processed
    }
}

struct LargeArtworkView: View {
    @Environment(\.isAccentedRenderingMode) var isAccentedRenderingMode

    @State var imageData: Data?
    var size: CGFloat = 74

    var showShadow: Bool = true

    var body: some View {
        ZStack {
            if !isAccentedRenderingMode, showShadow {
                Rectangle()
                    .foregroundColor(Color.nowPlayingShadowColor)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxHeight: size)
                    .cornerRadius(9)
                    .secondaryShadow()
                    .backwardWidgetAccentable(isAccentedRenderingMode)
            }
            if let uiImage = widgetArtworkImage(from: imageData, accented: isAccentedRenderingMode) {
                Image(uiImage: uiImage)
                    .resizable()
                    .backwardWidgetAccentedRenderingMode(isAccentedRenderingMode)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxHeight: size)
                    .cornerRadius(8)
                    .if(!isAccentedRenderingMode && showShadow) { view in
                        view.artworkShadow()
                    }
            } else {
                Image(uiImage: widgetPlaceholderImage(accented: isAccentedRenderingMode))
                    .resizable()
                    .backwardWidgetAccentedRenderingMode(isAccentedRenderingMode)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxHeight: size)
                    .cornerRadius(8)
                    .if(!isAccentedRenderingMode && showShadow) { view in
                        view.artworkShadow()
                    }
            }
        }
    }
}

struct SmallArtworkView: View {
    @Environment(\.isAccentedRenderingMode) var isAccentedRenderingMode

    @State var imageData: Data?

    var body: some View {
        ZStack {
            if !isAccentedRenderingMode {
                Rectangle()
                    .foregroundColor(Color.nowPlayingShadowColor)
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(5)
                    .secondaryShadow()
                    .backwardWidgetAccentable(isAccentedRenderingMode)
            }
            if let uiImage = widgetArtworkImage(from: imageData, accented: isAccentedRenderingMode) {
                Image(uiImage: uiImage)
                    .resizable()
                    .backwardWidgetAccentedRenderingMode(isAccentedRenderingMode)
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(4)
                    .if(!isAccentedRenderingMode) { view in
                        view.artworkShadow()
                    }
            } else {
                Image(uiImage: widgetPlaceholderImage(accented: isAccentedRenderingMode))
                    .resizable()
                    .backwardWidgetAccentedRenderingMode(isAccentedRenderingMode)
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(4)
                    .if(!isAccentedRenderingMode) { view in
                        view.artworkShadow()
                    }
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
