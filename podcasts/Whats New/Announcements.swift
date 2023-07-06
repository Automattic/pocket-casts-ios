import Foundation

struct Announcements {
    // Order is important.
    // In the case a user migrates to, let's say, 7.10 to 7.15 and
    // there were two announcements, the last one will be picked.
    var announcements: [WhatsNew.Announcement] = [
        .init(
            version: 7.80,
            image: "",
            title: "",
            message: ""
        )
    ]
}
