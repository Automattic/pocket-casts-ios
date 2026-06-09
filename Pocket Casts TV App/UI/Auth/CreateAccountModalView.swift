import SwiftUI
import CoreImage.CIFilterBuiltins
import PocketCastsServer

/// A modal card that nudges a signed-out viewer to create a free account by
/// scanning a QR code with their phone. Matches the "Your podcasts deserve a
/// home" design: a frosted card with the QR code on the leading side and the
/// three onboarding steps on the trailing side.
///
/// The QR code is currently a placeholder pointing at the marketing create
/// URL — the real device-pairing flow is not wired up yet.
struct CreateAccountModalView: View {

    /// The ordered steps shown next to the QR code.
    private let steps = [
        L10n.tvCreateAccountModalStepScan,
        L10n.tvCreateAccountModalStepCreate,
        L10n.tvCreateAccountModalStepSignIn
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 64) {
            header
            HStack(alignment: .center, spacing: 64) {
                // TODO: Replace the placeholder QR code with the real
                // device-pairing QR once the pairing flow is implemented.
                PlaceholderQRCode(url: ServerConstants.Urls.tvCreate)
                stepsList
            }
        }
        .padding(80)
        .frame(width: 952, alignment: .leading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.tvCreateAccountModalTitle)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(Color.pcTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text(L10n.tvCreateAccountModalSubtitle)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(Color.pcTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var stepsList: some View {
        VStack(alignment: .leading, spacing: 40) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                stepRow(number: index + 1, text: step)
            }
        }
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption2)
                .foregroundStyle(Color.pcTextSecondary)
                .frame(width: 40, height: 40)
                .background(Color.pcBackgroundActive50, in: Circle())
            Text(text)
                .font(.body)
                .foregroundStyle(Color.pcTextSecondary)
        }
        // Read each step as a single unit ("1, Scan the QR code") rather than
        // letting VoiceOver land on the bare number badge separately.
        .accessibilityElement(children: .combine)
    }
}

/// Renders a QR code synchronously onto a white rounded tile. Used as a
/// stand-in until the real device-pairing QR code is available.
private struct PlaceholderQRCode: View {

    enum Layout {
        static let tileSize = CGFloat(268)
        static let padding = CGFloat(22)
        static let cornerRadius = CGFloat(24)
    }

    let url: String

    @State private var image: UIImage?

    // A single reusable context — allocating one per render is wasteful.
    private let context = CIContext()

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                Color.white
            }
        }
        .padding(Layout.padding)
        .frame(width: Layout.tileSize, height: Layout.tileSize)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
        // Generate once and cache the result rather than rebuilding the QR on
        // every body re-evaluation. Done synchronously (the work is cheap) so
        // the tile is never empty, including in preview snapshots.
        .onAppear {
            if image == nil {
                image = makeImage(from: url)
            }
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

#Preview("Sheet") {
    @Previewable @State var isPresented = true

    CreateAccountModalPreviewBackdrop()
        .sheet(isPresented: $isPresented) {
            CreateAccountModalView()
        }
}

/// A grid of podcast covers used purely to give the modal previews a realistic
/// backdrop, mirroring the welcome screen's artwork grid.
private struct CreateAccountModalPreviewBackdrop: View {
    private let covers: [String] = (0..<48).map { "Covers/login-cover-\(($0 % 10) + 1)" }

    var body: some View {
        let columns = Array(repeating: GridItem(.fixed(272), spacing: 16), count: 8)
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Array(covers.enumerated()), id: \.offset) { _, cover in
                Image(cover)
                    .resizable()
                    .frame(width: 272, height: 272)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pcBackgroundSurface)
    }
}
