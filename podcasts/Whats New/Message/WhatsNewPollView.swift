import PocketCastsServer
import SwiftUI

/// The questions a poll asks, each above the options it's answered with.
///
/// The button that sends the answers isn't here: it's pinned to the bottom of the page alongside
/// the message's other calls to action, so it stays put while the questions scroll.
struct WhatsNewPollView: View {
    @ObservedObject var viewModel: WhatsNewPollViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            ForEach(viewModel.questions) { question in
                WhatsNewPollQuestionView(question: question, viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WhatsNewPollQuestionView: View {
    @EnvironmentObject private var theme: Theme

    let question: WhatsNewPoll.Question

    @ObservedObject var viewModel: WhatsNewPollViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.text)
                .font(size: 22, style: .title2, weight: .bold)
                .foregroundStyle(theme.primaryText01)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 8) {
                ForEach(question.options) { option in
                    WhatsNewPollOptionView(option: option, isSelected: viewModel.isSelected(option, in: question)) {
                        viewModel.toggle(option, in: question)
                    }
                }
            }
        }
        .disabled(!viewModel.isEditable)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(question.text)
    }
}

/// One option of a question, which fills in once it's chosen.
private struct WhatsNewPollOptionView: View {
    @EnvironmentObject private var theme: Theme
    @ScaledMetric(relativeTo: .headline) private var minimumHeight: CGFloat = 64

    /// The border the design draws around the chosen option, which sits inside its edges rather
    /// than growing the row when it appears.
    private let selectedBorderWidth: CGFloat = 2

    let option: WhatsNewPoll.Option
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                indicator

                Text(option.label)
                    .font(size: 18, style: .headline, weight: .semibold)
                    .foregroundStyle(theme.primaryText01)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .leading)
            .background(theme.primaryUi01Active, in: shape)
            .overlay {
                shape.strokeBorder(isSelected ? theme.primaryField03Active : .clear, lineWidth: selectedBorderWidth)
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 8)
    }

    @ViewBuilder
    private var indicator: some View {
        Group {
            if isSelected {
                // The checkmark is knocked out of the filled circle rather than drawn over it.
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(theme.primaryInteractive02, theme.primaryField03Active)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(theme.primaryIcon02)
            }
        }
        .font(size: 22, style: .title3)
        .accessibilityHidden(true)
    }
}

// MARK: - Sending

/// The button that sends a poll's answers, and what it turns into once they're on their way.
///
/// It sits with the page's calls to action rather than with the questions, so a poll long enough
/// to scroll still has its button in reach.
struct WhatsNewPollSubmitView: View {
    @EnvironmentObject private var theme: Theme
    @ObservedObject var viewModel: WhatsNewPollViewModel

    var body: some View {
        VStack(spacing: 8) {
            if viewModel.state == .failed {
                Text(L10n.whatsNewPollFailed)
                    .font(size: 13, style: .footnote)
                    .foregroundStyle(theme.support05)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if viewModel.state == .sent {
                Text(L10n.whatsNewPollSent)
                    .font(size: 15, style: .subheadline, weight: .semibold)
                    .foregroundStyle(theme.primaryText02)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                submitButton
            }
        }
    }

    private var submitButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            // The spinner takes the label's place without the button changing size under the tap.
            ZStack {
                Text(L10n.whatsNewPollSubmit)
                    .opacity(viewModel.state == .sending ? 0 : 1)

                if viewModel.state == .sending {
                    ProgressView()
                        .tint(theme.primaryInteractive02)
                }
            }
        }
        .buttonStyle(RoundedButtonStyle(theme: theme, isEnabled: viewModel.isComplete))
        .disabled(!viewModel.isComplete || viewModel.state == .sending)
    }
}
