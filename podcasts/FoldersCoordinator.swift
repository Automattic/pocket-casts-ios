import UIKit
import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class FoldersCoordinator: NSObject {

    enum UpsellFlow {
        case none
        case cta
        case userInitiated
    }

    private var currentUpsellFlow: UpsellFlow = .none

    private let navigationManager: NavigationManager
    private let dataManager: DataManager

    private enum Constants {
        static let minimumNumberOfPodcasts: Int = 8
        static let intervalBetweenUpsell: TimeInterval = 7.days
        static let maxUpsellDisplays: Int = 1
    }

    init(navigationManager: NavigationManager = .sharedManager, dataManager: DataManager = .sharedManager) {
        self.navigationManager = navigationManager
        self.dataManager = dataManager
    }

    func startFolderCreationFlow(from vc: UIViewController) {
        if FeatureFlag.suggestedFolders.enabled {
            newSuggestedFolderCreationFlow(from: vc)
        } else {
            oldFolderCreationFlow(from: vc)
        }
        AnalyticsHelper.folderCreated()
        Analytics.track(.podcastsListFolderButtonTapped)
    }

    func showUpsellIfNeeded(from vc: UIViewController) {
        guard FeatureFlag.suggestedFolders.enabled,
              !SubscriptionHelper.hasActiveSubscription(),
              Settings.suggestedFoldersUpsellCount < Constants.maxUpsellDisplays,
              DateUtil.hasEnoughTimePassed(since: Settings.suggestedFoldersLastUpsellDate, time: Constants.intervalBetweenUpsell),
              DataManager.sharedManager.allPodcasts(includeUnsubscribed: false, reloadFromDatabase: false).count > Constants.minimumNumberOfPodcasts
        else {
            return
        }
        currentUpsellFlow = .cta
        showUpsellSuggestedFolder(from: vc, fromUserAction: false)
    }

    private func oldFolderCreationFlow(from vc: UIViewController) {
        if !SubscriptionHelper.hasActiveSubscription() {
            navigationManager.showUpsellView(from: vc, source: .folders)
            return
        }

        let creatFolderView = CreateFolderView { [weak vc] folderUuid in
            if let folderUuid = folderUuid, let folder = DataManager.sharedManager.findFolder(uuid: folderUuid) {
                vc?.dismiss(animated: true, completion: { [weak self] in
                    self?.navigationManager.navigateTo(NavigationManager.folderPageKey, data: [NavigationManager.folderKey: folder])
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
            currentUpsellFlow = .userInitiated
            showUpsellSuggestedFolder(from: vc)
            return
        }
        let suggestedFoldersView = SuggestedFoldersView { [weak vc, weak self] result in
            guard let self, let vc else { return }

            switch result {
            case .dismiss:
                vc.dismiss(animated: true, completion: nil)
            case .applySuggestedFolders(let folders):
                vc.dismiss(animated: true, completion: nil)
                applySuggestedFolders(folders)
            case .createdManualFolder(let folderUuid):
                guard let folder = dataManager.findFolder(uuid: folderUuid) else {
                    vc.dismiss(animated: true, completion: nil)
                    return
                }
                vc.dismiss(animated: true, completion: { [weak self] in
                    self?.navigationManager.navigateTo(NavigationManager.folderPageKey, data: [NavigationManager.folderKey: folder])
                })
            }
        }
        let hostingController = PCHostingController(rootView: suggestedFoldersView.environmentObject(Theme.sharedTheme))
        vc.present(hostingController, animated: true, completion: nil)
        hostingController.sheetPresentationController?.delegate = self
    }

    private func showUpsellSuggestedFolder(from vc: UIViewController, fromUserAction: Bool = false) {
        let upsellSuggestedFoldersView = SuggestedFoldersUpsellView(model: SuggestedFoldersModel(failedToLoadAction: {[weak vc] in
            guard let vc else { return }
            vc.dismiss(animated: false) { [weak self] in
                self?.navigationManager.showUpsellView(from: vc, source: .folders)
            }
        })) { [weak self] result in
            switch result {
            case .dismiss:
                //Update settings only if this was show by system
                if !fromUserAction {
                    Settings.suggestedFoldersLastUpsellDate = Date.now
                    Settings.suggestedFoldersUpsellCount += 1
                }
                return
            case .applySuggestedFolders:
                //Show subscription/IAP flow
                vc.dismiss(animated: false) {
                    self?.navigationManager.showUpsellView(from: vc, source: .folders)
                }
                return
            default:
                break
            }
        }
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
        hostingController.presentationController?.delegate = self
        vc.present(hostingController, animated: true, completion: nil)

    }

    private func applySuggestedFolders(_ suggestedFolders: [SuggestedFolder]) {
        DataManager.sharedManager.deleteAllFoldersAndMarkSync()
        for suggestedFolder in suggestedFolders {
            let folder = makeFolder(from: suggestedFolder)
            dataManager.bulkSetFolderUuid(folderUuid: folder.uuid, podcastUuids: suggestedFolder.topPodcastUuids)
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
        dataManager.save(folder: folder)
        return folder
    }
}

extension FoldersCoordinator: UISheetPresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if currentUpsellFlow == .none {
            Analytics.track(.suggestedFoldersModalDismissed, properties: [:])
        } else {
            if currentUpsellFlow == .cta {
                Settings.suggestedFoldersLastUpsellDate = Date.now
                Settings.suggestedFoldersUpsellCount += 1
            }
        }
        currentUpsellFlow = .none
    }
}
