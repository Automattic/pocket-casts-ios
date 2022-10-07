import Foundation
import PocketCastsDataModel

public class MetadataUpdater {
    public static let shared = MetadataUpdater()

    private let operationQueue = OperationQueue()

    public init() {
        operationQueue.maxConcurrentOperationCount = 2
    }

    public func updatedMetadata(episodeUuid: String?) {
        guard let uuid = episodeUuid else { return }

        // if this episode is already in the queue, ignore it
        if let _ = taskFor(episodeUuid: uuid) { return }

        let metadataTask = MetadataTask()
        metadataTask.episodeUuid = uuid
        operationQueue.addOperation(metadataTask)
    }

    public func updateMetadataFrom(response: HTTPURLResponse?, episode: Episode?) {
        guard let episode = episode, let response = response else { return }

        MetadataTask.updateEpisodeFrom(response: response, episode: episode)
    }

    private func taskFor(episodeUuid: String) -> MetadataTask? {
        if operationQueue.operationCount == 0 { return nil }

        for case let task as MetadataTask in operationQueue.operations {
            if task.episodeUuid == episodeUuid {
                return task
            }
        }

        return nil
    }
}
