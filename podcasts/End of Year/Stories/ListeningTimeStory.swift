import SwiftUI

struct ListeningTimeStory: StoryView {
    var duration: TimeInterval = 5.seconds

    let listeningTime: Double

    var body: some View {
        VStack {
            Text("In 2022, you spent \(listeningTime.localizedTimeDescription ?? "") listening to podcasts")
                .foregroundColor(.white)
            Text(FunnyTimeConverter.timeSecsToFunnyText(listeningTime))
                .foregroundColor(.white)
        }
    }
}

struct ListeningTimeStory_Previews: PreviewProvider {
    static var previews: some View {
        ListeningTimeStory(listeningTime: 100)
    }
}
