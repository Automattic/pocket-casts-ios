import Foundation
import SwiftUI

fileprivate struct EpisodeShuffle {
    let image: String
    let date: String
    let name: String
    let duration: String
    let focused: Bool
}

fileprivate struct EpisodeShuffleRow: View {

    let episode: EpisodeShuffle
    let index: Int

    @EnvironmentObject var theme: Theme

    @State private var offset = 10.0
    @State private var opacity = 0.0
    @State private var selected = true

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(episode.image)
                .resizable()
                .frame(width: 52, height: 52)
                .cornerRadius(4)
            VStack(alignment: .leading) {
                Text(episode.date)
                    .font(size: 10, style: .caption, weight: .semibold)
                    .kerning(0.3)
                    .foregroundStyle(theme.primaryText02)
                Text(episode.name)
                    .font(size: 13, style: .callout, weight: .medium)
                    .foregroundStyle(theme.primaryText01)
                Text(episode.duration)
                    .font(size: 10, style: .caption, weight: .semibold)
                    .kerning(0.3)
                    .foregroundStyle(theme.primaryText02)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(theme.primaryUi03)
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.2), radius: 1.4, x: 0, y: 1)
        .scaleEffect(episode.focused ? 1.2 : 1)
        .opacity(opacity)
        .zIndex(episode.focused ? 1 : 0.5)
        .onAppear {
            animate(Double(index))
        }
    }

    private func animate(_ index: Double) {
        offset = 10
        opacity = 0
        withAnimation(.easeInOut(duration: 0.8).delay(0.1 + (0.1 * index))) {
            offset = 0
            opacity = episode.focused ? 1 : 0.5
        }
    }
}

struct UpNextShuffleAnimationView: View {

    fileprivate let episodes: [EpisodeShuffle] = [
        EpisodeShuffle(image: "login-cover-1", date: "29 May 2024", name: "What have you done today", duration: "30 mins", focused: false),
        EpisodeShuffle(image: "login-cover-2", date: "12 June 2025", name: "The Sunday Read", duration: "32 mins", focused: true),
        EpisodeShuffle(image: "login-cover-3", date: "27 June 2023", name: "800: Jane Doe", duration: "1h 55m", focused: false)
    ]

    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack(spacing: -16) {
            ForEach(Array(zip(episodes.indices, episodes)), id: \.0) { (index, episode) in
                EpisodeShuffleRow(episode: episode, index: index)
            }
        }
        .padding(.horizontal, 32)
    }

}

#Preview {
    UpNextShuffleAnimationView().setupDefaultEnvironment()
}
