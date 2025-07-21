import Foundation
import SwiftUI

struct PreSelectChaptersAnimationView: View {

    struct Chapter {
        let chapter: String
        let title: String
        let selected: Bool
    }

    let chapters: [Chapter] = [
        Chapter(chapter: "CHAPTER 1", title: "Intro", selected: false),
        Chapter(chapter: "CHAPTER 2", title: "A word from our sponsor", selected: true),
        Chapter(chapter: "CHAPTER 3", title: "Who will win the Oscars", selected: true)
    ]

    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack(spacing: 8) {
            ForEach(chapters, id: \.chapter) { chapter in
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
                    Image(chapter.selected ? "rounded-selected" : "rounded-deselected")
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(theme.primaryIcon02)
                        .frame(width: 24, height: 24)
                }
                .padding(16)
                .background(theme.primaryUi03)
            }
        }
        .padding(24)
    }
}

#Preview {
    PreSelectChaptersAnimationView().setupDefaultEnvironment()
}
