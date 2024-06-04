import SwiftUI

@main
struct PocketCastsApp: App {

    @WKApplicationDelegateAdaptor var appDelegate: ExtensionDelegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                SourceInterfaceForm()
                    .navigationTitle("Play Source")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        // This is placeholder to replace the previous placeholder notification implemented on the
        // storyboard file. This is not actively used.
        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
