#if DEBUG
import Foundation
import ObjectiveC

/// Network faults for agent-driven QA, set by the `network:` launch hook fixture.
///
/// A fault applies to the HTTP and HTTPS requests of `URLSession.shared` and of sessions made from the
/// `.default` and `.ephemeral` configurations. Background sessions (episode downloads, uploads, background sync)
/// and streamed playback don't go through it.
enum QANetworkFault: Equatable {
    /// Every request fails as if the device were offline.
    case offline
    /// Every request gets an empty HTTP 500 response.
    case serverError
    /// Every request waits this many seconds, then completes normally.
    case slow(TimeInterval)

    private static let defaultsKey = "QALaunchHooksNetworkFault"
    private static var isInstalled = false

    /// The fault the next launches apply, if any.
    static var saved: QANetworkFault? {
        UserDefaults.standard.string(forKey: defaultsKey).flatMap(QANetworkFault.init)
    }

    /// The fault this process applies, if any.
    fileprivate(set) static var current: QANetworkFault?

    /// Parses `offline`, `server-error`, `slow` or `slow:<seconds>`.
    init?(_ argument: String) {
        let parts = argument.split(separator: ":", maxSplits: 1).map(String.init)
        switch parts[0] {
        case "offline":
            self = .offline
        case "server-error":
            self = .serverError
        case "slow":
            guard let seconds = parts.count > 1 ? TimeInterval(parts[1]) : 5, seconds > 0 else {
                return nil
            }
            self = .slow(seconds)
        default:
            return nil
        }
    }

    var argument: String {
        switch self {
        case .offline: "offline"
        case .serverError: "server-error"
        case .slow(let seconds): "slow:\(seconds)"
        }
    }

    /// Applies the fault from now on, in this process and on later launches, or ends it when `nil`.
    static func set(_ fault: QANetworkFault?) {
        if let fault {
            UserDefaults.standard.set(fault.argument, forKey: defaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: defaultsKey)
        }
        apply(fault)
    }

    static func apply(_ fault: QANetworkFault?) {
        current = fault
        if fault != nil && !isInstalled {
            isInstalled = true
            URLProtocol.registerClass(QANetworkFaultProtocol.self)
            URLSessionConfiguration.qa_insertFaultProtocol()
        }
    }
}

private final class QANetworkFaultProtocol: URLProtocol {
    private static let forwardedKey = "QANetworkFaultForwarded"
    private static let session = URLSession(configuration: .default)

    private var forwardedTask: URLSessionDataTask?
    private var isStopped = false

    override class func canInit(with request: URLRequest) -> Bool {
        guard QANetworkFault.current != nil, let scheme = request.url?.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return false
        }
        return URLProtocol.property(forKey: forwardedKey, in: request) == nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        switch QANetworkFault.current {
        case .offline:
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
        case .serverError:
            if let url = request.url, let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: "HTTP/1.1", headerFields: nil) {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            client?.urlProtocolDidFinishLoading(self)
        case .slow(let seconds):
            DispatchQueue.global().asyncAfter(deadline: .now() + seconds) { [weak self] in
                self?.forward()
            }
        case nil:
            forward()
        }
    }

    override func stopLoading() {
        isStopped = true
        forwardedTask?.cancel()
    }

    private func forward() {
        guard !isStopped, let forwarded = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return
        }
        URLProtocol.setProperty(true, forKey: Self.forwardedKey, in: forwarded)
        if forwarded.httpBody == nil, let stream = request.httpBodyStream {
            forwarded.httpBodyStream = nil
            forwarded.httpBody = Self.read(stream)
        }
        let task = Self.session.dataTask(with: forwarded as URLRequest) { [weak self] data, response, error in
            guard let self, !self.isStopped else {
                return
            }
            if let error {
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }
            if let response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            self.client?.urlProtocolDidFinishLoading(self)
        }
        forwardedTask = task
        task.resume()
    }

    private static func read(_ stream: InputStream) -> Data {
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 16_384)
        stream.open()
        defer { stream.close() }
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else {
                break
            }
            data.append(buffer, count: count)
        }
        return data
    }
}

private extension URLSessionConfiguration {
    static func qa_insertFaultProtocol() {
        for (original, replacement) in [
            (NSSelectorFromString("defaultSessionConfiguration"), #selector(qa_defaultSessionConfiguration)),
            (NSSelectorFromString("ephemeralSessionConfiguration"), #selector(qa_ephemeralSessionConfiguration))
        ] {
            guard let originalMethod = class_getClassMethod(URLSessionConfiguration.self, original),
                  let replacementMethod = class_getClassMethod(URLSessionConfiguration.self, replacement) else {
                continue
            }
            method_exchangeImplementations(originalMethod, replacementMethod)
        }
    }

    @objc class func qa_defaultSessionConfiguration() -> URLSessionConfiguration {
        withFaultProtocol(qa_defaultSessionConfiguration())
    }

    @objc class func qa_ephemeralSessionConfiguration() -> URLSessionConfiguration {
        withFaultProtocol(qa_ephemeralSessionConfiguration())
    }

    private static func withFaultProtocol(_ configuration: URLSessionConfiguration) -> URLSessionConfiguration {
        configuration.protocolClasses = [QANetworkFaultProtocol.self] + (configuration.protocolClasses ?? [])
        return configuration
    }
}
#endif
