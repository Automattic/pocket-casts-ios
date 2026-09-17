import Foundation

@MainActor
protocol OnboardingModel {
    func didAppear()
    func didDismiss(type: OnboardingDismissType)
}

enum OnboardingDismissType {
    case viewDisappearing
    case swipe
}
