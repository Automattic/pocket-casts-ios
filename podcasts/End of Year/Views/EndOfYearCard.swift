import SwiftUI
import PocketCastsUtils

struct EndOfYearCard: View {
    @EnvironmentObject var theme: Theme

    let viewModel: ViewModel

    struct ViewModel {
        let title: String
        let description: String
        let imageName: String
        let imagePadding: CGFloat
        let backgroundColor: Color?
    }

    private var imageScale: Double {
        A11y.isDisplayZoomed ? 0.75 : 1.0
    }

    var body: some View {
        ZStack {
            HStack {
                VStack(alignment: .leading, spacing: Constants.textSpace) {
                    Text(viewModel.title)
                        .minimumScaleFactor(0.7)
                        .font(size: 18, style: .title2, weight: .semibold, maxSizeCategory: .extraExtraLarge)
                        .foregroundColor(.white)

                    Text(viewModel.description)
                        .font(size: 12, style: .footnote, weight: .semibold, maxSizeCategory: .accessibilityMedium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                }
                .padding(FeatureFlag.endOfYear2025.enabled ? 24 : 8)
                if FeatureFlag.endOfYear2025.enabled {
                    Spacer()
                    Rectangle()
                        .frame(width: 125, height: 1)
                        .opacity(0)
                } else {
                    Spacer()
                    Rectangle()
                        .frame(width: 150, height: 1)
                        .opacity(0)
                }
            }
            .background {
                if FeatureFlag.endOfYear2025.enabled {
                    VStack(alignment: .trailing) {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(viewModel.imageName)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                } else {
                    ZStack(alignment: .trailing) {
                        HStack {
                            Spacer()

                            Image(viewModel.imageName)
                                .padding(.trailing, viewModel.imagePadding)
                                .offset(x: 40)
                        }
                    }
                }
            }
            .background(viewModel.backgroundColor ?? ( theme.activeTheme.isDark ? Constants.darkThemeBackgroundColor : Constants.lightThemeBackgroundColor))
            .cornerRadius(Constants.cornerRadius)
        }
        .padding()
    }

    private struct Constants {
        static let textSpace: CGFloat = 8

        static let lightThemeBackgroundColor: Color = UIColor(hex: "#1A1A1A").color
        static let darkThemeBackgroundColor: Color = UIColor(hex: "#222222").color

        static let cornerRadius: CGFloat = 8
    }
}

#Preview("2024") {
    EndOfYearCard(viewModel: .init(title: "Playback 2024", description: "See your last 2024 playback", imageName: "23_small", imagePadding: 20, backgroundColor: nil))
        .environmentObject(Theme(previewTheme: .light))
}

#Preview("2025") {
    EndOfYearCard(viewModel: .init(title: L10n.playback2025FeatureTitle, description: L10n.playback2025FeatureDescription, imageName: "playback-25", imagePadding: 0, backgroundColor: Color(hex: "28486A")))
            .environmentObject(Theme(previewTheme: .light))
}
