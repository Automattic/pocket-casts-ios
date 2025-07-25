import Foundation
import SwiftUI

fileprivate struct EpisodeShuffle {
    let image: String
    let date: String
    let name: String
    let duration: String
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
            Image(selected ? "rounded-selected" : "rounded-deselected")
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(theme.primaryIcon02)
                .frame(width: 24, height: 24)
            VStack(alignment: .leading) {
                Text(episode.date)
                    .font(size: 12, style: .footnote, weight: .semibold)
                    .kerning(0.36)
                    .foregroundStyle(theme.primaryText02)
                Text(episode.name)
                    .font(size: 16, style: .title3, weight: .medium)
                    .foregroundStyle(theme.primaryText01)
                Text(episode.duration)
                    .font(size: 16, style: .title3, weight: .medium)
                    .foregroundStyle(theme.primaryText01)
            }
            Spacer()
        }
        .padding(16)
        .background(theme.primaryUi03)
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.2), radius: 1.4, x: 0, y: 1)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            animate(Double(index))
        }
    }

    private func animate(_ index: Double) {
        offset = 10
        opacity = 0
        withAnimation(.easeInOut(duration: 0.8).delay(1 + (0.1 * index))) {
            offset = 0
            opacity = 1
        }
    }
}

struct UpNextShuffleAnimationView: View {

    fileprivate let episodes: [EpisodeShuffle] = [
        EpisodeShuffle(image: "", date: "", name: "", duration: ""),
        EpisodeShuffle(image: "", date: "", name: "", duration: ""),
        EpisodeShuffle(image: "", date: "", name: "", duration: "")
    ]

    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(zip(episodes.indices, episodes)), id: \.0) { (index, episode) in
                EpisodeShuffleRow(episode: episode, index: index)
            }
        }
        .padding(.horizontal, 16)
    }

}

#Preview {
    UpNextShuffleAnimationView().setupDefaultEnvironment()
}
