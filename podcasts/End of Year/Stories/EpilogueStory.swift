import SwiftUI

struct EpilogueStory: StoryView {
    var duration: TimeInterval = 5.seconds

    var body: some View {
        ZStack {
            Color.orange
                .allowsHitTesting(false)

            VStack {
                Text(L10n.eoyStoryEpilogueTitle)
                    .foregroundColor(.white)
                Text(L10n.eoyStoryEpilogueSubtitle)
                    .foregroundColor(.white)
                Button(action: {
                    StoriesController.shared.replay()
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                        Text(L10n.eoyStoryReplay)
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
            }
            .padding()
        }
    }
}

struct EpilogueStory_Previews: PreviewProvider {
    static var previews: some View {
        EpilogueStory()
    }
}
