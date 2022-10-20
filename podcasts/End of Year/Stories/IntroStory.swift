import SwiftUI

struct IntroStory: StoryView {
    var duration: TimeInterval = 5.seconds

    var body: some View {
        Text("Let's celebrate your year of listening...")
            .foregroundColor(.white)
    }
}

struct IntroStory_Previews: PreviewProvider {
    static var previews: some View {
        IntroStory()
    }
}
