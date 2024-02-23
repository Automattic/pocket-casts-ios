import SwiftUI
import PocketCastsUtils

struct BetaMenu: View {
    var body: some View {
        List {
            ForEach(FeatureFlag.allCases, id: \.self) { feature in
                Toggle(String(describing: feature), isOn: feature.isOn)
            }
        }
        .modifier(MiniPlayerPadding())
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
