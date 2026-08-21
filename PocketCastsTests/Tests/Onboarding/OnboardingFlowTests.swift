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
}
