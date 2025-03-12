import Foundation
import SwiftUI

struct PodcastHeaderView: View {

    @EnvironmentObject var theme: Theme
    @StateObject var viewModel: PodcastHeaderViewModel

    var body: some View {
        VStack(spacing: 16) {
            PodcastImageViewWrapper(podcastUUID: viewModel.podcast.uuid, size: .grid)
                .frame(width: 192, height: 192)
            HStack {
                Text(viewModel.podcast.podcastCategory?.localized(seperatingWith: \.isNewline) ?? "")
                Text("·")
                Text(viewModel.podcast.author ?? "")
            }
                .font(.caption)
                .foregroundStyle(theme.primaryText02)
            Text(viewModel.podcast.title ?? "")
                .font(.headline).bold()
                .foregroundStyle(theme.primaryText01)
            StarRatingView(viewModel: viewModel.podcastRatingViewModel,
                                      onRate: {
                viewModel.podcastRatingViewModel.update(podcast: viewModel.podcast, ignoringCache: true)
            })
            podcastActions
            Text(viewModel.podcast.podcastDescription ?? "")
                .font(.body)
                .foregroundStyle(theme.primaryText01)
                .fixedSize(horizontal: false, vertical: true)
            podcastDetails
            EpisodeBookmarksTabsView(delegate: nil)
        }
    }

    private var podcastActions: some View {
        HStack(spacing: 8) {
            Spacer()
            actionButton(imageName: viewModel.folderImage) {}
            actionButton(imageName: "podcast-notification-on") {}
            actionButton(imageName: "podcast-settings") {}
            Spacer()
        }
    }

    private func actionButton(imageName: String, action: @escaping ()->()) -> some View {
        Button {
            action()
        } label: {
            Image(imageName)
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .padding(8)
                .foregroundStyle(theme.primaryIcon02)
        }
//        .accessibilityLabel(action.title)
//        .opacity(action.visible ? 1 : 0)
//        .accessibilityAnimation(.linear(duration: 0.1), value: action.visible)
    }

    private var podcastDetails: some View {
        VStack(alignment: .leading) {
            infoLabel(viewModel.displayAuthor, imageName: "podcast-author", action: {})
            infoLabel(viewModel.displayWebsite, imageName: "podcast-link", action: {})
            infoLabel(viewModel.displayFrequency, imageName: "podcast-schedule", action: {})
            infoLabel(viewModel.displayNextEpisodeDate, imageName: "podcast-nextepisode", action: {})
        }
        .padding()
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
            .inset(by: 0.5)
            .stroke(theme.primaryUi05, lineWidth: 1)
        )
    }

    private func infoLabel(_ label: String, imageName: String, action: @escaping ()->()) -> some View {
        HStack {
            Label(label, image: imageName)
            Spacer()
        }
        .foregroundStyle(theme.primaryIcon02)
    }
}
