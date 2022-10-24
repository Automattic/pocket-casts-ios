import SwiftUI
import PocketCastsDataModel

struct ListenedNumbersStory: StoryView {
    var duration: TimeInterval = 5.seconds

    let listenedNumbers: ListenedNumbers

    var body: some View {
        ZStack {
            Color.orange

            Text("You listened to \(listenedNumbers.numberOfPodcasts) different podcasts and \(listenedNumbers.numberOfEpisodes) episodes, but there was one that you kept coming back to...")
                .foregroundColor(.white)
                .padding()
        }
    }
}

struct ListenedNumbersStory_Previews: PreviewProvider {
    static var previews: some View {
        ListenedNumbersStory(listenedNumbers: ListenedNumbers(numberOfPodcasts: 5, numberOfEpisodes: 10))
    }
}
