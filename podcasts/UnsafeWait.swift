fileprivate class Box<ResultType> {
    var result: ResultType? = nil
    var error: Error? = nil
}

/// Unsafely awaits an async function from a synchronous context.
/// 
/// WARNING: This function should only be used as a last resort when migrating from
/// legacy synchronous code to async/await. It can cause deadlocks and performance issues.
/// 
/// - Parameter f: The async function to execute
/// - Returns: The result of the async function
/// - Throws: Any error thrown by the async function
@available(*, deprecated, message: "Migrate to structured concurrency")
func _unsafeWait<T>(_ f: @escaping () async throws -> T) throws -> T {
    let box = Box<T>()
    let sema = DispatchSemaphore(value: 0)
    
    Task {
        do {
            let val = try await f()
            box.result = val
        } catch {
            box.error = error
        }
        sema.signal()
    }
    
    // Add timeout to prevent infinite waiting
    let timeout = DispatchTime.now() + .seconds(30)
    let result = sema.wait(timeout: timeout)
    
    switch result {
    case .success:
        if let error = box.error {
            throw error
        }
        guard let result = box.result else {
            throw UnsafeWaitError.noResult
        }
        return result
    case .timedOut:
        throw UnsafeWaitError.timeout
    }
}

enum UnsafeWaitError: Error {
    case noResult
    case timeout
}
