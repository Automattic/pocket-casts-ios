import DataModel
import Foundation
import SwiftProtobuf
import Utils

class UploadFileRequestTask: ApiBaseTask {
    var completion: ((URL?) -> Void)?
    private let episode: UserEpisode

    init(episode: UserEpisode) {
        self.episode = episode

        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = Server.Urls.api + "files/upload/request"
        do {
            var uploadRequest = Files_FileUploadRequest()
            uploadRequest.uuid = episode.uuid
            uploadRequest.title = episode.title ?? "No Title"
            uploadRequest.contentType = episode.fileType ?? "audio/mp3" // TODO: do we need a default?
            uploadRequest.size = episode.sizeInBytes
            uploadRequest.duration = Int64(episode.duration)
            uploadRequest.colour = Google_Protobuf_Int32Value(episode.imageColor)
            uploadRequest.hasCustomImage_p = episode.hasCustomImage
            let data = try uploadRequest.serializedData()
            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            guard let responseData = response, httpStatus == Server.HttpConstants.ok else {
                FileLog.shared.addMessage("Upload file request failed \(httpStatus)")
                completion?(nil)
                return
            }

            do {
                let uploadResponse = try Files_FileUploadResponse(serializedData: responseData)
                FileLog.shared.addMessage("Upload request response \(uploadResponse)")
                completion?(URL(string: uploadResponse.url))
            } catch {
                FileLog.shared.addMessage("Upload request response failed")
            }
        } catch {
            print("Protobuf Encoding failed")
        }
    }
}
