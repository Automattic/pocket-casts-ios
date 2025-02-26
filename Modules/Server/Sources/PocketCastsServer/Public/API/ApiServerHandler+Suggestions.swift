import Foundation

extension ApiServerHandler {
    public func suggestedFolders(for uuids: [String]) async -> SuggestedFoldersResponse? {
        return await withCheckedContinuation { continuation in
            let operation = SuggestedFoldersTask(uuids: uuids) { response in
                continuation.resume(returning: response)
            }
            apiQueue.addOperation(operation)
        }
    }
}
