import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

extension UserEpisode {
    // MARK: - Helpers

    func displayableInfo(includeSize: Bool = true) -> String {
        if uploading() {
            let progress = UploadManager.shared.progressManager.progressForEpisode(uuid)?.percentageProgressAsString() ?? ""
            return L10n.podcastUploading(progress).trimmingCharacters(in: .whitespaces)
        } else if uploadWaitingForWifi() {
            return L10n.podcastWaitingUpload
        } else if uploadFailed() {
            return L10n.podcastFailedUpload
        } else {
            return commonDisplayableInfo(includeSize: includeSize)
        }
    }

    func displayableDuration(includeSize: Bool = true) -> String {
        var informationLabelStr = duration > 0 ? displayableTimeLeft() : L10n.unknownDuration

        if includeSize, sizeInBytes > 0 {
            if informationLabelStr.count == 0 {
                informationLabelStr = SizeFormatter.shared.noDecimalFormat(bytes: sizeInBytes)
            } else {
                informationLabelStr += " • \(SizeFormatter.shared.noDecimalFormat(bytes: sizeInBytes))"
            }
        }

        return informationLabelStr
    }

    public func shouldArchiveOnCompletion() -> Bool {
        Settings.userEpisodeRemoveFileAfterPlaying() || Settings.userEpisodeRemoveFromCloudAfterPlaying()
    }

    func urlForImage(size: Int = 280) -> URL {
        if imageColor > 0 {
            #if !os(watchOS)
                return ServerHelper.userEpisodeDefaultImageUrl(isDark: Theme.isDarkTheme(), color: Int(imageColor), size: size)
            #else
                return ServerHelper.userEpisodeDefaultImageUrl(isDark: true, color: Int(imageColor), size: size)
            #endif
        }

        if let serverImageLocation = imageUrl, let serverURL = URL(string: serverImageLocation) {
            return serverURL
        }
        #if !os(watchOS)
            let path = pathToLocalImage()
            return URL(fileURLWithPath: path)
        #else
            return ServerHelper.userEpisodeDefaultImageUrl(isDark: true, color: 1, size: size)
        #endif
    }

    func pathToLocalImage() -> String {
        UploadManager.shared.customImageDirectory + "/" + uuid + ".jpg"
    }

    public func subTitle() -> String {
        uploadStatus == UploadStatus.missing.rawValue ? L10n.downloadErrorNotUploaded : L10n.customEpisode
    }
}
