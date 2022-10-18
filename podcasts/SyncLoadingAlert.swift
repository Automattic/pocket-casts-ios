import UIKit
import PocketCastsServer

class SyncLoadingAlert: ShiftyLoadingAlert {
    private var totalPodcastsToImport: Int = 0

    init() {
        super.init(title: L10n.syncAccountLogin)
    }

    override func showAlert(_ presentingController: UIViewController, hasProgress: Bool, completion: (() -> Void)?) {
        super.showAlert(presentingController, hasProgress: hasProgress, completion: completion)
        subscribeToSyncChanges()
    }

    override func hideAlert(_ animated: Bool) {
        super.hideAlert(animated)
        unSubscribeToSyncChanges()
    }

    private func subscribeToSyncChanges() {
        NotificationCenter.default.addObserver(self, selector: #selector(syncProgressCountKnown(_:)), name: ServerNotifications.syncProgressPodcastCount, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(syncUpToChanged(_:)), name: ServerNotifications.syncProgressPodcastUpto, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(podcastsImported), name: ServerNotifications.syncProgressImportedPodcasts, object: nil)
    }

    private func unSubscribeToSyncChanges() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func syncProgressCountKnown(_ notification: Notification) {
        if let number = notification.object as? NSNumber {
            totalPodcastsToImport = number.intValue
        }
    }

    @objc private func syncUpToChanged(_ notification: Notification) {
        guard let number = notification.object as? NSNumber else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let upTo = number.intValue
            if self.totalPodcastsToImport > 0 {
                self.title = L10n.syncProgress(upTo.localized(), self.totalPodcastsToImport.localized())
                self.progress = CGFloat(upTo / self.totalPodcastsToImport)
            } else {
                // Used when the total number of podcasts to sync isn't known.
                self.title = upTo == 1 ? L10n.syncProgressUnknownCountSingular : L10n.syncProgressUnknownCountPluralFormat(upTo.localized())
            }
        }
    }

    @objc private func podcastsImported() {
        DispatchQueue.main.async {
            self.title = L10n.syncInProgress
        }
    }
}
