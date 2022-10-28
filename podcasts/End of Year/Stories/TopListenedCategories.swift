import SwiftUI
import PocketCastsDataModel

struct TopListenedCategories: StoryView {
    var duration: TimeInterval = 5.seconds

    let listenedCategories: [ListenedCategory]

    var body: some View {
        ZStack {
            Color.purple

            VStack {
                Text("Your Top Categories")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom)
                VStack {
                    ForEach(0 ..< min(listenedCategories.count, 5), id: \.self) { x in
                        HStack(spacing: 16) {
                            Text("\(x + 1).")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            Image("discover_cat_1")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                            Text(listenedCategories[x].categoryTitle.localized)
                                .lineLimit(2)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            VStack(alignment: .trailing) {
                                Text("\(listenedCategories[x].numberOfPodcasts)").font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Podcasts")
                                    .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                            }
                            Spacer()
                        }
                    }
                }
                .padding(.leading, 40)
                .padding(.trailing, 40)
            }
        }
    }
}

struct TopListenedCategories_Previews: PreviewProvider {
    static var previews: some View {
        TopListenedCategories(listenedCategories: [])
    }
}
