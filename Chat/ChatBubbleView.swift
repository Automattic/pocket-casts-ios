import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(foregroundColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(bubbleBackground)

                if let episodes = message.relatedEpisodes, !episodes.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(episodes) { episode in
                            RelatedEpisodeCard(episode: episode)
                        }
                    }
                }
            }

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }

    private var foregroundColor: Color {
        switch message.role {
        case .user:
            return .white
        case .assistant:
            return Color(ThemeColor.playerContrast01())
        }
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        switch message.role {
        case .user:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(PlayerColorHelper.playerHighlightColor01(for: .dark)))
        case .assistant:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(ThemeColor.playerContrast05()))
        }
    }
}

struct TypingIndicatorView: View {
    @State private var animatingDot = 0

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color(ThemeColor.playerContrast02()))
                        .frame(width: 8, height: 8)
                        .scaleEffect(animatingDot == index ? 1.3 : 0.7)
                        .opacity(animatingDot == index ? 1 : 0.4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(ThemeColor.playerContrast05()))
            )

            Spacer(minLength: 60)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                animatingDot = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    animatingDot = 2
                }
            }
        }
    }
}
