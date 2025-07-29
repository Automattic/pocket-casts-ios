import Foundation
import SwiftUI

struct Chapter {
    let chapter: String
    let title: String
    let selected: Bool
}

struct ChapterRow: View {

    let chapter: Chapter
    let index: Int

    @EnvironmentObject var theme: Theme

    @State private var offset = 10.0
    @State private var opacity = 0.0
    @State private var selected = true

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                Text(chapter.chapter)
                    .font(size: 12, style: .footnote, weight: .semibold)
                    .kerning(0.36)
                    .foregroundStyle(theme.primaryText02)
                Text(chapter.title)
                    .font(size: 16, style: .title3, weight: .medium)
                    .foregroundStyle(theme.primaryText01)
            }
            Spacer()
            Image(selected ? "rounded-selected" : "rounded-deselected")
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(theme.primaryIcon02)
                .frame(width: 24, height: 24)
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
        withAnimation(.easeInOut(duration: 0.6).delay(0.8 + (1 + (0.1 * index)) + (0.7 + (index * 0.1)))) {
            if !chapter.selected {
                selected = false
                offset = 0
                opacity = 0.2
            }
        }
    }
}

struct PreSelectChaptersAnimationView: View {

    let chapters: [Chapter] = [
        Chapter(chapter: "CHAPTER 1", title: "Intro", selected: false),
        Chapter(chapter: "CHAPTER 2", title: "A word from our sponsor", selected: false),
        Chapter(chapter: "CHAPTER 3", title: "Who will win the Oscars", selected: true)
    ]

    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(zip(chapters.indices, chapters)), id: \.0) { (index, chapter) in
                ChapterRow(chapter: chapter, index: index)
            }
        }
        .padding(.horizontal, 16)
    }

}

#Preview {
    PreSelectChaptersAnimationView().setupDefaultEnvironment()
}
