import SwiftUI
import PocketCastsServer

struct DeveloperMenu: View {
    @State private var searchText = ""

    var body: some View {
        List {
            if searchText.isEmpty {
                ForEach(Array(DeveloperMenuSection.all.enumerated()), id: \.offset) { _, section in
                    DeveloperMenuSectionView(section: section)
                }
            } else {
                DeveloperMenuSearchResults(query: searchText)
            }
        }
        .searchable(text: $searchText, prompt: L10n.search)
        .scrollDismissesKeyboard(.immediately)
        .miniPlayerSafeAreaInset()
    }
}

extension DeveloperMenuSection {
    static var all: [DeveloperMenuSection] {
        [.data, .dangerZone, .subscription, .screens, .tipsAndPrompts, .notifications, .whatsNew, .playlists, .buildAndDevice]
    }

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
