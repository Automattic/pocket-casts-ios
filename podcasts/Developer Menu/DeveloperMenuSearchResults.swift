import SwiftUI
import PocketCastsUtils

struct DeveloperMenuSearchResults: View {
    let query: String

    var body: some View {
        let sections = DeveloperMenuSection.searchable.compactMap { $0.filtered(by: query) }
        if sections.isEmpty {
            ContentUnavailableView.search(text: query)
                .listRowBackground(Color.clear)
        } else {
            ForEach(sections, id: \.title) { section in
                DeveloperMenuSectionView(section: section)
            }
        }
    }
}

private extension DeveloperMenuSection {
    static var searchable: [DeveloperMenuSection] {
        let pages = DeveloperMenuPage.all.flatMap { page in
            page.sections.map { section in
                DeveloperMenuSection(title: [page.title, section.title].compactMap { $0 }.joined(separator: " › "), items: section.items)
            }
        }
        return [.buildAndDevice, .featureFlags] + pages
    }

    static var featureFlags: DeveloperMenuSection {
        DeveloperMenuSection(title: "Feature Flags", items: FeatureFlag.allCases.map { flag in
            .toggle(String(describing: flag), subtitle: flag.remoteKey, isOn: {
                flag.enabled
            }, set: { isOn in
                try? FeatureFlagOverrideStore().override(flag, withValue: isOn)
            })
        })
    }

    func filtered(by query: String) -> DeveloperMenuSection? {
        let matches = title?.localizedCaseInsensitiveContains(query) == true ? items : items.filter { $0.matches(query) }
        return matches.isEmpty ? nil : DeveloperMenuSection(title: title, items: matches)
    }
}

private extension DeveloperMenuItem {
    func matches(_ query: String) -> Bool {
        title.localizedCaseInsensitiveContains(query) || subtitle?.localizedCaseInsensitiveContains(query) == true
    }
}
