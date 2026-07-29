import SwiftUI

struct EpisodeChatView: View {
    @ObservedObject var viewModel: EpisodeChatViewModel
    var onDismiss: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            closeButton
            headerView
            progressBar

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }

                        if viewModel.isTyping {
                            TypingIndicatorView()
                                .id("typing")
                        }

                        if viewModel.showChips {
                            chipsView
                                .transition(.opacity)
                        }

                        if viewModel.shouldShowFeedbackToast {
                            ChatFeedbackToastView(
                                onSubmit: { result in
                                    viewModel.submitFeedback(result)
                                },
                                onDismiss: {
                                    viewModel.dismissFeedback()
                                }
                            )
                            .id("feedbackToast")
                            .padding(.top, 8)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        if let lastMessage = viewModel.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.isTyping) { isTyping in
                    if isTyping {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.shouldShowFeedbackToast) { shouldShow in
                    if shouldShow {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("feedbackToast", anchor: .bottom)
                        }
                    }
                }
            }

            Divider().background(Color(ThemeColor.playerContrast04()))
            inputBar
        }
        .background(Color(PlayerColorHelper.playerBackgroundColor01()))
    }

    // MARK: - Close Button

    private var closeButton: some View {
        HStack {
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(ThemeColor.playerContrast01()))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            // Placeholder episode artwork
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(PlayerColorHelper.playerHighlightColor01(for: .dark)).opacity(0.6),
                            Color(PlayerColorHelper.playerHighlightColor01(for: .dark)).opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(ThemeColor.playerContrast01()).opacity(0.8))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.episodeTitle)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(ThemeColor.playerContrast01()))
                    .lineLimit(1)

                Text(viewModel.podcastName)
                    .font(.footnote)
                    .foregroundStyle(Color(ThemeColor.playerContrast02()))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                viewModel.togglePlayback()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color(ThemeColor.playerContrast01()))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Color(PlayerColorHelper.playerHighlightColor01(for: .dark))
                    .frame(width: geometry.size.width * 0.35)
                Color(ThemeColor.playerContrast04())
            }
        }
        .frame(height: 3)
    }

    // MARK: - Chips

    private var chipsView: some View {
        FlowLayout(spacing: 8) {
            ForEach(viewModel.currentPrompts, id: \.self) { prompt in
                SuggestedPromptPill(title: prompt) {
                    viewModel.send(prompt)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField(
                "",
                text: $viewModel.inputText,
                prompt: Text(L10n.chatInputPlaceholder)
                    .foregroundColor(Color(ThemeColor.playerContrast02()))
            )
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
