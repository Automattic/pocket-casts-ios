import SwiftUI
import PocketCastsDataModel

struct TopListenedCategories: StoryView {
    var duration: TimeInterval = 5.seconds

    let listenedCategories: [ListenedCategory]

    var body: some View {
        Text("Hello, World!")
    }
}

struct TopListenedCategories_Previews: PreviewProvider {
    static var previews: some View {
        TopListenedCategories(listenedCategories: [])
    }
}
