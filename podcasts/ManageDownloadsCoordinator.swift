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
        if let lastCheckDate = Settings.manageDownloadsLastCheckDate,
           fabs(lastCheckDate.timeIntervalSince(Date.now)) < 14.days {
           return false
        }
        return percentage < 0.1
    }

    static func showModalIfNeeded(from presentationVC: UIViewController, source: String) {
        guard Self.shouldShowBanner else {
            return
        }
        Analytics.track(.freeUpSpaceModalShown, properties: ["source": source])
        let dataModel = ManageDownloadsModel(initialSize: "", onManageTap: { [weak presentationVC] in
            Analytics.track(.freeUpSpaceManageDownloadsTapped, properties: ["source": source])
            presentationVC?.dismiss(animated: true, completion: {
                presentationVC?.navigationController?.pushViewController(DownloadedFilesViewController(), animated: true)
            })
        }, onNotNowTap: { [weak presentationVC] in
            Analytics.track(.freeUpSpaceMaybeLaterTapped, properties: ["source": source])
            Settings.manageDownloadsLastCheckDate = Date.now
            presentationVC?.dismiss(animated: true)
        })
        BottomSheetSwiftUIWrapper.present(
            ManageDownloadsModalView(dataModel: dataModel),
            autoSize: true,
            showingGrabber: true,
            in: presentationVC) {
                Settings.manageDownloadsLastCheckDate = Date.now
            }
        return
    }

}
