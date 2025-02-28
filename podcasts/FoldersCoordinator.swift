import UIKit
import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class FoldersCoordinator: NSObject {

    	func startFolderCreationFlow(from vc: UIViewController) {
        if FeatureFlag.suggestedFolders.enabled {
            newSuggestedFolderCreationFlow(from: vc)
        } else {
            oldFolderCreationFlow(from: vc)
        }
        AnalyticsHelper.folderCreated()
        Analytics.track(.podcastsListFolderButtonTapped)

    }

    private func oldFolderCreationFlow(from vc: UIViewController) {
        if !SubscriptionHelper.hasActiveSubscription() {
            NavigationManager.sharedManager.showUpsellView(from: vc, source: .folders)
            return
        }

        let creatFolderView = CreateFolderView { [weak vc] folderUuid in
            if let folderUuid = folderUuid, let folder = DataManager.sharedManager.findFolder(uuid: folderUuid) {
                vc?.dismiss(animated: true, completion: {
                    NavigationManager.sharedManager.navigateTo(NavigationManager.folderPageKey, data: [NavigationManager.folderKey: folder])
                })
            } else {
                vc?.dismiss(animated: true, completion: nil)
            }
        }
        let hostingController = PCHostingController(rootView: creatFolderView.environmentObject(Theme.sharedTheme))

        vc.present(hostingController, animated: true, completion: nil)
    }

    private func newSuggestedFolderCreationFlow(from vc: UIViewController) {
        if !SubscriptionHelper.hasActiveSubscription() {
            if !SyncManager.isUserLoggedIn() {
                NavigationManager.sharedManager.showUpsellView(from: vc, source: .folders)
            } else {
                showUpSellSuggestedFolder(from: vc)
            }
            return
        }
        let suggestedFoldersView = SuggestedFoldersView { [weak vc, weak self] result in
            switch result {
            case .dismiss:
                vc?.dismiss(animated: true, completion: nil)
            case .applySuggestedFolders(let folders):
                vc?.dismiss(animated: true, completion: nil)
                self?.applySuggestedFolders(folders)
            case .createdManualFolder(let folderUuid):
                guard let folder = DataManager.sharedManager.findFolder(uuid: folderUuid) else {
                    vc?.dismiss(animated: true, completion: nil)
                    return
                }
                vc?.dismiss(animated: true, completion: {
                    NavigationManager.sharedManager.navigateTo(NavigationManager.folderPageKey, data: [NavigationManager.folderKey: folder])
                })
            }
        }
        let hostingController = PCHostingController(rootView: suggestedFoldersView.environmentObject(Theme.sharedTheme))
        vc.present(hostingController, animated: true, completion: nil)
        hostingController.sheetPresentationController?.delegate = self
    }

    private func showUpSellSuggestedFolder(from vc: UIViewController) {
        let upsellSuggestedFoldersView = SuggestedFoldersUpSellView(model: SuggestedFoldersModel(failedToLoadAction: {[weak vc] in
            guard let vc else { return }
            vc.dismiss(animated: false) {
                NavigationManager.sharedManager.showUpsellView(from: vc, source: .folders)
            }
        }))
        let hostingController = PCHostingController(rootView: upsellSuggestedFoldersView.environmentObject(Theme.sharedTheme))
        if UIDevice.current.userInterfaceIdiom == .phone {
            if #available(iOS 16.0, *) {
                hostingController.sheetPresentationController?.detents = [.custom(resolver: { context in
                    return context.maximumDetentValue * 0.65
                })]
            } else {
                hostingController.sheetPresentationController?.detents = [.medium()]
            }
            hostingController.sheetPresentationController?.prefersGrabberVisible = true
        } else {
            hostingController.modalPresentationStyle = .formSheet
        }
        vc.present(hostingController, animated: true, completion: nil)

    }

    private func applySuggestedFolders(_ suggestedFolders: [SuggestedFolder]) {
        DataManager.sharedManager.clearAllFolderInformation()
        for suggestedFolder in suggestedFolders {
            let folder = makeFolder(from: suggestedFolder)
            DataManager.sharedManager.bulkSetFolderUuid(folderUuid: folder.uuid, podcastUuids: suggestedFolder.topPodcastUuids)
        }
        NotificationCenter.postOnMainThread(notification: ServerNotifications.podcastsRefreshed, object: nil)
    }

    private func makeFolder(from suggestedFolder: SuggestedFolder) -> Folder {
        let folder = Folder()
        folder.name = suggestedFolder.name
        folder.color = suggestedFolder.color
        folder.addedDate = Date()
        folder.syncModified = TimeFormatter.currentUTCTimeInMillis()
        folder.sortOrder = ServerPodcastManager.shared.lowestSortOrderForHomeGrid() - 1

        // the sort type for newly created folders defaults to the same thing the home grid is set to
        folder.sortType = Int32(Settings.homeFolderSortOrder().old.rawValue)
        DataManager.sharedManager.save(folder: folder)
        return folder
    }
}

extension FoldersCoordinator: UISheetPresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        Analytics.track(.suggestedFoldersModalDismissed, properties: [:])
    }
}
