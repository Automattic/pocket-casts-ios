import Foundation
import SwiftUI
import UserNotifications

enum AppClipNotification {
    static let appStoreNotificationID = "au.com.shiftyjelly.podcasts.prototype.Clip.reminder"

    static let appAppStoreURL = "itms-apps://itunes.apple.com/app/apple-store/id414834813?mt=8"
}

class AppClipAppDelegate: NSObject, UIApplicationDelegate, ObservableObject {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // This is where we register this device to recieve push notifications from Apple
        // All this function does is register the device with APNs, it doesn't set up push notifications by itself
        application.registerForRemoteNotifications()

        // Setting the notification delegate
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

    }
}

extension AppClipAppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard response.notification.request.identifier == AppClipNotification.appStoreNotificationID else {
            return
        }
        guard let url = URL(string: AppClipNotification.appAppStoreURL) else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    // This function allows us to view notifications in the app even with it in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.badge, .banner, .list, .sound]
    }
}
