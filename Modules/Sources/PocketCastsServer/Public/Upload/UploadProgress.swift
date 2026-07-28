import Foundation
import PocketCastsDataModel
import PocketCastsUtils

public struct UploadProgress {
    public var uploadedSoFar = 0 as Int64
    public var totalToUpload = 0 as Int64
    public var status = UploadStatus.notUploaded

    public func progress() -> Double {
        Double(uploadedSoFar) / Double(totalToUpload)
    }

    public func percentageProgress() -> Double {
        if totalToUpload <= 0 || uploadedSoFar <= 0 {
            return 0
        }

        return Double(uploadedSoFar) / Double(totalToUpload) * 100
    }

    public func percentageProgressAsString() -> String {
        let percentage = progress()

        guard !percentage.isNaN,
              !percentage.isInfinite
        else {
            return 0.localized(.percent)
        }

        return percentage.localized(.percent)
    }
}
