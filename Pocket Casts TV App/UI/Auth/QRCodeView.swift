import SwiftUI
import CoreImage.CIFilterBuiltins

/// Renders the device-pairing QR code onto a white rounded tile, falling back to
/// a spinner of the same size until the code arrives.
struct QRCodeView: View {

    enum Layout {
        static let tileSize = CGFloat(272)
        static let padding = CGFloat(14)
        static let cornerRadius = CGFloat(8)
    }

    /// The pairing URL to encode, or `nil` while the device code is being fetched.
    let url: String?

    @State private var image: UIImage?
    @State private var context = CIContext()

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .padding(Layout.padding)
                    .frame(width: Layout.tileSize, height: Layout.tileSize)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
                    .accessibilityHidden(true)
            } else {
                ProgressView()
                    .frame(width: Layout.tileSize, height: Layout.tileSize)
            }
        }
        // Regenerate on every code change, clearing first so a stale QR isn't
        // shown while the new one is fetched.
        .onChange(of: url, initial: true) { _, url in
            image = url.flatMap(makeImage)
        }
    }

    private func makeImage(from string: String) -> UIImage? {
        let generator = CIFilter.qrCodeGenerator()
        generator.message = Data(string.utf8)
        generator.correctionLevel = "H"
        guard let output = generator.outputImage else { return nil }
        // Scale up so the QR stays crisp when enlarged on a TV screen.
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    QRCodeView(url: "https://pocketcasts.net/pair")
}
