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

    var body: some View {
        layout
            .task {
                Analytics.track(.createAccountShown)
                await pairing.start()
            }
            .onChange(of: pairing.state) {
                switch pairing.state {
                case .finished:
                    finish()
                case .error(let error, _):
                    Analytics.track(.userAccountCreationFailed, properties: ["error_code": (error as NSError).code])
                default:
                    break
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
            fullScreenHeader
            if case .error(_, let message) = pairing.state {
                pairingError(message: message)
            }
            else {
                HStack(alignment: .center, spacing: 64) {
                    QRCodeView(url: pairing.pairURLComplete)
                    StepList(steps: steps)
                }
                QRCodeDigits(digits: pairing.codes)
            }
        }
        .padding(80)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fullScreenHeader: some View {
        Text(L10n.tvCreateAccountTitle)
            .font(.title3.weight(.medium))
            .foregroundStyle(Color.pcTextPrimary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Modal

    private var modalLayout: some View {
        VStack(alignment: .center, spacing: 64) {
            modalHeader
            if case .error(_, let message) = pairing.state {
                pairingError(message: message)
            } else {
                HStack(alignment: .center, spacing: 64) {
                    QRCodeView(url: pairing.pairURLComplete)
                    StepList(steps: steps, spacing: 40)
                }
                QRCodeDigits(digits: pairing.codes)
            }
        }
        .padding(80)
        .frame(width: 1200, alignment: .leading)
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

    var steps: [String] {
        [
            L10n.tvCreateAccountStepScan(pairing.pairURLPretty),
            L10n.tvCreateAccountStepCreate,
            L10n.tvCreateAccountStepConfirmCode
        ]
    }

    // MARK: - Shared

    private func pairingError(message: String) -> some View {
        ContentUnavailableView {
            Label(L10n.tvLogInQrCodeErrorTitle, systemImage: "wifi.exclamationmark")
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
