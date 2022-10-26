import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct ListenedCategoriesStory: StoryView {
    var duration: TimeInterval = 5.seconds

    let listenedCategories: [ListenedCategory]

    let podcasts: [Podcast]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DynamicBackgroundView(podcast: podcasts[0])

                VStack {
                    ZStack {
                        ImageView(ServerHelper.imageUrl(podcastUuid: podcasts[2].uuid, size: 280))
                            .modifier(PodcastCover())
                            .frame(width: 200, height: 200)
                            .modifier(PodcastCoverPerspective())
                            .padding(.leading, -60)
                            .padding(.top, 140)

                    ImageView(ServerHelper.imageUrl(podcastUuid: podcasts[1].uuid, size: 280))
                        .modifier(PodcastCover())
                        .frame(width: 200, height: 200)
                        .modifier(PodcastCoverPerspective())
                        .padding(.leading, -60)
                        .padding(.top, 70)

                        ImageView(ServerHelper.imageUrl(podcastUuid: podcasts[0].uuid, size: 280))
                            .modifier(PodcastCover())
                            .frame(width: 200, height: 200)
                            .modifier(PodcastCoverPerspective())
                            .padding(.leading, -60)
                    }

                    VStack {
                        Text("You listened to \(listenedCategories.count) different categories this year")
                            .foregroundColor(.white)
                            .font(.system(size: 25, weight: .heavy))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxHeight: geometry.size.height * 0.12)
                            .minimumScaleFactor(0.01)
                        Text("Let's take a look at some of your favourites...")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxHeight: geometry.size.height * 0.07)
                            .minimumScaleFactor(0.01)
                            .opacity(0.8)
                    }
                    .padding(.top, 25)
                    .padding(.trailing, 40)
                    .padding(.leading, 40)
                }
                .padding(.top, -30)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("logo_white")
                        .padding(.bottom, 40)
                    Spacer()
                }
            }
        }
    }
}

struct ListenedCategoriesStory_Previews: PreviewProvider {
    static var previews: some View {
        ListenedCategoriesStory(listenedCategories: [], podcasts: [Podcast.previewPodcast(), Podcast.previewPodcast(), Podcast.previewPodcast()])
    }
}
