import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

extension UpNextViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard !isMultiSelectEnabled,
              let indexPath = upNextTable.indexPathForRow(at: location) else {
            return nil
        }

        let isNowPlaying = tableData[indexPath.section] == .nowPlayingSection
        let episode: BaseEpisode?
        if isNowPlaying {
            episode = PlaybackManager.shared.currentEpisode()
        } else {
            guard location.x < (upNextTable.bounds.width - UpNextViewController.rearrangeWidth) else { return nil }
            episode = PlaybackManager.shared.queue.episodeAt(index: indexPath.row)
        }
        guard let episode else { return nil }

        track(.upNextQueueEpisodeLongPressed, properties: ["will_play": false])

        return UIContextMenuConfiguration(
            identifier: indexPath as NSCopying,
            previewProvider: { [weak self] in
                EpisodePreviewViewController(episode: episode, themeOverride: self?.themeOverride)
            },
            actionProvider: { [weak self] _ in
                self?.makeContextMenu(for: episode, isNowPlaying: isNowPlaying)
            }
        )
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        targetedPreview(for: configuration)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        targetedPreview(for: configuration)
    }

    private func targetedPreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = upNextTable.cellForRow(at: indexPath) else {
            return nil
        }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        let targetView = (cell as? UpNextNowPlayingCell)?.roundedBackgroundView ?? cell.contentView
        return UITargetedPreview(view: targetView, parameters: parameters)
    }

    private func makeContextMenu(for episode: BaseEpisode, isNowPlaying: Bool = false) -> UIMenu {
        var playbackActions = [UIAction]()

        if !isNowPlaying {
            let playNow = UIAction(title: L10n.playNow, image: UIImage(named: "episode-play")?.withRenderingMode(.alwaysTemplate)) { _ in
                AnalyticsPlaybackHelper.shared.currentSource = .upNext
                PlaybackActionHelper.play(episode: episode)
            }
            playbackActions.append(playNow)

            let removeFromUpNext = UIAction(title: L10n.removeFromUpNext, image: UIImage(named: "episode-removenext")) { _ in
                AnalyticsEpisodeHelper.shared.currentSource = .upNext
                PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: true, userInitiated: true)
            }
            playbackActions.append(removeFromUpNext)
        }

        let markAsPlayed = UIAction(title: L10n.markPlayed, image: UIImage(named: "episode-markasplayed")) { _ in
            AnalyticsEpisodeHelper.shared.currentSource = .upNext
            EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
        }
        playbackActions.append(markAsPlayed)

        let playbackGroup = UIMenu(title: "", options: .displayInline, children: playbackActions)

        let goToEpisode = UIAction(title: L10n.goToEpisode, image: UIImage(systemName: "info.circle")) { [weak self] _ in
            self?.showEpisodeDetailViewController(for: episode)
        }

        var navigationActions = [goToEpisode]
        if let episode = episode as? Episode, let podcast = episode.parentPodcast() {
            let goToPodcast = UIAction(title: L10n.goToPodcast, image: UIImage(named: "gotoarrow")) { [weak self] _ in
                self?.goToPodcast(podcast)
            }
            navigationActions.append(goToPodcast)
        }
        let navigationGroup = UIMenu(title: "", options: .displayInline, children: navigationActions)

        var children: [UIMenuElement] = [playbackGroup, navigationGroup]

        if let episode = episode as? Episode {
            let share = UIAction(title: L10n.shareEpisode, image: UIImage(named: "podcast-share")) { [weak self] _ in
                guard let self else { return }
                SharingHelper.shared.shareLinkTo(episode: episode, shareTime: 0, fromController: self, sourceRect: self.view.bounds, sourceView: self.view, fromSource: .upNext)
            }
            let shareGroup = UIMenu(title: "", options: .displayInline, children: [share])
            children.append(shareGroup)
        }

        return UIMenu(title: "", children: children)
    }

    private func goToPodcast(_ podcast: Podcast) {
        let navigate = {
            NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcast])
        }
        if presentingViewController != nil {
            dismiss(animated: true, completion: navigate)
        } else {
            navigate()
        }
    }
}
