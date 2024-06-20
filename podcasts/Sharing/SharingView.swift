import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SharingView: View {

    private enum Constants {
        static let descriptionMaxWidth: CGFloat = 200
    }

    let selectedOption: SharingModal.Option

    @State private var selectedMedia: ShareImageStyle = .large

    var body: some View {
        VStack {
            title
            image
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Color.white)
    }

    @ViewBuilder var title: some View {
        VStack {
            Text(selectedOption.shareTitle)
                .font(.headline)
            Text(L10n.shareDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: Constants.descriptionMaxWidth)
        }
    }

    @ViewBuilder var image: some View {
        TabView(selection: $selectedMedia) {
            ForEach(ShareImageStyle.allCases, id: \.self) { style in
                ShareImageView(info: selectedOption.imageInfo, style: style)
                    .tabItem { Text(style.tabString) }
            }
        }
        .tabViewStyle(.page)
    }
}

#Preview {
    SharingView(selectedOption: .podcast(Podcast.previewPodcast()))
}
