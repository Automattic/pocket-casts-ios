import XCTest
@testable import podcasts

/// Tests that `Analytics` normalizes event properties before handing them to adapters.
///
/// `AnalyticsDescribable` values must be replaced by their `analyticsDescription`,
/// and every value must reach the adapter unboxed. The previous implementation
/// (`(value as? AnalyticsDescribable)?.analyticsDescription ?? value`) selected the
/// `??` overload returning `T?`, which boxed every value into an `Optional`. Adapters
/// that serialize properties via `String(describing:)` then emitted `Optional("…")`
/// instead of the underlying value, so these assertions deliberately check the
/// `String(describing:)` form, which is what fails under the old implementation.
class AnalyticsTrackPropertiesTests: XCTestCase {

    private var analytics: Analytics!

    override func setUp() {
        super.setUp()
        analytics = Analytics.shared
        reset()
    }

    override func tearDown() {
        reset()
        super.tearDown()
    }

    private func reset() {
        Analytics.unregister()
        Settings.setAnalytics(optOut: false)
    }

    func testTrackNormalizesDescribableAndPlainProperties() {
        let adapter = CapturingAnalyticsAdapter()
        let didTrack = expectation(description: "adapter receives tracked event")
        adapter.onTrack = { didTrack.fulfill() }
        Analytics.register(adapters: [adapter])

        analytics.track(.applicationOpened, properties: [
            "describable": DescribableValue(),
            "plainString": "hello",
            "plainInt": 42
        ])

        wait(for: [didTrack], timeout: 1)

        let properties = try? XCTUnwrap(adapter.lastTrackedProperties)

        // Describable values are replaced by their description...
        XCTAssertEqual(properties?["describable"] as? String, DescribableValue.description)
        // ...and plain values pass through unchanged.
        XCTAssertEqual(properties?["plainString"] as? String, "hello")
        XCTAssertEqual(properties?["plainInt"] as? Int, 42)

        // Crucially, no value should be boxed into an Optional. Under the old
        // implementation each of these would describe as `Optional(…)`.
        XCTAssertEqual(describing(properties?["describable"]), DescribableValue.description)
        XCTAssertEqual(describing(properties?["plainString"]), "hello")
        XCTAssertEqual(describing(properties?["plainInt"]), "42")
    }

    private func describing(_ value: Sendable?) -> String? {
        value.map { String(describing: $0) }
    }
}

// MARK: - Test Helpers

private struct DescribableValue: AnalyticsDescribable {
    static let description = "DescribableValueDescription"
    var analyticsDescription: String { Self.description }
}

private final class CapturingAnalyticsAdapter: AnalyticsAdapter {
    var lastTrackedProperties: [String: Sendable]?
    var onTrack: (() -> Void)?

    func track(name: String, properties: [String: Sendable]) async {
        lastTrackedProperties = properties
        onTrack?()
    }
}
