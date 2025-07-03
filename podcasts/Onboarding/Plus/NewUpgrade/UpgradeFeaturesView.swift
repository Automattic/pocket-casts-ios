import SwiftUI

struct UpgradeFeaturesView: View {

    let features: [UpgradeTier.TierFeature]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(features, id: \.self) { feature in
                HStack(alignment: .center) {
                    Image(feature.iconName)
                        .resizable()
                        .font(.title)
                        .frame(width: 16, height: 16)
                    Text(feature.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
    }
}
