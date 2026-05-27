import Foundation

/// Serial execution context for analytics work.
///
/// Adapters that buffer or batch events isolate their mutable state to this
/// actor instead of managing their own dispatch queues.
@globalActor
actor AnalyticsActor {
    static let shared = AnalyticsActor()
}
