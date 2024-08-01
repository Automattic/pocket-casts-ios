import Foundation
import SwiftUI

class KidsProfileSheetViewModel: ObservableObject {
    @Published private(set) var currentScreen: SheetScreen = .thankYou

    @Published var textToSend = ""

    var onDismissScreenTap: (() -> Void)? = nil
    var onSendFeedbackTap: (() -> Void)? = nil

    func dismissScreen() {
        onDismissScreenTap?()
    }

    func sendFeedback() {
        onSendFeedbackTap?()
        currentScreen = .submit
    }

    func submitFeedback() {
        // Send message

        //If message sent succeded
        Toast.show(L10n.kidsProfileSubmitSuccess)

        //If message sent fail
//        Toast.show(L10n.serverErrorUnknown)

        dismissScreen()
    }

    enum SheetScreen {
        case thankYou
        case submit
    }
}
