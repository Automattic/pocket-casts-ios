import SwiftUI
import UIKit

extension UIImage {
    /// Converts white/light pixels to transparent, useful for logos on white backgrounds
    func addingAlphaFromLuminance() -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Convert luminance to alpha
        for i in stride(from: 0, to: pixelData.count, by: 4) {
            let r = Double(pixelData[i])
            let g = Double(pixelData[i + 1])
            let b = Double(pixelData[i + 2])
            let luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0

            // Invert: dark pixels become opaque, light pixels become transparent
            pixelData[i + 3] = UInt8((1.0 - luminance) * 255)
        }

        guard let outputCGImage = context.makeImage() else { return nil }
        return UIImage(cgImage: outputCGImage, scale: self.scale, orientation: self.imageOrientation)
    }
}

struct LargeArtworkView: View {
    @Environment(\.isAccentedRenderingMode) var isAccentedRenderingMode

    @State var imageData: Data?
    var size: CGFloat = 74

    var showShadow: Bool = true

    var imageToUse: UIImage? {
        return nil
        guard let imageData else {
            return nil
        }
        if isAccentedRenderingMode {
            return UIImage(data: imageData)?.addingAlphaFromLuminance()
        } else {
            return UIImage(data: imageData)
        }
    }

    var placeholderImageToUse: UIImage? {
        if isAccentedRenderingMode {
            return UIImage(named: "no-podcast-artwork-transparent")
        } else {
            return UIImage(named: "no-podcast-artwork-transparent")
        }
    }

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
            if let uiImage = imageToUse {
                Image(uiImage: uiImage)
                    .resizable()
                    .if(isAccentedRenderingMode) { content in
                        content.backwardWidgetAccentedRenderingMode(isAccentedRenderingMode)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxHeight: size)
                    .cornerRadius(8)
                    .if(showShadow) { view in
                        view.artworkShadow()
                    }
            } else {
                Image(uiImage: placeholderImageToUse!)
                    .resizable()
                    .if(isAccentedRenderingMode) { content in
                        content
                            .renderingMode(.template)
                            .backwardWidgetAccentedRenderingMode(isAccentedRenderingMode)
                    }
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

    var imageToUse: UIImage? {
        guard let imageData else {
            return nil
        }
        if isAccentedRenderingMode {
            return UIImage(data: imageData)?.addingAlphaFromLuminance()?.withRenderingMode(.alwaysTemplate)
        } else {
            return UIImage(data: imageData)
        }
    }

    var placeholderImageToUse: UIImage? {
        if isAccentedRenderingMode {
            return UIImage(named: "no-podcast-artwork-transparent")
        } else {
            return UIImage(named: "no-podcast-artwork-transparent")
        }
    }

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
            if let uiImage = imageToUse {
                Image(uiImage: uiImage)
                    .resizable()
                    .if(isAccentedRenderingMode) { content in
                        content.backwardWidgetAccentedRenderingMode(isAccentedRenderingMode)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(4)
                    .artworkShadow()
            } else {
                Image(uiImage: placeholderImageToUse!)
                    .resizable()
                    .if(isAccentedRenderingMode) { content in
                        content
                            .backwardWidgetAccentable(isAccentedRenderingMode)
                    }
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
