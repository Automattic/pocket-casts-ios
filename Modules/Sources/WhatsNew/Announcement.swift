import PocketCastsServer
import SwiftUI

/// Caseless-enum namespace so consumers can write `WhatsNew.Announcement`
/// even though the SPM module is also named `WhatsNew`.
public enum WhatsNew {
    public struct Announcement {
        public let version: String
        public let header: () -> AnyView
        public let title: String
        public let message: String
        public let buttonTitle: String
        public let action: () -> Void
        public let displayTier: SubscriptionTier
        public let isEnabled: () -> Bool
        public let fullModal: Bool
        public let customBody: () -> AnyView?

        public init(version: String,
                    header: @autoclosure @escaping () -> AnyView,
                    title: String, message: String,
                    buttonTitle: String,
                    action: @escaping () -> Void,
                    displayTier: SubscriptionTier = .none,
                    isEnabled: @autoclosure @escaping () -> Bool,
                    fullModal: Bool = false,
                    customBody: @autoclosure @escaping () -> AnyView? = nil) {
            self.version = version
            self.header = header
            self.title = title
            self.message = message
            self.buttonTitle = buttonTitle
            self.action = action
            self.displayTier = displayTier
            self.isEnabled = isEnabled
            self.fullModal = fullModal
            self.customBody = customBody
        }
    }
}
