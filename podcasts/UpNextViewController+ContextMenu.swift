import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

extension UpNextViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard !isMultiSelectEnabled,
              location.x < (upNextTable.bounds.width - UpNextViewController.rearrangeWidth),
              let indexPath = upNextTable.indexPathForRow(at: location),
              tableData[indexPath.section] == .upNextSection,
              let episode = PlaybackManager.shared.queue.episodeAt(index: indexPath.row) else {
            return nil
        }

        track(.upNextQueueEpisodeLongPressed, properties: ["will_play": false])

        return UIContextMenuConfiguration(
            identifier: indexPath as NSCopying,
            previewProvider: { [weak self] in
                EpisodePreviewViewController(episode: episode, themeOverride: self?.themeOverride)
            },
            actionProvider: { [weak self] _ in
                self?.makeContextMenu(for: episode)
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
              let cell = upNextTable.cellForRow(at: indexPath) as? PlayerCell else {
            return nil
        }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        return UITargetedPreview(view: cell.contentView, parameters: parameters)
    }

    private func makeContextMenu(for episode: BaseEpisode) -> UIMenu {
        let playNow = UIAction(title: L10n.playNow, image: UIImage(named: "episode-play")?.withRenderingMode(.alwaysTemplate)) { _ in
            AnalyticsPlaybackHelper.shared.currentSource = .upNext
            PlaybackActionHelper.play(episode: episode)
        }

        let removeFromUpNext = UIAction(title: L10n.removeFromUpNext, image: UIImage(named: "episode-removenext")) { _ in
            AnalyticsEpisodeHelper.shared.currentSource = .upNext
            PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: true, userInitiated: true)
        }

        let markAsPlayed = UIAction(title: L10n.markPlayed, image: UIImage(named: "episode-markasplayed")) { _ in
            AnalyticsEpisodeHelper.shared.currentSource = .upNext
            EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
        }

        let playbackGroup = UIMenu(title: "", options: .displayInline, children: [playNow, removeFromUpNext, markAsPlayed])

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
