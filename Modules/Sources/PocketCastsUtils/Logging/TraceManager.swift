import Foundation

public class TraceManager {
    public static let shared = TraceManager()

    private var traceHandler: TraceHandlingProtocol?

    public func setup(handler: TraceHandlingProtocol) {
        traceHandler = handler
    }

    public func beginTracing(eventName: String) -> AnyObject? {
        traceHandler?.beginTracing(eventName: eventName)
    }

    public func endTracing(trace: AnyObject?) {
        guard let trace = trace else { return }

        traceHandler?.endTracing(trace: trace)
    }
}

public protocol TraceHandlingProtocol {
    func beginTracing(eventName: String) -> AnyObject?
    func endTracing(trace: AnyObject)
}
