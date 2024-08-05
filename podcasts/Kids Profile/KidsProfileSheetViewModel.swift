import Foundation
import SwiftUI
import PocketCastsServer

class KidsProfileSheetViewModel: ObservableObject {
    @Published private(set) var currentScreen: SheetScreen = .thankYou

    @Published var textToSend = ""

    var onDismissScreenTap: (() -> Void)? = nil
    var onSendFeedbackTap: (() -> Void)? = nil

    var canSendFeedback: Bool {
        !textToSend.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var buttonOpacity: Double {
        return canSendFeedback ? 1 : 0.8
    }

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
        Task { @MainActor [weak self] in
            guard let self else { return }

            if SyncManager.isUserLoggedIn() {
                await ApiServerHandler.shared.sendFeedback(message: textToSend)
            } else {
                await ApiServerHandler.shared.sendAnonymousFeedback(message: textToSend)
            }

            Analytics.track(.kidsProfileFeedbackSent)
            Toast.show(L10n.kidsProfileSubmitSuccess)

            onDismissScreenTap?()
        }
    }

    enum SheetScreen {
        case thankYou
        case submit
    }
}
