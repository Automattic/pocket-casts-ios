import CoreTransferable
import PocketCastsDataModel

@available(iOS 18.2, *)
extension EpisodeEntity: Transferable {
    static var transferRepresentation: some TransferRepresentation {
//        DataRepresentation(exportedContentType: .mp3) { episode in
//            guard let url = await DownloadManager.shared.download(episodeUuid: episode.id) else {
//                return Data()
//            }
//            return try Data(contentsOf: URL(string: url)!)
//        }
        DataRepresentation(exportedContentType: .text) { episode in
            var podcastID = episode.podcast?.id
            if podcastID == nil {
                podcastID = DataManager.sharedManager.findEpisode(uuid: episode.id)?.podcastUuid
            }
            guard let podcastID else { return Data() }
            let transcriptManager = TranscriptManager(episodeUUID: episode.id, podcastUUID: podcastID)
            let transcript = try await transcriptManager.loadTranscript()
            return transcript.attributedText.string.data(using: .utf8) ?? Data()
        }
    }
}
