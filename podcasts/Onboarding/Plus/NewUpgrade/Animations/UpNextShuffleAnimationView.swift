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

    @State private var offset = CGFloat(0)
    @State private var opacity = 0.0

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
        .offset(x: 0, y: offset)
        .opacity(opacity)
        .zIndex(episode.focused ? 1 : 0.5)
        .onAppear {
            animate(Double(index))
        }
    }

    private func animate(_ index: Double) {
        offset = 0
        opacity = 0
        withAnimation(.easeInOut(duration: 0.8).delay(0.1 + (0.1 * (3-index)))) {
            offset = -10
            opacity = episode.focused ? 1 : 0.5
        }
    }
}

struct UpNextShuffleAnimationView: View {

    fileprivate let episodes: [[EpisodeShuffle]] = [
        [
            EpisodeShuffle(image: "login-cover-1", date: "29 May 2024", name: "What have you done today", duration: "30 mins", focused: false),
            EpisodeShuffle(image: "login-cover-7", date: "12 June 2025", name: "The Sunday Read", duration: "32 mins", focused: true),
            EpisodeShuffle(image: "login-cover-3", date: "27 June 2023", name: "800: Jane Doe", duration: "1h 55m", focused: false)
        ],
        [
            EpisodeShuffle(image: "login-cover-4", date: "13 January 2025", name: "Can Ley rebuild the Coallition", duration: "32 mins", focused: false),
            EpisodeShuffle(image: "login-cover-5", date: "12 February 2025", name: "David Bezmozgis", duration: "47 mins", focused: true),
            EpisodeShuffle(image: "login-cover-6", date: "27 June 2023", name: "The Trial of Sean Combs", duration: "1h 34m", focused: false)
        ],
        [
            EpisodeShuffle(image: "login-cover-8", date: "12 May 2024", name: "El poder que tendrá León XIV", duration: "30 mins", focused: false),
            EpisodeShuffle(image: "login-cover-2", date: "18 May 2025", name: "Jason played the Switch 2", duration: "56 mins", focused: true),
            EpisodeShuffle(image: "login-cover-9", date: "27 June 2023", name: "887: Burgertory", duration: "1h 55m", focused: false)
        ],
    ]

    @EnvironmentObject var theme: Theme

    @State var position = 0

    func nextAnimation() {
        withAnimation(.easeIn.delay(0.25)) {
            if position == episodes.count - 1 {
                position = 0
            } else {
                position += 1
            }
        }
    }

    @ViewBuilder
    func groupOfEpisodes(position: Int) -> some View {
        VStack(spacing: -16) {
            ForEach(Array(zip(episodes[position].indices, episodes[position])), id: \.0) { (index, episode) in
                EpisodeShuffleRow(episode: episode, index: index)
            }
        }
        .padding(.horizontal, 32)
    }

    var body: some View {
        ZStack {
            switch position {
                case 0:
                    groupOfEpisodes(position: 0)
                case 1:
                    groupOfEpisodes(position: 1)
                case 2:
                    groupOfEpisodes(position: 2)
                default:
                    EmptyView()
            }
        }
        .task {
            Task {
                while true {
                    try await Task.sleep(for: .seconds(1.6))
                    nextAnimation()
                }
            }
        }
    }
}

extension AnyTransition {
    static var fade: AnyTransition {
        .asymmetric(
            insertion: .opacity,
            removal: .offset(y: -10).combined(with: .opacity)
        )
    }
}

#Preview {
    UpNextShuffleAnimationView().setupDefaultEnvironment()
}
