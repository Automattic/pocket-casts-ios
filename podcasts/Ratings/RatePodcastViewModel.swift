import SwiftUI
import PocketCastsDataModel

class RatePodcastViewModel: ObservableObject {
    @Binding var presented: Bool

    @Published var userCanRate: UserCanRate = .checking

    @Published var isSubmitting: Bool = false

    @Published var showConfirmation: Bool = false

    @Published var anErrorOccurred: Bool = false

    @Published var stars: Double = 0 {
        didSet {
            if oldValue != stars {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    var podcast: Podcast

    var buttonLabel: String {
        userCanRate == .allowed ? L10n.supportSubmit : L10n.done
    }

    var isButtonEnabled: Bool {
        userCanRate != .allowed || userCanRate == .allowed && stars > 0
    }

    init(presented: Binding<Bool>, podcast: Podcast) {
        self._presented = presented
        self.podcast = podcast
        checkIfUserCanRate()
    }

    func buttonAction() {
        userCanRate == .allowed ? submit() : dismiss()
    }

    func submit() {
        isSubmitting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.isSubmitting = false
            self?.anErrorOccurred = true
        }
    }

    func dismiss() {
        presented = false
    }

    private func checkIfUserCanRate() {
        // Check through an API if the user can rate this podcast
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.userCanRate = .allowed
        }
    }

    enum UserCanRate {
        case checking
        case allowed
        case disallowed
    }
}
