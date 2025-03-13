import Foundation
import PocketCastsDataModel
import SwiftUI

struct PodcastHeaderView: View {

    @EnvironmentObject var theme: Theme
    @StateObject var viewModel: PodcastHeaderViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Spacer()
                PodcastImageViewWrapper(podcastUUID: viewModel.podcast.uuid, size: .grid)
                    .frame(width: viewModel.isExpanded ? 192 : 108, height: viewModel.isExpanded ? 192 : 108)
                Spacer()
            }
            if viewModel.isExpanded {
                VStack(spacing: 0) {
                    Spacer().frame(height: 24)
                    podcastCategory
                }
                .transition(.collapse.combined(with: .move(edge: .top)))
            }
            Spacer().frame(height: 16)
            podcastTitle
            Spacer().frame(height: 16)
            StarRatingView(viewModel: viewModel.podcastRatingViewModel, style: .short,
                                      onRate: {
                viewModel.podcastRatingViewModel.update(podcast: viewModel.podcast, ignoringCache: true)
            })
            Spacer().frame(height: 16)
            podcastActions
            Spacer().frame(height: 24)
            if viewModel.isExpanded {
                VStack {
                    podcastDescription
                    podcastDetails
                    Spacer().frame(height: 24)
                }
                .transition(.collapse)
            }
            EpisodeBookmarksTabsView(delegate: viewModel.delegate)
         }
    }

    private var podcastCategory: some View {
        VStack {
            Text(viewModel.displayCategory)
                .font(.callout)
            .foregroundStyle(theme.primaryText02)
        }
    }

    private var podcastTitle: some View {
        HStack(spacing: 0) {
            Text(viewModel.podcast.title ?? "")
                .font(.title).bold()
            Image(systemName: "chevron.up")
                .padding()
                .rotationEffect(.degrees(viewModel.isExpanded ? 0 : 180))
        }
        .foregroundStyle(theme.primaryText01)
        .multilineTextAlignment(.center)
        .onTapGesture {
            withAnimation() {
                viewModel.toggleExpanded()
            }
        }
    }

    private var followButton: some View {
        Button() {
            viewModel.subscribeButtonTapped()
        } label: {
            Text(viewModel.podcast.subscribed != 0 ? L10n.unfollow : L10n.follow)
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
        HStack(spacing: 0) {
            Spacer()
            followButton
            if viewModel.isPodcastSubscribed {
                actionButton(title: L10n.folder, imageName: viewModel.folderImage) {
                    viewModel.delegate?.folderTapped()
                }
                actionButton(title: viewModel.podcast.pushEnabled ? L10n.notificationsOn : L10n.notificationsOff, imageName: viewModel.podcast.pushEnabled ? "podcast-notification-on" : "podcast-notification-off") {
                    viewModel.delegate?.notificationTapped()
                }
                actionButton(title: L10n.settings, imageName: "podcast-settings") {
                    viewModel.delegate?.settingsTapped()
                }
            }
            Spacer()
        }
    }

    private func actionButton(title: String, imageName: String, action: @escaping ()->()) -> some View {
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
        .accessibilityLabel(title)
    }

    private var podcastDescription: some View {
        HStack {
            Text(viewModel.podcast.podcastDescription ?? "")
                .font(.body)
                .foregroundStyle(theme.primaryText01)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var podcastDetails: some View {
        VStack(alignment: .leading) {
            if let displayAuthor = viewModel.displayAuthor {
                infoLabel(displayAuthor, imageName: "podcast-author", action: {})
            }
            if let displayWebsite = viewModel.displayWebsite {
                infoLabel(displayWebsite, imageName: "podcast-link", isLink: true, action: { viewModel.websiteLinkTapped() })
            }
            if let displayFrequency = viewModel.displayFrequency {
                infoLabel(displayFrequency, imageName: "podcast-schedule", action: {})
            }
            if let displayNextEpisodeDate = viewModel.displayNextEpisodeDate {
                infoLabel(displayNextEpisodeDate, imageName: "podcast-nextepisode", action: {})
            }
        }
        .padding()
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
            .inset(by: 0.5)
            .stroke(theme.primaryUi05, lineWidth: 1)
        )
    }

    private func infoLabel(_ label: String, imageName: String, isLink: Bool = false, action: @escaping ()->()) -> some View {
        HStack {
            Image(imageName)
                .foregroundStyle(theme.primaryIcon02)
            Text(label)
                .foregroundStyle(isLink ? theme.support05 : theme.primaryText01)
                .onTapGesture {
                    action()
                }
            Spacer()
        }
    }
}

extension AnyTransition {
    static var collapse: AnyTransition { get {
        AnyTransition.modifier(
            active: ShapeClipModifier(shape: CollapseShape(pct: 1)),
            identity: ShapeClipModifier(shape: CollapseShape(pct: 0)))
        }
    }
}

struct ShapeClipModifier<S: Shape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        content.clipShape(shape)
    }
}

struct CollapseShape: Shape {
    var pct: CGFloat

    var animatableData: CGFloat {
        get { pct }
        set { pct = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: (1.0-pct) * rect.height))

        return path
    }
}

struct PodcastHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        PodcastHeaderView(viewModel: PodcastHeaderViewModel(podcast: Podcast()))
            .previewWithAllThemes()
    }
}
