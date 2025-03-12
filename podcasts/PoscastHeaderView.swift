import Foundation
import PocketCastsDataModel
import SwiftUI

struct PodcastHeaderView: View {

    @EnvironmentObject var theme: Theme
    @StateObject var viewModel: PodcastHeaderViewModel

    var body: some View {
        VStack(spacing: 16) {
            PodcastImageViewWrapper(podcastUUID: viewModel.podcast.uuid, size: .grid)
                .frame(width: viewModel.isExpanded ? 192 : 108, height: viewModel.isExpanded ? 192 : 108)
                .animation(.linear, value: viewModel.isExpanded)
            if viewModel.isExpanded {
                podcastCategory
            }
            podcastTitle
            StarRatingView(viewModel: viewModel.podcastRatingViewModel,
                                      onRate: {
                viewModel.podcastRatingViewModel.update(podcast: viewModel.podcast, ignoringCache: true)
            })
            podcastActions
            if viewModel.isExpanded {
                VStack {
                    podcastDescription
                    podcastDetails
                }
                .frame(height: viewModel.isExpanded ? nil : 0, alignment: .top)
                .clipped()
            }
            EpisodeBookmarksTabsView(delegate: viewModel.delegate)
            Spacer()
        }
    }

    private var podcastCategory: some View {
        VStack {
            Text(viewModel.displayCategory)
            .font(.caption)
            .foregroundStyle(theme.primaryText02)
        }
        .frame(height: viewModel.isExpanded ? nil : 0, alignment: .top)
        .clipped()
    }

    private var podcastTitle: some View {
        HStack(spacing: 0) {
            Text(viewModel.podcast.title ?? "")
            Image(systemName: "chevron.up")
                .rotationEffect(.degrees(viewModel.isExpanded ? 0 : 180))
                .padding()
                .animation(.easeInOut, value: viewModel.isExpanded)
        }
        .font(.headline)
        .foregroundStyle(theme.primaryText01)
        .multilineTextAlignment(.center)
        .onTapGesture {
            withAnimation {
                viewModel.isExpanded.toggle()
            }
        }
    }

    private var followButton: some View {
        Button() {
            viewModel.subscribeButtonTapped()
        } label: {
            Text(viewModel.isPodcastSubscribed ? L10n.unfollow : L10n.follow)
                .font(.body).bold()
                .foregroundStyle(theme.primaryText01)
                .padding()
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                    .inset(by: 0.5)
                    .stroke(theme.primaryUi05, lineWidth: 1)
                )
        }
        .frame(width: 150, height: 40)
    }

    private var podcastActions: some View {
        HStack(spacing: 8) {
            Spacer()
            followButton
            if viewModel.isPodcastSubscribed {
                actionButton(imageName: viewModel.folderImage) {
                    viewModel.delegate?.folderTapped()
                }
                actionButton(imageName: "podcast-notification-on") {
                    viewModel.delegate?.notificationTapped()
                }
                actionButton(imageName: "podcast-settings") {
                    viewModel.delegate?.settingsTapped()
                }
            }
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

    private var podcastDescription: some View {
        Text(viewModel.podcast.podcastDescription ?? "")
            .font(.body)
            .foregroundStyle(theme.primaryText01)
            .fixedSize(horizontal: false, vertical: true)
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

struct PodcastHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        PodcastHeaderView(viewModel: PodcastHeaderViewModel(podcast: Podcast()))
            .previewWithAllThemes()
    }
}
