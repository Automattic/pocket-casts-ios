import SwiftUI

@main
struct MyWatchApp: App {
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
