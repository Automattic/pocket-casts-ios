import FirebasePerformance
import Foundation
import PocketCastsUtils

class TraceHelper: TraceHandlingProtocol {
    func beginTracing(eventName: String) -> AnyObject? {
        Performance.startTrace(name: eventName)
    }

    func endTracing(trace: AnyObject) {
        guard let trace = trace as? Trace else { return }

        trace.stop()
    }
}
