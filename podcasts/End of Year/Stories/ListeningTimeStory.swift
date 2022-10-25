import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct ListeningTimeStory: StoryView {
    var duration: TimeInterval = 5.seconds

    let listeningTime: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DynamicBackgroundView(podcast: Podcast.previewPodcast())

                VStack {
                    Text("In 2022, you spent \(listeningTime.localizedTimeDescription ?? "") listening to podcasts")
                        .foregroundColor(.white)
                        .font(.system(size: 25, weight: .heavy))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: geometry.size.height * 0.12)
                        .minimumScaleFactor(0.01)

                    Text(FunnyTimeConverter.timeSecsToFunnyText(listeningTime))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: geometry.size.height * 0.07)
                        .minimumScaleFactor(0.01)
                        .opacity(0.8)
                    Spacer()
                }
                .padding(.top, geometry.size.height * 0.15)
                .padding(.trailing, 40)
                .padding(.leading, 40)

                VStack {
                    Spacer()

                    HStack {
                        ImageView(ServerHelper.imageUrl(podcastUuid: Podcast.previewPodcast().uuid, size: 280))
                            .frame(width: 140, height: 140)
                            .aspectRatio(1, contentMode: .fit)
                            .cornerRadius(4)
                            .shadow(radius: 2, x: 0, y: 1)
                            .accessibilityHidden(true)

                        ImageView(ServerHelper.imageUrl(podcastUuid: Podcast.previewPodcast().uuid, size: 280))
                            .frame(width: 140, height: 140)
                            .aspectRatio(1, contentMode: .fit)
                            .cornerRadius(4)
                            .shadow(radius: 2, x: 0, y: 1)
                            .accessibilityHidden(true)

                        ImageView(ServerHelper.imageUrl(podcastUuid: Podcast.previewPodcast().uuid, size: 280))
                            .frame(width: 140, height: 140)
                            .aspectRatio(1, contentMode: .fit)
                            .cornerRadius(4)
                            .shadow(radius: 2, x: 0, y: 1)
                            .accessibilityHidden(true)
                    }
                    .transformEffect(androidValuesToIOSTransform())
                    .rotationEffect(.init(degrees: -30))
                    .position(x: 170, y: geometry.size.height - 230)
                }
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

    func androidValuesToIOSTransform() -> CGAffineTransform {

        let androidValues: [CGFloat] = [0.89, 0, 0.58, 1, 0, 0]
        return CGAffineTransform(
            a: androidValues[0], b: androidValues[1],
            c: androidValues[2], d: androidValues[3],
            tx: 0, ty: 0
        )
    }
}

struct ListeningTimeStory_Previews: PreviewProvider {
    static var previews: some View {
        ListeningTimeStory(listeningTime: 100)
    }
}
