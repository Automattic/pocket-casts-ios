import Foundation

/// Owns a `CustomRefreshControl` and wires it up to a podcast feed reload:
/// invokes the supplied `perform` closure on pull, and observes
/// `PodcastFeedReloadNotification` to update the status text and dismiss the
/// control when the reload finishes.
///
/// The owner is responsible for assigning `refreshControl` to a scroll view.
final class PodcastFeedRefreshController {
    let refreshControl = CustomRefreshControl()

    var perform: (() -> Void)?

    init() {
        refreshControl.perform = { [weak self] _ in
            self?.perform?()
        }

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(loading), name: PodcastFeedReloadNotification.loading, object: nil)
        center.addObserver(self, selector: #selector(episodesFound), name: PodcastFeedReloadNotification.episodesFound, object: nil)
        center.addObserver(self, selector: #selector(noEpisodesFound), name: PodcastFeedReloadNotification.noEpisodesFound, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func processRefreshCompleted(_ message: String) {
        refreshControl.set(text: message.uppercased())
        refreshControl.endRefreshing()
    }

    @objc private func loading() {
        refreshControl.set(text: L10n.podcastFeedReloadLoading.uppercased())
    }

    @objc private func episodesFound() {
        processRefreshCompleted(L10n.podcastFeedReloadNewEpisodesFound)
    }

    @objc private func noEpisodesFound() {
        processRefreshCompleted(L10n.podcastFeedReloadNoEpisodesFound)
    }
}
