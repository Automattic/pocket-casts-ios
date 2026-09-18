import PocketCastsServer
import SwiftUI

/// The single poll a research message is built around: a question, the answers it can be given, and
/// the button that sends the one that's picked.
///
/// An account answers once. Sync only records that it did, not what it picked, so a poll answered
/// on another device comes back closed with nothing to point at — which is shown as exactly that
/// rather than as a guess at the answer.
struct WhatsNewPollView: View {
    @EnvironmentObject private var theme: Theme

    let research: WhatsNewResearch

    @ObservedObject var viewModel: WhatsNewMessageViewModel

    /// The gutter the design leaves either side of the poll.
    private let horizontalPadding: CGFloat = 20

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(research.poll.question)
                    .font(size: 22, style: .title2, weight: .bold)
                    .foregroundStyle(theme.primaryText01)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                if let description = research.description {
                    Text(description)
                        .font(size: 15, style: .subheadline)
                        .foregroundStyle(theme.primaryText02)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                }

                VStack(spacing: 8) {
                    ForEach(research.poll.options) { option in
                        WhatsNewPollOptionView(option: option,
                                               isSelected: viewModel.selectedOptionID == option.id,
                                               hasResponded: viewModel.hasResponded) {
                            viewModel.select(option)
                        }
                    }
                }
                .padding(.top, 24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
    }

    /// The button that sends the answer, or what's left once the poll has been answered.
    @ViewBuilder
    private var footer: some View {
        Group {
            if viewModel.hasResponded {
                Text(L10n.whatsNewPollAnswered)
                    .font(size: 15, style: .subheadline)
                    .foregroundStyle(theme.primaryText02)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            } else {
                Button(L10n.continue) {
                    viewModel.submitResponse()
                }
                .buttonStyle(RoundedButtonStyle(theme: theme, isEnabled: viewModel.canSubmitResponse))
                .disabled(!viewModel.canSubmitResponse)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(theme.primaryUi01)
    }
}

/// One answer the poll can be given, which stops being a button once the poll is answered.
private struct WhatsNewPollOptionView: View {
    @EnvironmentObject private var theme: Theme
    @ScaledMetric(relativeTo: .body) private var minimumHeight: CGFloat = 64

    let option: WhatsNewPoll.Option
    let isSelected: Bool
    let hasResponded: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: 12) {
                selectionIndicator

                Text(option.label)
                    .font(size: 18, style: .body, weight: .semibold)
                    .foregroundStyle(theme.primaryText01)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .leading)
            .background(theme.primaryUi01Active)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(theme.primaryField03Active, lineWidth: 2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(hasResponded)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        Group {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(theme.primaryInteractive02, theme.primaryField03Active)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(theme.primaryUi05)
            }
        }
        .font(.system(size: 22))
        .accessibilityHidden(true)
    }
}
