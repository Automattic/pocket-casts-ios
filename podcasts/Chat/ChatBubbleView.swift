import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        switch message.role {
        case .user:
            userBubble
        case .assistant:
            assistantMessage
        }
    }

    // MARK: - User Bubble

    private var userBubble: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer(minLength: 60)

            Text(message.content)
                .font(.body)
                .foregroundStyle(Color(ThemeColor.playerContrast01()))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(ThemeColor.playerContrast05()))
                )
        }
    }

    // MARK: - Assistant Message

    private var assistantMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message.content)
                .font(.body)
                .foregroundStyle(Color(ThemeColor.playerContrast01()))

            if let episodes = message.relatedEpisodes, !episodes.isEmpty {
                VStack(spacing: 8) {
                    ForEach(episodes) { episode in
                        RelatedEpisodeCard(episode: episode)
                    }
                }
            }
        }
    }
}

struct TypingIndicatorView: View {
    @State private var animatingDot = 0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color(ThemeColor.playerContrast02()))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animatingDot == index ? 1.3 : 0.7)
                    .opacity(animatingDot == index ? 1 : 0.4)
            }
        }
        .padding(.vertical, 8)
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
