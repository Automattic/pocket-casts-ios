import Foundation
import UIKit
import SwiftUI
import PocketCastsUtils

class ManageDownloadsCoordinator {

    static var shouldShowBanner: Bool {
        guard FeatureFlag.manageDownloadedEpisodes.enabled,
              let percentage = FileManager.devicePercentageFreeSpace,
              EpisodeManager.hasDownloadedEpisodes()
        else {
            return false
        }
        return percentage < 0.1
    }

    static func showModalIfNeeded(from presentationVC: UIViewController, source: String) {
        guard Self.shouldShowBanner
        else {
            return
        }
        if let lastCheckDate = Settings.manageDownloadsLastCheckDate,
           fabs(lastCheckDate.timeIntervalSince(Date.now)) < 7.days {
            return
        }
        Analytics.track(.freeUpSpaceModalShown, properties: ["source": source])
        let modalView = ManageDownloadsModel(initialSize: "", onManageTap: { [weak presentationVC] in
            Analytics.track(.freeUpSpaceManageDownloadsTapped, properties: ["source": source])
            presentationVC?.dismiss(animated: true, completion: {
                presentationVC?.navigationController?.pushViewController(DownloadedFilesViewController(), animated: true)
            })
        }, onNotNowTap: { [weak presentationVC] in
            Analytics.track(.freeUpSpaceMaybeLaterTapped)
            Settings.manageDownloadsLastCheckDate = Date.now
            presentationVC?.dismiss(animated: true)
        })
        let themedVC = ThemedHostingController(rootView: ManageDownloadsModalView(dataModel: modalView))
        if let sheet = themedVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        presentationVC.present(themedVC, animated: true)
    }

}
