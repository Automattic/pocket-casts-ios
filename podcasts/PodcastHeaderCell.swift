import Foundation
import SwiftUI
import UIKit

import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class PodcastHeaderCell: UITableViewCell {

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let podcast: Podcast
    let viewController: UIViewController

    init(podcast: Podcast, vc: UIViewController) {
        self.podcast = podcast
        self.viewController = vc
        super.init(style: .default, reuseIdentifier: "PodcastHeaderCell")
        commonSetup()
    }

    func commonSetup() {
        self.backgroundColor = .clear
        let viewModel = PodcastHeaderViewModel(podcast: podcast)
        if #available(iOS 16.0, *) {
            self.contentConfiguration = UIHostingConfiguration(content: {
                PodcastHeaderView(viewModel: viewModel).setupDefaultEnvironment()
            }
            )
        } else {
            // Fallback on earlier versions
            configureCellFromSwiftUIView(cell: self, viewController: self.viewController, rootView: PodcastHeaderView(viewModel: viewModel).setupDefaultEnvironment().padding())
        }
    }

    func configureCellFromSwiftUIView(cell: UITableViewCell, viewController: UIViewController, rootView: some View) {

        let swiftUICellViewController = UIHostingController(rootView: rootView)
        swiftUICellViewController.view.backgroundColor = .clear
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.layoutIfNeeded()
        cell.selectionStyle = UITableViewCell.SelectionStyle.none

        viewController.addChild(swiftUICellViewController)
        cell.contentView.addSubview(swiftUICellViewController.view)
        swiftUICellViewController.view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addConstraint(NSLayoutConstraint(item: swiftUICellViewController.view!, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: cell.contentView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: 0.0))
        cell.contentView.addConstraint(NSLayoutConstraint(item: swiftUICellViewController.view!, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: cell.contentView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: 0.0))
        cell.contentView.addConstraint(NSLayoutConstraint(item: swiftUICellViewController.view!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: cell.contentView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0.0))
        cell.contentView.addConstraint(NSLayoutConstraint(item: swiftUICellViewController.view!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: cell.contentView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0.0))

        swiftUICellViewController.didMove(toParent: viewController)
        swiftUICellViewController.view.layoutIfNeeded()

    }
}

class PodcastHeaderViewModel: ObservableObject {
    let podcast: Podcast

    init(podcast: Podcast) {
        self.podcast = podcast
    }

    lazy var podcastRatingViewModel: PodcastRatingViewModel = {
        let podcastRatingViewModel = PodcastRatingViewModel()
        podcastRatingViewModel.update(podcast: podcast)
        return podcastRatingViewModel
    }()

    var folderImage: String {
        let folderImage = SubscriptionHelper.hasActiveSubscription() ? (podcast.folderUuid?.isEmpty ?? true) ? "folder-empty" : "folder-check" : "folder-create"
        return folderImage
    }

    var displayAuthor: String {
        guard let podcastAuthor = podcast.author else {
            return ""
        }
        return podcastAuthor
    }

    var displayWebsite: String {
        guard let websiteUrl = podcast.podcastUrl, let host = URL(string: websiteUrl)?.host else {
            return ""
        }
        if host.startsWith(string: "www.") {
            let wwwIndex = host.index(host.startIndex, offsetBy: 4)
            return String(host[wwwIndex...])
        } else {
            return host
        }
    }

    var displayFrequency: String {
        guard let frequency = podcast.displayableFrequency() else {
            return ""
        }
        return L10n.paidPodcastReleaseFrequencyFormat(frequency)
    }

    var displayNextEpisodeDate: String {
        guard let estimatedDate = podcast.displayableNextEpisodeDate() else {
            return ""
        }
        return L10n.paidPodcastNextEpisodeFormat(estimatedDate)
    }
}

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
