import Foundation
import SwiftUI

private struct BookmarkUpgradeCardStyle {
    let gradientStart: Color
    let gradientEnd: Color

    static let front = BookmarkUpgradeCardStyle(gradientStart: Color(hex: "#0202FE"), gradientEnd: Color(hex: "#27D9E9"))
    static let middle = BookmarkUpgradeCardStyle(gradientStart: Color(hex: "#EC4034"), gradientEnd: Color(hex: "#FF9D00"))
    static let back = BookmarkUpgradeCardStyle(gradientStart: Color(hex: "#E8A92C"), gradientEnd: Color(hex: "#E4D820"))
}

private extension BookmarkUpgradeCardStyle {
    var gradient: LinearGradient {
        LinearGradient(
            stops: [
                Gradient.Stop(color: gradientStart, location: 0.00),
                Gradient.Stop(color: gradientEnd, location: 1.00),
            ],
            startPoint: UnitPoint(x: 0.0, y: 1.0),
            endPoint: UnitPoint(x: 1.0, y: 0.0)
        )
    }
}

/// The bookmark a listener ends up with: a generated title, the words from the transcript, and the timestamp.
private struct BookmarkUpgradeCard: View {
    @ScaledMetric(relativeTo: .subheadline) private var artworkSize = 44

    var body: some View {
        HStack(spacing: 12) {
            Image("login-cover-2")
                .resizable()
                .frame(width: artworkSize, height: artworkSize)
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.bookmarksUpgradeExampleTitle)
                    .font(size: 15, style: .subheadline, weight: .semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(L10n.bookmarksUpgradeExamplePassage)
                    .font(size: 12, style: .caption, weight: .regular)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            timestamp
        }
        .padding(12)
        .background(BookmarkUpgradeCardStyle.front.gradient)
        .cornerRadius(12)
    }

    private var timestamp: some View {
        HStack(spacing: 4) {
            Text(Constants.timestamp)
                .font(size: 13, style: .caption, weight: .medium)
                .foregroundStyle(.black)
            Image("bookmarks-icon-play")
                .renderingMode(.template)
                .foregroundStyle(.black)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background {
            Capsule(style: .continuous)
                .fill(Color.white)
        }
    }

    private enum Constants {
        static let timestamp = "6:45"
    }
}

struct BookmarksAnimationView: View {
    @State private var revealed = false

    var body: some View {
        BookmarkUpgradeCard()
            .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 2)
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 24)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: revealed)
            .background(alignment: .top) {
                stackedCards
            }
            .padding(.horizontal, 16)
            .onAppear {
                revealed = true
            }
    }

    private var stackedCards: some View {
        ZStack(alignment: .top) {
            card(style: .back, inset: 34, offset: -22)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: revealed)
            card(style: .middle, inset: 17, offset: -11)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: revealed)
        }
    }

    private func card(style: BookmarkUpgradeCardStyle, inset: CGFloat, offset: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(style.gradient)
            .padding(.horizontal, inset)
            .offset(y: revealed ? offset : 0)
            .opacity(revealed ? 1 : 0)
    }
}

#Preview {
    BookmarksAnimationView().setupDefaultEnvironment()
}
