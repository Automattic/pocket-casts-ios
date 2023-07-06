import Foundation
import SwiftUI

struct Announcements {
    // Order is important.
    // In the case a user migrates to, let's say, 7.10 to 7.15 and
    // there were two announcements, the last one will be picked.
    var announcements: [WhatsNew.Announcement] = [
        .init(
            version: 7.43,
            header: {
                AnyView(AutoplayWhatsNewHeader())
            },
            title: L10n.announcementAutoplayTitle,
            message: L10n.announcementAutoplayDescription,
            buttonTitle: L10n.enableIt,
            action: {
                AnnouncementFlow.shared.isShowingAutoplayOption = true

                NavigationManager.sharedManager.navigateTo(NavigationManager.settingsProfileKey, data: nil)
            }
        )
    ]
}

class AnnouncementFlow {
    static let shared = AnnouncementFlow()

    var isShowingAutoplayOption = false
}
