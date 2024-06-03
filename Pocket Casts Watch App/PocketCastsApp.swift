import SwiftUI

@main
struct PocketCastsApp: App {
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
