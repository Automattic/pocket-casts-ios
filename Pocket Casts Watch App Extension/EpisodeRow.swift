import PocketCastsDataModel
import SwiftUI

struct EpisodeRow: View {
    @StateObject var viewModel: EpisodeRowViewModel
    let showArtwork: Bool
    private let progressScale: CGFloat = 0.3
    private let iconSize: CGFloat = 12
    private let artworkSize: CGFloat = 26

    init(viewModel: EpisodeRowViewModel, showArtwork: Bool) {
        // https://stackoverflow.com/questions/62635914/initialize-stateobject-with-a-parameter-in-swiftui
        _viewModel = StateObject(wrappedValue: viewModel)
        viewModel.hydrate()
        self.showArtwork = showArtwork
    }

    var body: some View {
        Group {
            if showArtwork {
                iconLayout
            } else {
                textOnlyLayout
            }
        }
        .font(.dynamic(size: 13))
        .multilineTextAlignment(.leading)
        .accessibilityLabel(viewModel.accessibilityInfo)
    }

    var iconLayout: some View {
        HStack(alignment: .top, spacing: 5) {
            VStack(alignment: .trailing) {
                CachedImage(url: viewModel.episode.smallImageUrl, cornerRadius: 2.3)
                    .frame(width: artworkSize, height: artworkSize)
                    .clipped()

                indicators
                    .frame(minHeight: iconSize)
            }

            VStack(alignment: .leading) {
                titleLabel
                    .padding(.vertical, -3)
                infoLabel
            }
        }
    }

    var textOnlyLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleLabel
            HStack {
                indicators
                infoLabel
            }
        }
    }

    var titleLabel: some View {
        Text(viewModel.episode.title ?? "")
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(2)
    }

    var infoLabel: some View {
        Text(viewModel.displayInfo)
            .foregroundColor(.subheadlineText)
    }

    var indicators: some View {
        HStack(spacing: 2) {
            if viewModel.inUpNext {
                Image("upnext_status", bundle: Bundle.watchAssets)
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
            } else if showArtwork {
                Spacer()
                    .frame(width: iconSize, height: iconSize)
            }

            if let downloadStatusIconName = viewModel.downloadStatusIconName {
                Image(downloadStatusIconName)
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
            } else if viewModel.isDownloading {
                ProgressView()
                    .scaleEffect(x: progressScale, y: progressScale, anchor: .center)
                    .frame(width: iconSize, height: iconSize)
            } else if showArtwork {
                Spacer()
                    .frame(width: iconSize, height: iconSize)
            }
        }
    }
}

struct EpisodeRow_Previews: PreviewProvider {
    static var previews: some View {
        EpisodeRow(viewModel: EpisodeRowViewModel(episode: Episode()), showArtwork: false)
            .previewDevice(.largeWatch)
            .previewLayout(.sizeThatFits)
    }
}
