import DataModel
import Foundation
import SwiftProtobuf
import Utils

class UploadImageRequestTask: ApiBaseTask {
    var completion: ((URL?) -> Void)?
    private let episode: UserEpisode

    init(episode: UserEpisode) {
        self.episode = episode

        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = Server.Urls.api + "files/upload/image"

        let fileURL = episode.urlForImage()
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

            guard let responseData = response, httpStatus == Server.HttpConstants.ok else {
                FileLog.shared.addMessage("Upload image file request failed \(httpStatus)")
                completion?(nil)
                return
            }

            do {
                let uploadResponse = try Files_ImageUploadResponse(serializedData: responseData)
                FileLog.shared.addMessage("Upload image request response \(uploadResponse)")
                completion?(URL(string: uploadResponse.url))
            } catch {
                FileLog.shared.addMessage("Upload image request response failed")
            }
        } catch {
            print("Protobuf Encoding failed")
        }
    }
}
