import Foundation
import UserNotifications
import WatchKit
import SwiftUI

struct NotificationView: View {

    var body: some View {
        Text("Message")
    }
}

class NotificationController: WKUserNotificationHostingController<NotificationView> {

    override var body: NotificationView {
        NotificationView()
    }
}
