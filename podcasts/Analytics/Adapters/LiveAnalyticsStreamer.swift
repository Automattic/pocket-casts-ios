import Foundation
import PocketCastsServer
import PocketCastsUtils

private let allowedHost = "pocketcasts.com"

/// Streams analytics events to a remote debugging endpoint when enabled by the server.
///
/// This adapter buffers analytics events and sends them in batches to the configured
/// `liveAnalyticsUrl`. The URL is provided by the server via synced settings and can
/// be enabled/disabled remotely per user.
///
/// Buffering:
/// - Buffer capacity: 1000 events
/// - If buffer overflows, oldest events are dropped
///
/// Flush Strategy:
/// - When first event enters buffer: immediately trigger send
/// - Drain all buffered events into a batch
/// - Wait 500ms before sending next batch
///
/// Failure Handling:
/// - Fire and forget model - failures are logged but not retried
final class LiveAnalyticsStreamer: AnalyticsAdapter {
    private enum Config {
        static let maxBufferSize = 1000
        static let flushDelayMs: UInt64 = 500
        static let errorBackoffMs: UInt64 = 30_000
    }

    fileprivate struct AnalyticsEvent: Codable {
        let name: String
        let timestamp: String
        let properties: [String: String]?
        let platform: String
    }

    private let queue = DispatchQueue(label: "au.com.shiftyjelly.pocketcasts.liveanalytics")
    private var eventBuffer: [AnalyticsEvent] = []
    private var isFlushScheduled = false
    private var isBackingOff = false

    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        return encoder
    }()

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // MARK: - AnalyticsAdapter

    func track(name: String, properties: [AnyHashable: Any]?) {
        // Don't send if analytics are disabled
        guard !Settings.analyticsOptOut() else {
            return
        }

        let event = AnalyticsEvent(
            name: name,
            timestamp: dateFormatter.string(from: Date()),
            properties: properties?.reduce(into: [String: String]()) { result, entry in
                result[String(describing: entry.key)] = String(describing: entry.value)
            },
            platform: "iOS"
        )

        queue.async { [weak self] in
            self?.bufferEvent(event)
        }
    }
}

// MARK: - Private

private extension LiveAnalyticsStreamer {
    func bufferEvent(_ event: AnalyticsEvent) {
        // Drop oldest events if buffer is full
        if eventBuffer.count >= Config.maxBufferSize {
            let dropCount = eventBuffer.count - Config.maxBufferSize + 1
            eventBuffer.removeFirst(dropCount)
        }

        eventBuffer.append(event)

        // Schedule flush if not already scheduled
        if !isFlushScheduled {
            isFlushScheduled = true
            scheduleFlush()
        }
    }

    func scheduleFlush() {
        guard !isBackingOff else {
            isFlushScheduled = false
            return
        }

        // Immediately flush, then wait 500ms before next flush
        flush()

        queue.asyncAfter(deadline: .now() + .milliseconds(Int(Config.flushDelayMs))) { [weak self] in
            guard let self else { return }

            if self.eventBuffer.isEmpty {
                self.isFlushScheduled = false
            } else {
                self.scheduleFlush()
            }
        }
    }

    func flush() {
        guard !eventBuffer.isEmpty else { return }

        // Respect opt-out even if events were buffered before the user opted out
        if Settings.analyticsOptOut() {
            eventBuffer.removeAll()
            isFlushScheduled = false
            return
        }

        // Check for URL at flush time (allows dynamic enable/disable).
        // Stop the flush loop when no URL is configured; the next call to
        // bufferEvent() will restart it when a new event arrives.
        guard let urlString = ServerSettings.liveAnalyticsUrl,
              !urlString.isEmpty,
              let url = URL(string: urlString),
              isAllowedUrl(url) else {
            isFlushScheduled = false
            return
        }

        let events = eventBuffer
        eventBuffer.removeAll()

        send(events: events, to: url)
    }

    func startBackoff() {
        guard !isBackingOff else { return }
        isBackingOff = true

        queue.asyncAfter(deadline: .now() + .milliseconds(Int(Config.errorBackoffMs))) { [weak self] in
            guard let self else { return }
            self.isBackingOff = false

            if !self.eventBuffer.isEmpty, !self.isFlushScheduled {
                self.isFlushScheduled = true
                self.scheduleFlush()
            }
        }
    }

    /// In release builds, only allow HTTPS URLs on the Pocket Casts domain.
    func isAllowedUrl(_ url: URL) -> Bool {
        #if DEBUG || STAGING
        return true
        #else
        guard url.scheme == "https",
              let host = url.host?.lowercased() else {
            return false
        }
        return host == allowedHost || host.hasSuffix(".\(allowedHost)")
        #endif
    }

    func send(events: [AnalyticsEvent], to url: URL) {
        guard let data = try? encoder.encode(events) else {
            FileLog.shared.addMessage("LiveAnalyticsStreamer: Failed to encode event batch")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        // Fire and forget - no retry on failure, but back off on errors
        urlSession.dataTask(with: request) { [weak self] _, response, error in
            let failed: Bool
            if let error, (error as NSError).code != NSURLErrorCancelled {
                FileLog.shared.addMessage("LiveAnalyticsStreamer: Send failed - \(error.localizedDescription)")
                failed = true
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                FileLog.shared.addMessage("LiveAnalyticsStreamer: Send failed - HTTP \(httpResponse.statusCode)")
                failed = true
            } else {
                failed = false
            }

            if failed {
                self?.queue.async {
                    self?.startBackoff()
                }
            }
        }.resume()
    }
}
