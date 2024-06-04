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
    }
}
