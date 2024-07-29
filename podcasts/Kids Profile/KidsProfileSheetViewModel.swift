import Foundation
import SwiftUI

class KidsProfileSheetViewModel: ObservableObject {
    @Published private(set) var currentScreen: SheetScreen = .thankYou

    var onDismissScreenTap: (() -> Void)? = nil
    var onSendFeedbackTap: (() -> Void)? = nil

    let transition: AnyTransition = .asymmetric(insertion: .slide, removal: .scale(scale: 0.7)).combined(with: .opacity)

    func dismissScreen() {
        onDismissScreenTap?()
    }

    func sendFeedback() {
        onSendFeedbackTap?()
        currentScreen = .submit
    }

    enum SheetScreen {
        case thankYou
        case submit
    }
}
