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
                .blur(radius: 60)
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

    @State private var contentHeight: CGFloat = RichExpandableLabel.estimateHeightFor(maxLines: 3, lineHeightMultiple: 1.4, font: UIFont.preferredFont(forTextStyle: .body))

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Spacer()
                PodcastImageViewWrapper(podcastUUID: viewModel.podcast.uuid, size: .grid)
                    .frame(width: viewModel.isExpanded ? Constants.largeImageSize : Constants.smallImageSize, height: viewModel.isExpanded ? Constants.largeImageSize : Constants.smallImageSize)
                    .animation(.bouncy, value: viewModel.isExpanded)
                    .onLongPressGesture {
                        viewModel.podcastArtworkTapped()
                    }
                Spacer()
            }
            VStack(spacing: 0) {
                Spacer().frame(height: 24)
                podcastCategory
            }
                .frame(maxHeight: viewModel.isExpanded ? .infinity : 0)
                .opacity(viewModel.isExpanded ? 1 : 0)
                .clipped()
            Spacer().frame(height: 16)
            podcastTitle
            Spacer().frame(height: 16)
            StarRatingView(viewModel: viewModel.podcastRatingViewModel,
                           style: .short,
                           onRate: {
                viewModel.podcastRatingViewModel.update(podcast: viewModel.podcast, ignoringCache: true)
            })
            Spacer().frame(height: 16)
            podcastActions
            Spacer().frame(height: 24)
            VStack {
                podcastDescription
                podcastDetails
                Spacer().frame(height: 24)
            }
                .frame(maxHeight: viewModel.isExpanded ? .infinity : 0)
                .opacity(viewModel.isExpanded ? 1 : 0)
                .clipped()
            EpisodeBookmarksTabsView(delegate: viewModel.delegate)
            Spacer()
                .frame(height: 8)
        }
        .padding()
    }

    private var podcastCategory: some View {
        VStack {
            Text(viewModel.displayCategoryAndAuthor)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(theme.primaryText02)
            .tint(theme.primaryText02)
            .environment(\.openURL, OpenURLAction { url in
                viewModel.categoryTapped()
                return .handled
            })
        }
    }

    private var podcastTitle: some View {
        HStack(spacing: 0) {
            Text(viewModel.podcast.title ?? "")
                .font(.title).bold()
                .fixedSize(horizontal: false, vertical: true)
            Image(systemName: "chevron.up")
                .frame(width: 24, height: 24)
                .padding(.horizontal, 4)
                .rotationEffect(.degrees(viewModel.isExpanded ? 0 : 180))
                .contentShape(Rectangle())
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
                .frame(minWidth: viewModel.isSubscribed ? 32 : viewModel.hasFundingURL ? 118 : 150, maxWidth: viewModel.isSubscribed ? 32 : nil, minHeight: viewModel.isSubscribed ? 32 : 40, maxHeight: viewModel.isSubscribed ? 32 : 40)
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

    private var fundingButton: some View {
        Button {
            viewModel.delegate?.fundingTapped()
        } label: {
            if !viewModel.isSubscribed {
                // Unsubscribed state - larger button next to Follow
                fundingImage(width: 20.0, height: 20.0, padding: 10.0)
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .inset(by: 0.5)
                            .stroke(theme.primaryUi05, lineWidth: 1)
                    )

            } else {
                // Subscribed state - compact button with other actions
                fundingImage(width: 24.0, height: 24.0, padding: 8.0)
            }
        }
        .accessibilityLabel(L10n.funding)
    }

    private func fundingImage(width: CGFloat, height: CGFloat, padding: CGFloat) -> some View {
        return Image("podcast-funding")
            .renderingMode(.template)
            .resizable()
            .frame(width: width, height: height)
            .padding(padding)
            .foregroundStyle(theme.primaryIcon02)
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
                if viewModel.hasFundingURL {
                    fundingButton
                }
                actionButton(title: L10n.settings, imageName: "podcast-settings") {
                    viewModel.delegate?.settingsTapped()
                }
            } else {
                if viewModel.hasFundingURL {
                    fundingButton
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
        PodcastHeaderDescriptionView(htmlDescription: viewModel.htmlDescription, delegate: viewModel) { newHeight in
            DispatchQueue.main.async {
                contentHeight = newHeight
            }
        }
        .frame(height: contentHeight)
        .animation(.easeInOut(duration: 0.1), value: contentHeight)
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
