import UIKit
import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import Combine

class FoldersCoordinator: NSObject {

    enum UpsellFlow {
        case none
        case cta
        case userInitiated
    }

    private var currentUpsellFlow: UpsellFlow = .none
    private weak var currentVC: UIViewController? = nil

    private var currentSource: AnalyticsSource = .unknown

    private let startingTime: Date = Date.now

    private let navigationManager: NavigationManager
    private let dataManager: DataManager
    private let suggestedFoldersModel: SuggestedFoldersModel

    private enum Constants {
        static let minimumNumberOfPodcasts: Int = 7
        static let intervalBetweenUpsell: TimeInterval = 7.days
        static let maxUpsellDisplays: Int = 2
        static let intervalAfterStartup: TimeInterval = 10.seconds
    }

    init(navigationManager: NavigationManager = .sharedManager, dataManager: DataManager = .sharedManager) {
        self.navigationManager = navigationManager
        self.dataManager = dataManager
        self.suggestedFoldersModel = SuggestedFoldersModel()
        super.init()
        Task {
            await suggestedFoldersModel.load()
        }
    }

    func startFolderCreationFlow(from vc: UIViewController) {
        if FeatureFlag.suggestedFolders.enabled,
           dataManager.allPodcasts(includeUnsubscribed: false, reloadFromDatabase: false).count > Constants.minimumNumberOfPodcasts,
           suggestedFoldersModel.loadingState == .loaded,
           didPodcastsChanged() {
            suggestedFolderCreationFlow(from: vc, source: .podcastsList)
        } else {
            manualFolderCreationFlow(from: vc)
        }
        AnalyticsHelper.folderCreated()
        Analytics.track(.podcastsListFolderButtonTapped)
    }

    func showSuggestedFolders(from vc: UIViewController, source: AnalyticsSource = .notifications) {
        guard FeatureFlag.suggestedFolders.enabled,
              dataManager.allPodcasts(includeUnsubscribed: false, reloadFromDatabase: false).count > Constants.minimumNumberOfPodcasts else {
            return
        }
        suggestedFolderCreationFlow(from: vc, source: source)
    }

    func showUpsellIfNeeded(from vc: UIViewController) {
        guard FeatureFlag.suggestedFolders.enabled,
              vc.presentedViewController == nil,
              !SubscriptionHelper.hasActiveSubscription(),
              DateUtil.hasEnoughTimePassed(since: startingTime, time: Constants.intervalAfterStartup),
              Settings.suggestedFoldersUpsellCount < Constants.maxUpsellDisplays,
              DateUtil.hasEnoughTimePassed(since: Settings.suggestedFoldersLastUpsellDate, time: Constants.intervalBetweenUpsell),
              dataManager.allPodcasts(includeUnsubscribed: false, reloadFromDatabase: false).count > Constants.minimumNumberOfPodcasts,
              suggestedFoldersModel.loadingState == .loaded
        else {
            return
        }
        currentUpsellFlow = .cta
        showUpsellSuggestedFolder(from: vc, fromUserAction: false, source: .suggestedFolderPopup)
    }

