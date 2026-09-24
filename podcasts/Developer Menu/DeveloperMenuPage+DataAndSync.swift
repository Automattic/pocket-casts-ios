import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

extension DeveloperMenuPage {
    static var dataAndSync: DeveloperMenuPage {
        DeveloperMenuPage(title: "Data & Sync", systemImage: "externaldrive", sections: [
            DeveloperMenuSection(title: "Bundle", items: [
                .custom("Import Bundle") {
                    ImportBundleButton()
                },
                .custom("Export Bundle") {
                    ExportBundleButton()
                }
            ]),
            DeveloperMenuSection(title: "Refresh", items: [
                .action("Force Reload Discover") {
                    DiscoverServerHandler.shared.discoveryCache.removeAllCachedResponses()
                    URLSession.shared.configuration.urlCache?.removeAllCachedResponses()
                    NotificationCenter.postOnMainThread(notification: Constants.Notifications.chartRegionChanged)
                },
                .action("Force Reload Feature Flags") {
                    FirebaseManager.refreshRemoteConfig(expirationDuration: 0) { _ in
                        DispatchQueue.main.async {
                            (UIApplication.shared.delegate as? AppDelegate)?.updateRemoteFeatureFlags(forceReload: true)
                        }
                    }
                }
            ]),
            DeveloperMenuSection(title: "Danger Zone", items: [
                .destructive("Reset Database + Settings") {
                    PCBundleDoc.delete()
                },
                .destructive("Unsubscribe from All Podcasts") {
                    for podcast in DataManager.shared.allPodcasts(includeUnsubscribed: false) {
                        PodcastManager.shared.unsubscribe(podcast: podcast)
                    }
                },
                .destructive("Clear All Folder Information") {
                    DataManager.shared.clearAllFolderInformation()
                },
                .destructive("Corrupt Sync Login Token") {
                    ServerSettings.syncingV2Token = "badToken"
                }
            ])
        ])
    }
}

private struct ImportBundleButton: View {
    @State private var isPresented = false

    var body: some View {
        Button("Import Bundle") {
            isPresented = true
        }
        .fileImporter(isPresented: $isPresented, allowedContentTypes: [.pcasts]) { result in
            switch result {
            case .success(let url):
                print("Selected: \(url)")
                Task {
                    do {
                        let fileWrapper = try FileWrapper(url: url)
                        try PCBundleDoc.performImport(from: fileWrapper)
                    } catch {
                        print("Failed to import pcasts: \(error)")
                    }
                }
            case .failure(let error):
                print("Failed to import pcasts: \(error)")
            }
        }
    }
}

private struct ExportBundleButton: View {
    @State private var isPresented = false

    var body: some View {
        Button("Export Bundle") {
            isPresented = true
        }
        .fileExporter(isPresented: $isPresented, document: PCBundleDoc()) { result in
            switch result {
            case .success(let url):
                print("Saved to: \(url)")
            case .failure(let error):
                print("Failed to export pcasts: \(error)")
            }
        }
    }
}
