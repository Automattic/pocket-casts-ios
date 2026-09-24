import SwiftUI
import PocketCastsServer

struct DeveloperMenu: View {
    var body: some View {
        List {
            DeveloperMenuSectionView(section: .buildAndDevice)

            Section {
                NavigationLink {
                    BetaMenu()
                        .navigationTitle("Feature Flags")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    Label("Feature Flags", systemImage: "flag")
                }
                ForEach(DeveloperMenuPage.all) { page in
                    NavigationLink {
                        DeveloperMenuPageView(page: page)
                    } label: {
                        Label(page.title, systemImage: page.systemImage)
                    }
                }
            }
        }
        .miniPlayerSafeAreaInset()
    }
}

extension DeveloperMenuPage {
    static var all: [DeveloperMenuPage] {
        [.subscription, .screens, .tipsAndPrompts, .notifications, .dataAndSync, .debugOptions]
    }
}

private extension DeveloperMenuSection {
    static var buildAndDevice: DeveloperMenuSection {
        DeveloperMenuSection(title: "Build & Device", footer: "Tap to copy.", items: [
            .value("Bundle ID", Bundle.main.bundleIdentifier),
            .value("Version", Bundle.main.versionAndBuild),
            .value("Device ID", ServerConfig.shared.syncDelegate?.uniqueAppId()),
            .value("Push Token", ServerSettings.pushToken()),
            .value("Account", ServerSettings.syncingEmail())
        ])
    }
}

struct DeveloperMenu_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DeveloperMenu()
        }
    }
}

private extension Bundle {
    var versionAndBuild: String? {
        guard let version = infoDictionary?["CFBundleShortVersionString"] as? String,
              let build = infoDictionary?["CFBundleVersion"] as? String else {
            return nil
        }
        return "\(version) (\(build))"
    }
}
