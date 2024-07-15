import Foundation

public extension ApiServerHandler {
    func addRating(uuid: String, rating: Int) async -> Bool {
        return await withCheckedContinuation { continuation in
            let operation = UserPodcastRatingAddTask(uuid: uuid, rating: UInt32(rating))
            operation.completion = { success in
                continuation.resume(returning: success)
            }
            apiQueue.addOperation(operation)
        }
    }

    func getRating(uuid: String) async -> UserPodcastRating? {
        return await withCheckedContinuation { continuation in
            let operation = UserPodcastRatingGetTask(uuid: uuid)
            operation.completion = { success, userRating in
                continuation.resume(returning: userRating)
            }
            apiQueue.addOperation(operation)
        }
    }
}
