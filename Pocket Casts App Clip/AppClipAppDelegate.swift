import Foundation
import SwiftUI
import UserNotifications
import Firebase
import PocketCastsUtils
import PocketCastsServer

enum AppClipNotification {
    static let appStoreNotificationID = "au.com.shiftyjelly.podcasts.prototype.Clip.reminder"

    static let appAppStoreURL = "itms-apps://itunes.apple.com/app/apple-store/id414834813?mt=8"
}

class AppClipAppDelegate: NSObject, UIApplicationDelegate, ObservableObject {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // This is where we register this device to recieve push notifications from Apple
        // All this function does is register the device with APNs, it doesn't set up push notifications by itself
        application.registerForRemoteNotifications()

        configureFirebase()

        // Setting the notification delegate
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

    }

    private func configureFirebase() {
        FirebaseApp.configure()

        FirebaseManager.refreshRemoteConfig() { [weak self] status in
            self?.updateRemoteFeatureFlags()
            ServerConfig.avoidLogoutOnError = FeatureFlag.errorLogoutHandling.enabled
            ServerConfig.avoidLogoutInBackground = FeatureFlag.avoidLogoutInBackground.enabled
        }
    }

    private func updateRemoteFeatureFlags(forceReload: Bool = false) {
        guard BuildEnvironment.current != .debug || forceReload else { return }

        if FeatureFlag.errorLogoutHandling.enabled != Settings.errorLogoutHandling {
            ServerConfig.avoidLogoutOnError = FeatureFlag.errorLogoutHandling.enabled
            try? FeatureFlagOverrideStore().override(FeatureFlag.errorLogoutHandling, withValue: Settings.errorLogoutHandling)
        }

        try? FeatureFlagOverrideStore().override(FeatureFlag.slumber, withValue: Settings.slumberPromoCode?.isEmpty == false)

        FeatureFlag.allCases.forEach { flag in
            if let remoteKey = flag.remoteKey {
                let remoteValue = RemoteConfig.remoteConfig().configValue(forKey: remoteKey)
                if remoteValue.source == .remote {
                    do {
                        FileLog.shared.console("Override \(flag): \(remoteValue.boolValue)")
                        try FeatureFlagOverrideStore().override(flag, withValue: remoteValue.boolValue)
                    } catch {
                        FileLog.shared.addMessage("Failed to set remote feature flag \(flag): \(error)")
                    }
                }
            }
        }
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
