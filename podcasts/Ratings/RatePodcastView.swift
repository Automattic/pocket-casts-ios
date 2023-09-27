import SwiftUI
import PocketCastsDataModel

struct RatePodcastView: View {
    @ObservedObject var viewModel: RatePodcastViewModel

    @EnvironmentObject var theme: Theme

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
                    ForEach(0..<Constants.maxStars, id: \.self) { index in
                        let currentStar = viewModel.stars - Double(index)

                        Group {
                            if currentStar > 0 && currentStar < 1 {
                                Image("star-half")
                                    .resizable()
                                    .renderingMode(.template)
                            } else if currentStar > 0 {
                                Image("star-full")
                                    .resizable()
                                    .renderingMode(.template)
                            } else {
                                Image("star")
                                    .resizable()
                                    .renderingMode(.template)
                            }
                        }
                        .foregroundStyle(theme.primaryText01)
                        .frame(width: 36, height: 36)
                        .padding(4)
                        .onTapGesture {
                            viewModel.stars = Double(index) + 1
                        }
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            var starValue = (gesture.location.x * 5) / reader.size.width
                            starValue = (starValue * 2).rounded() / 2
                            viewModel.stars = max(0, min(5, starValue))
                        }
                )
            }
        }
    }

    enum Constants {
        static let maxStars = 5
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
