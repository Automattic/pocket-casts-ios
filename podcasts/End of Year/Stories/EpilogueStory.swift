import SwiftUI

struct EpilogueStory: StoryView {
    var duration: TimeInterval = 5.seconds

    var body: some View {
        ZStack {
            Color.orange

            VStack {
                Text("Thank you for letting Pocket Casts be apart of your listening experience in 2022")
                    .foregroundColor(.white)
                Text("Don't forget to share with your friends and give a shout out to your favorite podcasts creators")
                    .foregroundColor(.white)
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
