import SwiftUI
import PocketCastsDataModel

struct RatePodcastView: View {
    @ObservedObject var viewModel: RatePodcastViewModel

    @EnvironmentObject var theme: Theme
    @State var stars: Double = 0

    init(viewModel: RatePodcastViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Spacer()
                content
                Spacer()
                Button("Done") {
                    viewModel.dismiss()
                }
                .buttonStyle(BasicButtonStyle(textColor: theme.primaryInteractive02, backgroundColor: theme.primaryText01))
            }

            Image("close")
                .renderingMode(.template)
                .foregroundStyle(theme.primaryText01)
                .buttonize {
                    viewModel.dismiss()
                }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .applyDefaultThemeOptions()
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.userCanRate {
        case .checking:
            ProgressView()
                .tint(theme.primaryIcon01)
                .controlSize(.large)
        case .allowed:
            rate
        case .disallowed:
            cannotRate
        }
    }

    private var cannotRate: some View {
        Group {
            PodcastCover(podcastUuid: viewModel.podcast.uuid, big: true)
                .frame(width: 164, height: 164)
                .padding(.bottom, 40)
            Text(L10n.ratingListenToThisPodcastTitle)
                .font(size: 20, style: .title3, weight: .bold)
                .padding(.bottom, 16)
            Text(L10n.ratingListenToThisPodcastMessage)
                .font(style: .body)
                .multilineTextAlignment(.center)
        }
    }

    private var rate: some View {
        Group {
            PodcastCover(podcastUuid: viewModel.podcast.uuid, big: true)
                .frame(width: 164, height: 164)
                .padding(.bottom, 40)
            Text(L10n.ratingTitle(viewModel.podcast.title ?? ""))
                .font(size: 20, style: .title3, weight: .bold)
                .padding(.bottom, 16)
                .multilineTextAlignment(.center)
            ContentSizeGeometryReader { reader in
                HStack {
                    let fullStars = Int(floor(stars))
                    let halfStar = stars.truncatingRemainder(dividingBy: 1) > 0
                    let emptyStars = Int((halfStar ? 4 : 5) - fullStars)
                    ForEach(0..<fullStars, id: \.self) { index in
                        Image("star-full")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .padding(4)
                    }

                    if halfStar {
                        Image("star-half")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .padding(4)
                    }

                    ForEach(0..<emptyStars, id: \.self) { index in
                        Image("star")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .padding(4)
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            var value = (gesture.location.x * 5) / reader.size.width
                            value = value * 2
                            value = value.rounded() / 2
                            stars = value
                            print("$$ \(value)")
                        }
                )
            }
        }
    }
}

extension Double {
    func round(nearest: Double) -> Double {
        let n = 1/nearest
        let numberToRound = self * n
        return numberToRound.rounded() / n
    }
}

#Preview {
    RatePodcastView(viewModel: RatePodcastViewModel(presented: .constant(true), podcast: Podcast.previewPodcast()))
        .environmentObject(Theme.sharedTheme)
}
