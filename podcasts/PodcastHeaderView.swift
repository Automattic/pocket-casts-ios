import Foundation
import PocketCastsDataModel
import SwiftUI

struct PodcastBlurHeaderView: View {

    let podcastUUID: String

    var body: some View {
        GeometryReader { proxy in
            HStack {
                Spacer()
                PodcastImageViewWrapper(podcastUUID: podcastUUID, size: .grid)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                .blur(radius: 120)
                Spacer()
            }
        }
    }
}

struct PodcastHeaderView: View {

    enum Constants {
        static let largeImageSize: CGFloat = 192
        static let smallImageSize: CGFloat = 108
    }

    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: PodcastHeaderViewModel

    @State private var contentHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isExpanded {
                Spacer()
                    .transaction { transaction in
                        transaction.disablesAnimations = true
                    }
            }
            HStack(alignment: .top) {
                Spacer()
                PodcastImageViewWrapper(podcastUUID: viewModel.podcast.uuid, size: .grid)
                    .frame(width: viewModel.isExpanded ? Constants.largeImageSize : Constants.smallImageSize, height: viewModel.isExpanded ? Constants.largeImageSize : Constants.smallImageSize)
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
            PodcastHeaderDescriptionView(htmlDescription: "Sergio", delegate: nil, contentHeight: $contentHeight)
                .frame(height: contentHeight)
            if viewModel.isExpanded {
                VStack {
                    podcastDetails
                    Spacer().frame(height: 24)
                }
                .transition(.collapse)
            }
            EpisodeBookmarksTabsView(delegate: viewModel.delegate)
            Spacer()
            Spacer()
                .frame(height: 8)
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
                .padding(.horizontal, 4)
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
            withAnimation {
                viewModel.subscribeButtonTapped()
            }
        } label: {
            Text(viewModel.isSubscribed ? "" : L10n.follow)
                .font(.body).bold()
                .foregroundStyle(theme.primaryText01)
                .padding()
                .cornerRadius(viewModel.isSubscribed ? 8 : 32)
                .frame(minWidth: viewModel.isSubscribed ? 32 : 150, maxWidth: viewModel.isSubscribed ? 32 : nil, minHeight: viewModel.isSubscribed ? 32 : 40, maxHeight: viewModel.isSubscribed ? 32 : 40)
                .background {
                    Image("discover_tick")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(theme.support02)
                        .tint(theme.primaryUi01)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                        .opacity(viewModel.isSubscribed ? 1 : 0)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: viewModel.isSubscribed ? 32 : 8)
                    .inset(by: 0.5)
                    .stroke(theme.primaryUi05, lineWidth: 1)
                    .opacity(viewModel.isSubscribed ? 0 : 1)
                )
                .clipped()

        }
    }

    private var podcastActions: some View {
        HStack(spacing: 8) {
            Spacer()
            followButton
            if viewModel.isSubscribed {
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
        VStack {
            PodcastHeaderDescriptionView(htmlDescription: viewModel.podcast.podcastHTMLDescription ?? viewModel.podcast.podcastDescription ?? "", delegate: nil, contentHeight: $contentHeight)
                .frame(height: contentHeight)
//            Text(viewModel.podcast.podcastDescription ?? "")
//                .font(.body)
//                .foregroundStyle(theme.primaryText01)
//                .fixedSize(horizontal: false, vertical: true)
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
