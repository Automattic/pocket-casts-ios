import Foundation

class AboutViewModel: ObservableObject {
    @Published var shouldShowWhatsNew: Bool = false
    @Published var whatsNewInfo: WhatsNewInfo?

    var whatsNewText: String {
        L10n.whatsNewInVersion(Settings.appVersion())
    }

    init() {
        whatsNewInfo = WhatsNewHelper.extractWhatsNewInfo()

        shouldShowWhatsNew = Settings.appVersion() == whatsNewInfo?.versionNo
    }
}
