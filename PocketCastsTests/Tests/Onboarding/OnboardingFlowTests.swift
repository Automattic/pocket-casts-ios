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

    // MARK: - Encourage Account Creation grace period

    func testClockStartsWhenInitialOnboardingFinishedWithoutAccount() {
        // Declining signup during initial onboarding starts the 60-day clock, so a fresh install
        // isn't prompted on the very next launch.
        XCTAssertTrue(OnboardingFlow.shouldStartEncourageAccountCreationClock(didCreateAccount: false, flow: .initialOnboarding))
    }

    func testClockNotStartedWhenAccountCreatedDuringOnboarding() {
        // Creating an account logs the user in, so there's nothing to anchor.
        XCTAssertFalse(OnboardingFlow.shouldStartEncourageAccountCreationClock(didCreateAccount: true, flow: .initialOnboarding))
    }

    func testClockNotStartedForOtherFlows() {
        // Other flows (e.g. an existing logged-out user opening the app) don't run initial
        // onboarding, so their clock stays unanchored and the modal shows on the first launch.
        XCTAssertFalse(OnboardingFlow.shouldStartEncourageAccountCreationClock(didCreateAccount: false, flow: .loggedOut))
        XCTAssertFalse(OnboardingFlow.shouldStartEncourageAccountCreationClock(didCreateAccount: false, flow: .encourageAccountCreation))
    }
}
