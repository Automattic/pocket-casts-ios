import SwiftUI
import CoreImage.CIFilterBuiltins

/// Prompts a signed-out viewer to create an account by scanning a QR code with
/// their phone, driving the shared ``PairingSession`` until the phone approves.
/// Two layouts share this flow, selected via ``Style``.
struct CreateAccountView: View {

    enum Style {
        /// Full-screen page; steps in a row pinned to the bottom.
        case fullScreen
        /// Compact card, sized for presentation in a sheet.
        case modal
    }

    let style: Style

    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss

    @State private var pairing = PairingSession()

    private let steps = [
        L10n.tvCreateAccountModalStepScan,
        L10n.tvCreateAccountModalStepCreate,
        L10n.tvCreateAccountModalStepSignIn
    ]

    var body: some View {
        layout
            .task {
                Analytics.track(.createAccountShown)
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
        Analytics.track(.userAccountCreated, properties: ["source": "qr_code"])
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

    private func stepBadge(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption2)
                .foregroundStyle(Color.pcTextSecondary)
                .frame(width: 40, height: 40)
                .background(Color.pcBackgroundActive20, in: Circle())
            Text(text)
                .font(.body)
                .foregroundStyle(Color.pcTextSecondary)
        }
        // Read each step as a single unit rather than landing on the bare badge.
        .accessibilityElement(children: .combine)
    }

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

/// Renders the device-pairing QR code onto a white rounded tile, falling back to
/// a spinner of the same size until the code arrives.
private struct QRCodeTile: View {

    enum Layout {
        static let tileSize = CGFloat(268)
        static let padding = CGFloat(22)
        static let cornerRadius = CGFloat(24)
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

/// A grid of podcast covers, used purely as a backdrop for the modal preview.
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
