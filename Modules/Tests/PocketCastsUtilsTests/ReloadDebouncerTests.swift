import Testing
@testable import PocketCastsUtils

@MainActor
struct ReloadDebouncerTests {
    private struct Scope: OptionSet, Equatable {
        let rawValue: Int

        static let a = Scope(rawValue: 1 << 0)
        static let b = Scope(rawValue: 1 << 1)
    }

    @Test func singleRequestFiresAfterDebounce() async throws {
        var received: [Scope] = []
        let debouncer = ReloadDebouncer<Scope>(debounce: .zero) { received.append($0) }

        debouncer.request(.a)
        #expect(received == [], "Callback should not fire synchronously")

        await debouncer.waitForIdle()
        #expect(received == [.a])
    }

    @Test func burstCoalescesToUnionOfScopes() async throws {
        var received: [Scope] = []
        let debouncer = ReloadDebouncer<Scope>(debounce: .zero) { received.append($0) }

        debouncer.request(.a)
        debouncer.request(.b)
        debouncer.request(.a)

        await debouncer.waitForIdle()
        #expect(received == [[.a, .b]], "Burst of requests should flush once with the union of scopes")
    }

    @Test func pauseDefersFlushUntilResume() async throws {
        var received: [Scope] = []
        let debouncer = ReloadDebouncer<Scope>(debounce: .zero) { received.append($0) }

        debouncer.pause()
        debouncer.request(.a)

        await debouncer.waitForIdle()
        #expect(received == [], "Requests should not fire while paused")

        debouncer.resume()
        await debouncer.waitForIdle()
        #expect(received == [.a], "Pending request should flush after resume")
    }

    @Test func pauseWithDurationAutoResumes() async throws {
        var received: [Scope] = []
        let debouncer = ReloadDebouncer<Scope>(debounce: .zero) { received.append($0) }

        debouncer.request(.b)
        debouncer.pause(for: .zero)

        await debouncer.waitForIdle()
        #expect(received == [.b])
    }

    @Test func resumeWithNoPendingRequestsDoesNothing() async throws {
        var received: [Scope] = []
        let debouncer = ReloadDebouncer<Scope>(debounce: .zero) { received.append($0) }

        debouncer.pause()
        debouncer.resume()

        await debouncer.waitForIdle()
        #expect(received == [])
    }

    @Test func requestDuringPauseIsCoalescedWithLaterRequest() async throws {
        var received: [Scope] = []
        let debouncer = ReloadDebouncer<Scope>(debounce: .zero) { received.append($0) }

        debouncer.pause()
        debouncer.request(.a)
        debouncer.request(.b)
        debouncer.resume()

        await debouncer.waitForIdle()
        #expect(received == [[.a, .b]])
    }
}
