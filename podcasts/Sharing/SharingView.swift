import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SharingView: View {

    private enum Constants {
        static let descriptionMaxWidth: CGFloat = 200
    }

    let destinations: [ShareDestination]
    let selectedOption: SharingModal.Option

    @State private var selectedMedia: ShareImageStyle = .large

    var body: some View {
        VStack {
            title
            image
            buttons
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .tabItem { Text(style.tabString) }
            }
        }
        .tabViewStyle(.page)
    }

    @ViewBuilder var buttons: some View {
        HStack(spacing: 24) {
            ForEach(destinations, id: \.self) { option in
                Button {
                    option.action(selectedOption, selectedMedia)
                } label: {
                    VStack {
                        option.icon
                            .renderingMode(.template)
                            .font(size: 20, style: .body, weight: .bold)
                            .frame(width: 24, height: 24)
                            .padding(15)
                            .background {
                                Circle()
                                    .foregroundStyle(.white.opacity(0.1))
                            }
                        Text(option.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    SharingView(destinations: [.copyLinkOption], selectedOption: .podcast(Podcast.previewPodcast()))
}
