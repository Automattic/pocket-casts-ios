import Testing
@testable import PocketCastsUtils

@MainActor
struct ReloadSchedulerTests {
    private struct Scope: OptionSet, Equatable {
        let rawValue: Int

        static let a = Scope(rawValue: 1 << 0)
        static let b = Scope(rawValue: 1 << 1)
    }

    @Test func singleRequestFiresAfterDebounce() async throws {
        var received: [Scope] = []
        let scheduler = ReloadScheduler<Scope>(interval: .zero) { received.append($0) }

        scheduler.request(.a)
        #expect(received == [], "Callback should not fire synchronously")

        await scheduler.waitForIdle()
        #expect(received == [.a])
    }

    @Test func burstCoalescesToUnionOfScopes() async throws {
        var received: [Scope] = []
        let scheduler = ReloadScheduler<Scope>(interval: .zero) { received.append($0) }

        scheduler.request(.a)
        scheduler.request(.b)
        scheduler.request(.a)

        await scheduler.waitForIdle()
        #expect(received == [[.a, .b]], "Burst of requests should flush once with the union of scopes")
    }

    @Test func pauseDefersFlushUntilResume() async throws {
        var received: [Scope] = []
        let scheduler = ReloadScheduler<Scope>(interval: .zero) { received.append($0) }

        scheduler.pause()
        scheduler.request(.a)

        await scheduler.waitForIdle()
        #expect(received == [], "Requests should not fire while paused")

        scheduler.resume()
        await scheduler.waitForIdle()
        #expect(received == [.a], "Pending request should flush after resume")
    }

    @Test func pauseWithDurationAutoResumes() async throws {
        var received: [Scope] = []
        let scheduler = ReloadScheduler<Scope>(interval: .zero) { received.append($0) }

        scheduler.request(.b)
        scheduler.pause(for: .zero)

        await scheduler.waitForIdle()
        #expect(received == [.b])
    }

    @Test func resumeWithNoPendingRequestsDoesNothing() async throws {
        var received: [Scope] = []
        let scheduler = ReloadScheduler<Scope>(interval: .zero) { received.append($0) }

        scheduler.pause()
        scheduler.resume()

        await scheduler.waitForIdle()
        #expect(received == [])
    }

    @Test func requestDuringPauseIsCoalescedWithLaterRequest() async throws {
        var received: [Scope] = []
        let scheduler = ReloadScheduler<Scope>(interval: .zero) { received.append($0) }

        scheduler.pause()
        scheduler.request(.a)
        scheduler.request(.b)
        scheduler.resume()

        await scheduler.waitForIdle()
        #expect(received == [[.a, .b]])
    }
}
