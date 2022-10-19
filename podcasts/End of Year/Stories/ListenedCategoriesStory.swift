import SwiftUI
import PocketCastsDataModel

struct ListenedCategoriesStory: StoryView {
    var duration: TimeInterval = 5.seconds

    let listenedCategories: [ListenedCategory]

    var body: some View {
        ZStack {
            Color.purple
            VStack {
                Text("You listened to \(listenedCategories.count) different categories this year")
                Text("Let's take a look at some of your favourites..")
            }
        }
    }
}

struct ListenedCategoriesStory_Previews: PreviewProvider {
    static var previews: some View {
        ListenedCategoriesStory(listenedCategories: [])
    }
}
