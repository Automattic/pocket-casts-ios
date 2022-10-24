import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct TopFivePodcastsStory: StoryView {
    let podcasts: [Podcast]

    let duration: TimeInterval = 5.seconds

    var backgroundColor: Color {
        Color(podcasts.first?.bgColor() ?? UIColor.black)
    }

    var tintColor: Color {
        .white
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack {
                Text("Your Top Podcasts")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(tintColor)
                    .padding(.bottom)
                VStack {
                    ForEach(0 ..< podcasts.count, id: \.self) { x in
                        HStack(spacing: 16) {
                            Text("\(x + 1).")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(tintColor)
                            ImageView(ServerHelper.imageUrl(podcastUuid: podcasts[x].uuid, size: 280))
                                .frame(width: 76, height: 76)
                                .aspectRatio(1, contentMode: .fit)
                                .cornerRadius(4)
                                .shadow(radius: 2, x: 0, y: 1)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading) {
                                Text(podcasts[x].title ?? "")
                                    .lineLimit(2)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(tintColor)
                                Text(podcasts[x].author ?? "").font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(tintColor)
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

struct DummyStory_Previews: PreviewProvider {
    static var previews: some View {
        let podcast = Podcast()
        TopFivePodcastsStory(podcasts: [Podcast.previewPodcast()])
    }
}
