import Testing
import PlaybackKit
import PocketCastsDataModel
import PocketCastsServer
@testable import podcasts

@Suite(.serialized)
struct Playback2026PayloadTests {
    @Test(arguments: Playback2026Archetype.allCases)
    func passesTheServersArchetypeAsThePagesID(_ archetype: Playback2026Archetype) {
        let payload = Playback2026Payload.make(year: 2026, archetype: archetype, dataManager: .newTestDataManager())

        #expect(payload.archetype?.rawValue == archetype.rawValue)
    }

    @Test func leavesTheArchetypeOutWhenTheServerHasNone() {
        let payload = Playback2026Payload.make(year: 2026, archetype: nil, dataManager: .newTestDataManager())

        #expect(payload.archetype == nil)
    }
}
