import SwiftUI
import CoreImage.CIFilterBuiltins

/// Prompts a signed-out viewer to create a free account by scanning a QR code
/// with their phone, then drives the device-pairing flow (shared with
/// ``SignInView``): it owns a ``PairingSession`` that fetches a device code,
/// renders it as the QR the viewer scans, and polls until the phone approves —
/// at which point the screen dismisses and the app moves on to syncing the new
/// account.
///
/// Two layouts share this flow, selected via ``Style``:
/// - ``Style/fullScreen``: a full-screen page with the title up top, the QR
///   centered, and the onboarding steps in a row pinned to the bottom.
/// - ``Style/modal``: a compact card (shown in a sheet) with the QR on the
///   leading side and the steps listed down the trailing side.
struct CreateAccountView: View {

    /// Selects how the QR code and onboarding steps are arranged.
    enum Style {
        /// Full-screen page; the steps sit in a horizontal row pinned to the bottom.
        case fullScreen
        /// Compact card, sized for presentation in a sheet.
        case modal
    }

    let style: Style

    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss

    /// The QR / device-pairing flow, shared with the sign-in screen.
    @State private var pairing = PairingSession()

    /// The ordered onboarding steps shown alongside the QR code. Only the first
    /// is the viewer's to act on (scan); the phone and TV handle the rest.
    private let steps = [
        L10n.tvCreateAccountModalStepScan,
        L10n.tvCreateAccountModalStepCreate,
        L10n.tvCreateAccountModalStepSignIn
    ]

    var body: some View {
        layout
            .task {
                await pairing.start()
            }
            .onChange(of: pairing.state) {
                if case .finished = pairing.state {
                    finish()
                }
            }
    }

    @ViewBuilder private var layout: some View {
        switch style {
        case .fullScreen:
            fullScreenLayout
        case .modal:
            modalLayout
        }
    }

    private func finish() {
        dismiss()
        coordinator.state = .userSync
    }

    // MARK: - Full screen

    private var fullScreenLayout: some View {
        VStack(spacing: 64) {
            Spacer()
            fullScreenHeader
            if case .error(_, let message) = pairing.state {
                pairingError(message: message)
            } else {
                QRCodeTile(url: pairing.pairURLComplete)
            }
            Spacer()
            fullScreenSteps
        }
        .padding(80)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fullScreenHeader: some View {
        VStack(spacing: 16) {
            Text(L10n.tvCreateAccountTitle)
                .font(.title3.weight(.medium))
                .foregroundStyle(Color.pcTextPrimary)
            Text(L10n.tvCreateAccountQrInstruction)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.pcTextSecondary)
        }
        .multilineTextAlignment(.center)
    }

    /// The onboarding steps laid out in a row, chained by arrows.
    private var fullScreenSteps: some View {
        HStack(spacing: 24) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                if index > 0 {
                    Image(systemName: "arrow.right")
                        .font(.body)
                        .foregroundStyle(Color.pcTextDisabled)
                }
                stepBadge(number: index + 1, text: step)
            }
        }
    }

    // MARK: - Modal

    private var modalLayout: some View {
        VStack(alignment: .leading, spacing: 64) {
            modalHeader
            if case .error(_, let message) = pairing.state {
                pairingError(message: message)
            } else {
                HStack(alignment: .center, spacing: 64) {
                    QRCodeTile(url: pairing.pairURLComplete)
                    modalSteps
                }
            }
        }
        .padding(80)
        .frame(width: 952, alignment: .leading)
    }

    private var modalHeader: some View {
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

    private var modalSteps: some View {
        VStack(alignment: .leading, spacing: 40) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                stepBadge(number: index + 1, text: step)
            }
        }
    }

    // MARK: - Shared

    /// A numbered step: a dimmed circular badge and its label.
    private func stepBadge(number: Int, text: String) -> some View {
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

    /// Shown in place of the QR code and steps when the device-pairing request
    /// fails, mirroring the sign-in screen's error treatment and reusing its
    /// strings.
    private func pairingError(message: String) -> some View {
        ContentUnavailableView {
            Label(L10n.tvSignInQrCodeErrorTitle, systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button {
                Task {
                    await pairing.start()
                }
            } label: {
                Text(L10n.tryAgain)
                    .frame(minWidth: 300)
            }
        }
    }
}

/// Renders the device-pairing QR code onto a white rounded tile. Shows a
/// spinner until the device code arrives, and regenerates whenever the code
/// changes (e.g. after the previous one expires or "Try Again" is tapped).
private struct QRCodeTile: View {

    enum Layout {
        static let tileSize = CGFloat(268)
        static let padding = CGFloat(22)
        static let cornerRadius = CGFloat(24)
    }

    /// The pairing URL to encode, or `nil` while the device code is being fetched.
    let url: String?

    @State private var image: UIImage?

    // A single reusable context — allocating one per render is wasteful.
    private let context = CIContext()

    var body: some View {
        Group {
            if let image {
                // The white QR tile only appears once the code has loaded.
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .padding(Layout.padding)
                    .frame(width: Layout.tileSize, height: Layout.tileSize)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
            } else {
                // While the code is being fetched, show a spinner in the QR's
                // place rather than an empty white tile. Same footprint so the
                // layout doesn't shift once the QR arrives.
                ProgressView()
                    .frame(width: Layout.tileSize, height: Layout.tileSize)
            }
        }
        // Regenerate whenever the code changes — including the first time it
        // arrives — and clear the image while we're waiting on a new one so the
        // tile falls back to the spinner rather than showing a stale QR.
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

#Preview("Full Screen") {
    CreateAccountView(style: .fullScreen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pcBackgroundSurface)
        .environment(AppCoordinator())
}

#Preview("Modal") {
    @Previewable @State var isPresented = true

    CreateAccountPreviewBackdrop()
        .sheet(isPresented: $isPresented) {
            CreateAccountView(style: .modal)
                .environment(AppCoordinator())
        }
}

/// A grid of podcast covers used purely to give the modal preview a realistic
/// backdrop, mirroring the welcome screen's artwork grid.
private struct CreateAccountPreviewBackdrop: View {
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
