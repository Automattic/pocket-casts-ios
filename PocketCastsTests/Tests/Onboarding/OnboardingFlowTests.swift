import XCTest

@testable import podcasts

final class OnboardingFlowTests: XCTestCase {

    // MARK: - Notifications-permission prompt

    func testNotificationsPromptShownAfterAccountCreatedInAnyFlow() {
        // Account creation is what gates the prompt (email consent), regardless of the flow.
        for flow in [OnboardingFlow.Flow.encourageAccountCreation, .loggedOut, .initialOnboarding, .referralCode] {
            XCTAssertTrue(
                OnboardingFlow.shouldShowNotificationsPermissions(didCreateAccount: true, flow: flow),
                "Expected the notifications prompt after account creation in \(flow)"
            )
        }
    }

    func testNotificationsPromptShownForInitialOnboardingWithoutAccount() {
        // Initial onboarding keeps its first-run prompt even when no account is created.
        XCTAssertTrue(OnboardingFlow.shouldShowNotificationsPermissions(didCreateAccount: false, flow: .initialOnboarding))
    }

    func testNotificationsPromptNotShownWhenModalDismissedWithoutAccount() {
        // Dismissing the encourage-account-creation modal (or a plain login) without creating an
        // account must not chain into the notifications prompt.
        XCTAssertFalse(OnboardingFlow.shouldShowNotificationsPermissions(didCreateAccount: false, flow: .encourageAccountCreation))
        XCTAssertFalse(OnboardingFlow.shouldShowNotificationsPermissions(didCreateAccount: false, flow: .loggedOut))
    }

    // MARK: - didCreateAccount lifecycle

    // Exercise the flag through the mutating methods. `.loggedOut` avoids the clock's UserDefaults
    // write and the upsell controller's (unconfigured) Firebase lookup.

    func testResetClearsAccountCreatedFlag() {
        var flow = OnboardingFlow()
        _ = flow.begin(flow: .loggedOut, source: .unknown)
        flow.markAccountCreated()
        XCTAssertTrue(flow.didCreateAccount)
        flow.reset()
        XCTAssertFalse(flow.didCreateAccount, "A stale flag would show the notifications prompt after an unrelated flow")
    }

    func testBeginClearsStaleAccountCreatedFlag() {
        var flow = OnboardingFlow()
        _ = flow.begin(flow: .loggedOut, source: .unknown)
        flow.markAccountCreated()
        XCTAssertTrue(flow.didCreateAccount)
        // A new flow that never reached reset() must not inherit the previous flow's flag.
        _ = flow.begin(flow: .loggedOut, source: .unknown)
        XCTAssertFalse(flow.didCreateAccount, "begin() must scope didCreateAccount to a single flow")
    }
}