    private func manualFolderCreationFlow(from vc: UIViewController) {
        if !SubscriptionHelper.hasActiveSubscription() {
            navigationManager.showUpsellView(from: vc, source: .folders)
            return
        }

        let creatFolderView = CreateFolderView { [weak vc, weak self] folderUuid in
            guard let self = self else { return }
            if let folderUuid = folderUuid, let folder = dataManager.findFolder(uuid: folderUuid) {
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

    private func suggestedFolderCreationFlow(from vc: UIViewController, source: AnalyticsSource) {
        if !SubscriptionHelper.hasActiveSubscription() {
            currentUpsellFlow = .userInitiated
            showUpsellSuggestedFolder(from: vc, source: source)
            return
        }
        let suggestedFoldersView = SuggestedFoldersView(model: suggestedFoldersModel, source: source) { [weak vc, weak self] result in
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
        let hostingController = UIHostingController(rootView: suggestedFoldersView.environmentObject(Theme.sharedTheme))
        vc.present(hostingController, animated: true, completion: nil)
        hostingController.sheetPresentationController?.delegate = self
    }

    private func showUpsellSuggestedFolder(from vc: UIViewController, fromUserAction: Bool = false, source: AnalyticsSource) {
        let suggestedFoldersView = SuggestedFoldersView(model: suggestedFoldersModel, source: source) { [weak vc, weak self] result in
            guard let self, let vc else { return }
            switch result {
            case .dismiss:
                vc.dismiss(animated: true)
                //Update settings only if this was show by system
                if !fromUserAction {
                    Settings.suggestedFoldersLastUpsellDate = Date.now
                    Settings.suggestedFoldersUpsellCount += 1
                }
                return
            case .applySuggestedFolders, .createdManualFolder:
                //Show upsell flow
                startUpsellFlow(from: vc, source: source, upgradeSource: .suggestedFolders)
                return
            }
        }
        let hostingController = UIHostingController(rootView: suggestedFoldersView.environmentObject(Theme.sharedTheme))
        vc.present(hostingController, animated: true, completion: nil)
        hostingController.sheetPresentationController?.delegate = self

    }

    private func applySuggestedFolders(_ suggestedFolders: [SuggestedFolder]) {
        saveLastUuidsUsed()
        DataManager.sharedManager.deleteAllFoldersAndMarkSync()
        for suggestedFolder in suggestedFolders {
            let folder = makeFolder(from: suggestedFolder)
            dataManager.bulkSetFolderUuid(folderUuid: folder.uuid, podcastUuids: suggestedFolder.podcastUuids)
        }
        NotificationCenter.postOnMainThread(notification: ServerNotifications.podcastsRefreshed, object: nil)
    }

    private var currentPodcastsHash: String {
        let uuids = dataManager.allPodcastsOrderedByAddedDate().map { $0.uuid }.sorted()
        let md5 = String(uuids.joined(separator: "")).md5
        return md5
    }

    private func saveLastUuidsUsed() {
        Settings.suggestedFoldersLastPodcastsUsed = currentPodcastsHash
    }

    private func didPodcastsChanged() -> Bool {
        return Settings.suggestedFoldersLastPodcastsUsed != currentPodcastsHash
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

    private func startUpsellFlow(from vc: UIViewController, source: AnalyticsSource, upgradeSource: PlusUpgradeViewSource) {
        currentVC = vc
        currentSource = source
        addObservers()
        vc.dismiss(animated: false) {
            self.navigationManager.showUpsellView(from: vc, source: upgradeSource, flow: .suggestedFolderUpsell)
        }
    }

    private var cancellables = Set<AnyCancellable>()
    private func addObservers() {
        // Observe IAP flows notification
        Publishers.Merge3(
            NotificationCenter.default.publisher(for: ServerNotifications.iapPurchaseFailed),
            NotificationCenter.default.publisher(for: ServerNotifications.iapPurchaseCancelled),
            NotificationCenter.default.publisher(for: ServerNotifications.iapPurchaseCompleted)
        )
        .receive(on: OperationQueue.main)
        .sink { [unowned self] notification in
            refreshAfterUpsellFlow()
        }
        .store(in: &cancellables)

        //Observe Login/Signup notification
        NotificationCenter.default.publisher(for: .onboardingFlowDidDismiss)
        .receive(on: OperationQueue.main)
        .sink { [unowned self] notification in
            refreshAfterUpsellFlow()
        }
        .store(in: &cancellables)
    }

    private func refreshAfterUpsellFlow() {
        guard FeatureFlag.suggestedFolders.enabled,
              SubscriptionHelper.hasActiveSubscription(),
              let currentVC
        else {
            currentVC = nil
            currentUpsellFlow = .none
            cancellables = []
            return
        }
        cancellables = []
        currentUpsellFlow = .none
        suggestedFolderCreationFlow(from: currentVC, source: currentSource)
        self.currentVC = nil
    }
}

extension FoldersCoordinator: UISheetPresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if currentUpsellFlow == .none {
            Analytics.track(.suggestedFoldersPageDismissed, properties: [:])
        } else {
            if currentUpsellFlow == .cta {
                Settings.suggestedFoldersLastUpsellDate = Date.now
                Settings.suggestedFoldersUpsellCount += 1
            }
        }
        currentUpsellFlow = .none
        currentVC = nil
    }
}
