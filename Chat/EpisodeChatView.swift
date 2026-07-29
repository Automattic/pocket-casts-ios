import SwiftUI

struct EpisodeChatView: View {
    @ObservedObject var viewModel: EpisodeChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider().background(Color(ThemeColor.playerContrast04()))

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.showSuggestions {
                            suggestionsView
                                .transition(.opacity)
                        }

                        ForEach(viewModel.messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }

                        if viewModel.isTyping {
                            TypingIndicatorView()
                                .id("typing")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .onChange(of: viewModel.messages.count) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        if let lastMessage = viewModel.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.isTyping) {
                    if viewModel.isTyping {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
            }

            Divider().background(Color(ThemeColor.playerContrast04()))
            inputBar
        }
        .background(Color(PlayerColorHelper.playerBackgroundColor01()))
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            // Placeholder episode artwork
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(ThemeColor.playerContrast05()))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "waveform")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(ThemeColor.playerContrast02()))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.episodeTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(ThemeColor.playerContrast01()))
                    .lineLimit(1)

                Text(viewModel.podcastName)
                    .font(.caption)
                    .foregroundStyle(Color(ThemeColor.playerContrast02()))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color(ThemeColor.playerContrast02()))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Suggestions

    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer().frame(height: 40)

            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: 40))
                .foregroundStyle(Color(ThemeColor.playerContrast02()).opacity(0.6))
                .frame(maxWidth: .infinity)

            Text(L10n.chatWithEpisode)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color(ThemeColor.playerContrast01()))
                .frame(maxWidth: .infinity)

            Text(L10n.chatSuggestionsHeader)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(ThemeColor.playerContrast02()))
                .padding(.top, 8)

            FlowLayout(spacing: 8) {
                ForEach(viewModel.suggestedPrompts, id: \.self) { prompt in
                    SuggestedPromptPill(title: prompt) {
                        viewModel.send(prompt)
                    }
                }
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField(L10n.chatInputPlaceholder, text: $viewModel.inputText)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(Color(ThemeColor.playerContrast01()))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(ThemeColor.playerContrast05()))
                )
                .onSubmit {
                    viewModel.send(viewModel.inputText)
                }

            Button {
                viewModel.send(viewModel.inputText)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color(ThemeColor.playerContrast04())
                            : Color(PlayerColorHelper.playerHighlightColor01(for: .dark))
                    )
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Flow Layout

/// A simple flow layout that wraps children horizontally
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(in maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}
