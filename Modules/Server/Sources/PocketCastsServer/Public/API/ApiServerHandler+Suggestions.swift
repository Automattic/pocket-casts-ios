import Foundation

extension ApiServerHandler {
    public func suggestedFolders(for uuids: [String], language: String = Locale.current.languageCode ?? "en") async -> SuggestedFoldersResponse? {
        return await withCheckedContinuation { continuation in
            let operation = SuggestedFoldersTask(uuids: uuids, language: language) { response in
                continuation.resume(returning: response)
            }
            apiQueue.addOperation(operation)
        }
    }
}
