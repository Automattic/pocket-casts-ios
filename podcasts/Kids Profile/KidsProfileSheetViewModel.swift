import Foundation
import SwiftUI

class KidsProfileSheetViewModel: ObservableObject {
    @Published private(set) var currentScreen: SheetScreen = .thankYou

    @Published var textToSend = ""

    var onDismissScreenTap: (() -> Void)? = nil
    var onSendFeedbackTap: (() -> Void)? = nil

    func dismissScreen() {
        Analytics.track(.kidsProfileNoThankYouTapped)
        onDismissScreenTap?()
    }

    func sendFeedback() {
        Analytics.track(.kidsProfileSendFeedbackTapped)
        onSendFeedbackTap?()
        currentScreen = .submit
    }

    func submitFeedback() {
        // Send message in optimistic way
        Analytics.track(.kidsProfileFeedbackSent)
        Toast.show(L10n.kidsProfileSubmitSuccess)

        onDismissScreenTap?()
    }

    enum SheetScreen {
        case thankYou
        case submit
    }
}
