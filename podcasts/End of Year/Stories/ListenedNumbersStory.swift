import SwiftUI
import PocketCastsDataModel

struct ListenedNumbersStory: StoryView {
    var duration: TimeInterval = 5.seconds

    let listenedNumbers: ListenedNumbers

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.orange

                VStack {
                    Text(L10n.eoyStoryListenedToNumbers("\(listenedNumbers.numberOfPodcasts)", "\(listenedNumbers.numberOfEpisodes)"))
                        .foregroundColor(.white)
                        .font(.system(size: 25, weight: .heavy))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: geometry.size.height * 0.12)
                        .minimumScaleFactor(0.01)

                    Text(L10n.eoyStoryListenedToNumbersSubtitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: geometry.size.height * 0.07)
                        .minimumScaleFactor(0.01)
                        .opacity(0.8)
                }
            }
        }
    }
}

struct ListenedNumbersStory_Previews: PreviewProvider {
    static var previews: some View {
        ListenedNumbersStory(listenedNumbers: ListenedNumbers(numberOfPodcasts: 5, numberOfEpisodes: 10))
    }
}
