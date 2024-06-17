import PocketCastsDataModel
import UIKit

struct DownloadProgress {
    var downloadedSoFar = 0 as Int64
    var totalToDownload = 0 as Int64
    var status = DownloadStatus.notDownloaded
    var lastUiUpdateTime = Date.distantPast

    func progress() -> Double {
        Double(downloadedSoFar) / Double(totalToDownload)
    }

    func percentageProgress() -> Double {
        if totalToDownload <= 0 || downloadedSoFar <= 0 {
            return 0
        }

        return Double(downloadedSoFar) / Double(totalToDownload) * 100
    }

    func percentageProgressAsString() -> String {
        let percentage = percentageProgress()

        return String(format: "%.0f%%", percentage)
    }
}
