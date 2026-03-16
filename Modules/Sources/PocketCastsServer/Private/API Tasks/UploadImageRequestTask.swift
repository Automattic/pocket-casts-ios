import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class UploadImageRequestTask: ApiBaseTask {
    var completion: ((URL?) -> Void)?
    private let episode: UserEpisode

    init(episode: UserEpisode) {
        self.episode = episode

        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "files/upload/image"

        let fileString = UploadManager.shared.customImageDirectory + "/" + episode.uuid + ".jpg"
        let fileURL = URL(fileURLWithPath: fileString)
        var fileSize = 0
        guard fileURL.isFileURL, FileManager.default.fileExists(atPath: fileURL.path) else {
            completion?(nil)

            return
        }
        do {
            let resources = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            fileSize = resources.fileSize ?? 0
        } catch {
            completion?(nil)
            return
        }

        do {
            var uploadRequest = Files_ImageUploadRequest()
            uploadRequest.uuid = episode.uuid
            uploadRequest.size = Int64(fileSize)
            uploadRequest.contentType = "image/jpeg"
            let data = try uploadRequest.serializedData()
            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            guard let responseData = response, httpStatus == ServerConstants.HttpConstants.ok else {
                FileLog.shared.addMessage("Upload image file request failed \(httpStatus)")
                completion?(nil)
                return
            }

            do {
                let uploadResponse = try Files_ImageUploadResponse(serializedData: responseData)
                FileLog.shared.addMessage("Upload image request response \(uploadResponse)")
                completion?(URL(string: uploadResponse.url))
                return
            } catch {
                FileLog.shared.addMessage("Upload image request response failed")
            }
        } catch {
            FileLog.shared.addMessage("UploadImageRequestTask: Protobuf Encoding failed \(error.localizedDescription)")
        }

        completion?(nil)
    }
}
