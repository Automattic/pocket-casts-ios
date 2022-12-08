import SwiftUI

struct BetaMenu: View {
    @State var enabled = true
    var body: some View {
        List {
            ForEach(FeatureFlag.allCases, id: \.self) { feature in
                Toggle(feature.rawValue, isOn: isEnabled(feature))
            }
        }
    }

    func isEnabled(_ featureFlag: FeatureFlag) -> Binding<Bool> {
        return Binding<Bool>(
            get: {
                return featureFlag.isEnabled
            },
            set: { enabled in
                try? FeatureFlagOverrideStore().override(featureFlag, withValue: enabled)
            })
    }
}

struct BetaMenu_Previews: PreviewProvider {
    static var previews: some View {
        BetaMenu()
    }
}
