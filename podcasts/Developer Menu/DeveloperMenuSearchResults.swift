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
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                DeveloperMenuSectionView(section: section)
            }
        }
    }
}

private extension DeveloperMenuSection {
    static var searchable: [DeveloperMenuSection] {
        all + [.featureFlags]
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
        if title?.localizedCaseInsensitiveContains(query) == true {
            return self
        }
        let matches = items.compactMap { $0.filtered(by: query) }
        return matches.isEmpty ? nil : DeveloperMenuSection(title: title, footer: footer, items: matches)
    }
}

private extension DeveloperMenuItem {
    func filtered(by query: String) -> DeveloperMenuItem? {
        if title.localizedCaseInsensitiveContains(query) || subtitle?.localizedCaseInsensitiveContains(query) == true {
            return self
        }
        guard case .menu(let sections) = kind else {
            return nil
        }
        let matches = sections.compactMap { $0.filtered(by: query) }
        return matches.isEmpty ? nil : DeveloperMenuItem(title: title, subtitle: subtitle, kind: .menu(matches))
    }
}
