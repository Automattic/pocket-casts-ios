fileprivate class Box<ResultType> {
    var result: ResultType? = nil
}

/// Unsafely awaits an async function from a synchronous context.
@available(*, deprecated, message: "Migrate to structured concurrency")
func _unsafeWait<T>(_ f: @escaping () async -> T) -> T {
    let box = Box<T>()
    let sema = DispatchSemaphore(value: 0)
    Task {
        let val = await f()
        box.result = val
        sema.signal()
    }
    sema.wait()
    return box.result!
}
