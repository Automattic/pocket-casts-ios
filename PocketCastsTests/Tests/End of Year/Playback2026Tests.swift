import Testing
@testable import podcasts

struct Playback2026Tests {
    @Test func signedOutUserSignsInFirst() {
        #expect(Playback2026.requiresSignIn(requireAccount: true, isSignedIn: false))
    }

    @Test(arguments: [(true, true), (false, false), (false, true)])
    func otherUsersOpenTheStories(requireAccount: Bool, isSignedIn: Bool) {
        #expect(!Playback2026.requiresSignIn(requireAccount: requireAccount, isSignedIn: isSignedIn))
    }
}
