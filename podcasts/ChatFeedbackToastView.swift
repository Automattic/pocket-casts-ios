// Temporary file: adds missing ChatFeedbackToastView to unblock the build.
// The canonical version is at podcasts/Chat/ChatFeedbackToastView.swift on disk
// but that file is not in the Xcode project yet.

import SwiftUI

struct ChatFeedbackToastView: View {
    var onSubmit: (ChatFeedbackResult) -> Void
    var onDismiss: () -> Void

    @State private var phase: Phase = .initial
    @State private var selectedRating: ChatFeedbackRating?
    @State private var selectedReasons: Set<ChatFeedbackReason> = []
    @State private var additionalComment: String = ""

    private enum Phase {
        case initial
        case expanded
        case thankYou
    }

    var body: some View {
        cardContent
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(ThemeColor.playerContrast05()))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(ThemeColor.playerContrast04()), lineWidth: 0.5)
            )
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        if abs(value.translation.width) > 80 || abs(value.translation.height) > 80 {
                            withAnimation { onDismiss() }
                        }
                    }
            )
    }

    @ViewBuilder
    private var cardContent: some View {
        switch phase {
        case .initial:
            initialContent
        case .expanded:
            expandedContent
        case .thankYou:
            thankYouContent
        }
    }

    private var initialContent: some View {
        VStack(spacing: 12) {
            Text(L10n.chatFeedbackTitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(ThemeColor.playerContrast01()))

            HStack(spacing: 20) {
                ForEach(ChatFeedbackRating.allCases) { rating in
                    Button {
                        selectedRating = rating
                        if rating.isPositive {
                            submitPositive(rating)
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                phase = .expanded
                            }
                        }
                    } label: {
                        Text(rating.emoji)
                            .font(.system(size: 28))
                    }
                }
            }
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.chatFeedbackWhatWentWrong)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(ThemeColor.playerContrast01()))

            FlowLayout(spacing: 8) {
                ForEach(ChatFeedbackReason.allCases) { reason in
                    reasonChip(for: reason)
                }
            }

            TextField(
                "",
                text: $additionalComment,
                prompt: Text(L10n.chatFeedbackCommentPlaceholder)
                    .foregroundColor(Color(ThemeColor.playerContrast02()))
            )
            .textFieldStyle(.plain)
            .font(.subheadline)
            .foregroundStyle(Color(ThemeColor.playerContrast01()))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(PlayerColorHelper.playerBackgroundColor01()))
            )

            Button {
                submitNegative()
            } label: {
                Text(L10n.chatFeedbackSend)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(ThemeColor.playerContrast01()))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(PlayerColorHelper.playerHighlightColor01(for: .dark)))
                    )
            }
        }
    }

    private func reasonChip(for reason: ChatFeedbackReason) -> some View {
        let isSelected = selectedReasons.contains(reason)
        return Button {
            if isSelected {
                selectedReasons.remove(reason)
            } else {
                selectedReasons.insert(reason)
            }
        } label: {
            Text(reason.label)
                .font(.subheadline)
                .foregroundStyle(Color(ThemeColor.playerContrast01()))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? Color(PlayerColorHelper.playerHighlightColor01(for: .dark)).opacity(0.3)
                                : Color(ThemeColor.playerContrast05())
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected
                                ? Color(PlayerColorHelper.playerHighlightColor01(for: .dark))
                                : Color(ThemeColor.playerContrast04()),
                            lineWidth: isSelected ? 1.5 : 0.5
                        )
                )
        }
    }

    private var thankYouContent: some View {
        Text(L10n.chatFeedbackThankYou)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color(ThemeColor.playerContrast02()))
            .frame(maxWidth: .infinity)
            .onAppear {
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    withAnimation { onDismiss() }
                }
            }
    }

    private func submitPositive(_ rating: ChatFeedbackRating) {
        let result = ChatFeedbackResult(rating: rating, reasons: [], additionalComment: "")
        onSubmit(result)
        withAnimation(.easeInOut(duration: 0.25)) {
            phase = .thankYou
        }
    }

    private func submitNegative() {
        guard let rating = selectedRating else { return }
        let result = ChatFeedbackResult(rating: rating, reasons: selectedReasons, additionalComment: additionalComment)
        onSubmit(result)
        withAnimation(.easeInOut(duration: 0.25)) {
            phase = .thankYou
        }
    }
}
