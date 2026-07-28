extension PCDBQueue {

    /// Asynchronously perform queries on an `PCDatabase` from a `PCDBQueue`
    /// The `inDatabase` call itself is a synchronous process but makes getting a return result harder due to the completion block. Using async you can retrieve the result in 1 line.
    ///
    /// Usage:
    ///
    ///     let result = await dbQueue.perform { try $0.executeQuery(...) }
    ///     switch result {
    ///         case .success:
    ///             print("Yay")
    ///         case .failure(let error):
    ///             print("Uh oh", error)
    ///
    func perform<T>(_ action: (PCDatabase) throws -> T) async -> Result<T, Error> {
        await withCheckedContinuation { continuation in
            write { db in
                do {
                    continuation.resume(returning: .success(try action(db)))
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }

    /// Helper async function perform `executeUpdate` from a database queue
    func executeUpdate(_ query: String, values: [Any]? = nil) async -> Result<Void, Error> {
        await perform { db in
            try db.executeUpdate(query, values: values)
        }
    }

    /// Helper async function perform `executeQuery` from a database queue
    func executeQuery(_ query: String, values: [Any]? = nil) async -> Result<PCDBResultSet, Error> {
        await perform { db in
            try db.executeQuery(query, values: values)
        }
    }
}
