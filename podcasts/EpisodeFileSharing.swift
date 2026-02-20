import UIKit
import PocketCastsDataModel
import PocketCastsUtils
import ObjectiveC

/// Protocol for view controllers that support sharing episode files
protocol EpisodeFileSharing: UIViewController, UIDocumentInteractionControllerDelegate {
    /// The episode to share
    var episodeForFileSharing: Episode? { get }
    
    /// The analytics source for tracking
    var analyticsSource: AnalyticsSource { get }
    
    /// Creates an action for opening the episode file
    /// - Parameter sourceRect: The source rectangle for presenting the document controller
    /// - Returns: An option action if the episode is downloaded, nil otherwise
    func episodeFileAction(from sourceRect: CGRect) -> OptionAction?
}

// Associated object key for storing the document controller
private var documentControllerKey: UInt8 = 0

extension EpisodeFileSharing {
    
    private var documentController: UIDocumentInteractionController? {
        get {
            return objc_getAssociatedObject(self, &documentControllerKey) as? UIDocumentInteractionController
        }
        set {
            objc_setAssociatedObject(self, &documentControllerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func episodeFileAction(from sourceRect: CGRect) -> OptionAction? {
        guard let episode = episodeForFileSharing,
              episode.downloaded(pathFinder: DownloadManager.shared) else {
            return nil
        }
        let openFileAction = OptionAction(label: L10n.podcastShareOpenFile, icon: nil) { [weak self] in
            self?.shareEpisodeFile(episode: episode, sourceRect: sourceRect)
        }
        return openFileAction
    }
    
    func shareEpisodeFile(episode: Episode, sourceRect: CGRect) {
        let fileUrl = URL(fileURLWithPath: episode.pathToDownloadedFile(pathFinder: DownloadManager.shared))
        let docController = UIDocumentInteractionController(url: fileUrl)
        docController.name = episode.displayableTitle()
        docController.delegate = self
        
        // Store the controller to prevent it from being deallocated
        self.documentController = docController
        
        Analytics.track(.podcastShared, properties: ["type": "episode_file", "source": analyticsSource])
        
        let canOpen = docController.presentOpenInMenu(from: sourceRect, in: view, animated: true)
        if !canOpen {
            let alert = UIAlertController(title: L10n.error, message: L10n.podcastShareEpisodeErrorMsg, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: L10n.ok, style: UIAlertAction.Style.cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            
            // Clear the controller on error
            self.documentController = nil
        }
    }
}

