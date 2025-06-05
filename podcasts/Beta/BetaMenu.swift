import SwiftUI
import PocketCastsUtils

struct BetaMenu: View {
    @State private var searchText = ""

    var body: some View {
        List {
            ForEach(filteredFeatures, id: \.self) { feature in
                Toggle(isOn: feature.isOn) {
                    VStack(alignment: .leading) {
                        Text(String(describing: feature))
                        Text(feature.remoteKey ?? "No Key")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
                .onTapGesture { }
                .onLongPressGesture(minimumDuration: 0.2) {
                    if let key = feature.remoteKey {
                        UIPasteboard.general.setValue(key,
                                    forPasteboardType: UTType.plainText.identifier)
                        Toast.show("Key \(key) copied!")
                    } else {
                        Toast.show("No key available")
                    }
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: L10n.search)
        .miniPlayerSafeAreaInset()
    }

    private var filteredFeatures: [FeatureFlag] {
        if searchText.isEmpty {
            FeatureFlag.allCases
        } else {
            FeatureFlag.allCases.filter { feature in
                String(describing: feature).localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

private extension FeatureFlag {
    var isOn: Binding<Bool> {
        return Binding<Bool>(
            get: {
                return enabled
            },
            set: { enabled in
                try? FeatureFlagOverrideStore().override(self, withValue: enabled)
            }
        )
    }
}

struct BetaMenu_Previews: PreviewProvider {
    static var previews: some View {
        BetaMenu()
    }
}
