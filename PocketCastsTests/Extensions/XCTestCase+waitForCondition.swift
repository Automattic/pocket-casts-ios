extension XCTestCase {
    /// Waits for the provided condition to become true, executing the check block until the timeout is reached.
    /// - Parameters:
    ///   - timeout: The maximum time to wait for the condition to become true.
    ///   - pollingInterval: The interval to wait between checks, in seconds.
    ///   - condition: A closure that returns a boolean value indicating whether the condition is met.
    func waitForCondition(
        timeout: TimeInterval,
        pollingInterval: TimeInterval = 0.5,
        condition: @escaping () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if condition() {
                return // Condition met, exit the function
            }
            try? await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000)) // Sleep for the polling interval
        }

        // If we reach here, the condition was not met in time
        XCTFail("Condition was not met in time.")
    }
}
