import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class UploadFileRequestTask: ApiBaseTask {
    var completion: ((URL?) -> Void)?
    private let episode: UserEpisode

    init(episode: UserEpisode) {
        self.episode = episode

        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "files/upload/request"
        do {
            var uploadRequest = Files_FileUploadRequest()
            uploadRequest.uuid = episode.uuid
            uploadRequest.title = episode.title ?? "No Title"
            uploadRequest.contentType = episode.fileType ?? "audio/mp3"
            uploadRequest.size = episode.sizeInBytes
            uploadRequest.duration = Int64(episode.duration)
            uploadRequest.colour = Google_Protobuf_Int32Value(episode.imageColor)
            uploadRequest.hasCustomImage_p = episode.hasCustomImage
            let data = try uploadRequest.serializedData()
            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            guard let responseData = response, httpStatus == ServerConstants.HttpConstants.ok else {
                FileLog.shared.addMessage("Upload file request failed \(httpStatus)")
                completion?(nil)
                return
            }

            do {
                let uploadResponse = try Files_FileUploadResponse(serializedData: responseData)
                FileLog.shared.addMessage("Upload request response \(uploadResponse)")
                completion?(URL(string: uploadResponse.url))
                return
            } catch {
                FileLog.shared.addMessage("Upload request response failed \(error.localizedDescription)")
            }
        } catch {
            print("Protobuf Encoding failed")
        }

        completion?(nil)
    }
}
