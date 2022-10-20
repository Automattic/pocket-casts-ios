import SwiftUI

struct EpilogueStory: StoryView {
    var duration: TimeInterval = 5.seconds

    var body: some View {
        ZStack {
            Color.orange
                .allowsHitTesting(false)

            VStack {
                Text("Thank you for letting Pocket Casts be a part of your listening experience in 2022")
                    .foregroundColor(.white)
                Text("Don't forget to share with your friends and give a shout out to your favorite podcasts creators")
                    .foregroundColor(.white)
                Button(action: {
                    StoriesController.shared.replay()
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                        Text("Replay")
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
