import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct SharedProfilePodcastsList: View {
    @EnvironmentObject var theme: Theme
    let podcasts: [SharedProfileViewModel.PodcastInfo]
    let navigateToPodcast: (_ uuid: String) -> Void
    let goBack: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(podcasts.enumerated()), id: \.element.id) { index, podcast in
                    SharedProfilePodcastRow(
                        podcast: podcast,
                        navigateToPodcast: { navigateToPodcast(podcast.uuid) }
                    )

                    if index < podcasts.count - 1 {
                        ThemedDivider()
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
        .background(theme.primaryUi01)
        .navigationTitle(L10n.shareProfileFollowedPodcasts)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: goBack) {
                    Image("nav-back")
                        .renderingMode(.template)
                }
                .navThemed()
            }
        }
    }
}

struct SharedProfilePodcastRow: View {
    @EnvironmentObject var theme: Theme
    let podcast: SharedProfileViewModel.PodcastInfo
    let navigateToPodcast: () -> Void

    var body: some View {
        Button(action: navigateToPodcast) {
            HStack(spacing: 12) {
                PodcastImage(uuid: podcast.uuid, size: .list)
                    .frame(width: 52, height: 52)
                    .cornerRadius(4)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(podcast.title)
                        .font(style: .subheadline, weight: .medium)
                        .foregroundColor(theme.primaryText01)
                        .lineLimit(1)

                    if let author = podcast.author {
                        Text(author)
                            .font(style: .footnote, weight: .regular)
                            .foregroundColor(theme.primaryText02)
                            .lineLimit(1)
                    }
                }

                Spacer()

                SharedProfileSubscribeButton(podcastUuid: podcast.uuid)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}
