import SwiftUI

struct UpgradeFeaturesView: View {
    @EnvironmentObject var theme: Theme

    let features: [UpgradeTier.TierFeature]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(features, id: \.self) { feature in
                HStack(alignment: .center) {
                    Image(feature.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(theme.primaryText01)
                    UnderlineLinkTextView(feature.title)
                        .font(size: 15, style: .subheadline, weight: .medium)
                        .foregroundColor(theme.primaryText02)
                        .tint(theme.primaryText02)
                }
            }
        }
    }
}

#Preview {
    UpgradeFeaturesView(features: UpgradeTier.plus.yearlyFeatures).setupDefaultEnvironment()
}
