import PocketCastsDataModel

extension URLSession {
    func existingTask(for episode: BaseEpisode) async -> URLSessionTask? {
        let tasks = await allTasks
        return tasks.first(where: { $0.taskDescription == episode.downloadTaskId })
    }
}
