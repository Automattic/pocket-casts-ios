import SwiftUI

struct PlusAccountUpgradePrompt: View {
    @ObservedObject var viewModel: PlusAccountPromptViewModel
    let freeTrialDuration: String?

    init(viewModel: PlusAccountPromptViewModel) {
        self.viewModel = viewModel
        let firstProduct = viewModel.pricingInfo.products.first
        self.freeTrialDuration = firstProduct?.freeTrialDuration
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // PC + Plus icons
            HStack(alignment: .top, spacing: 12) {
                Image("plus-pc-icon-white")
                    .resizable()
                    .frame(width: 32, height: 32)
                Image("plus-icon-white")
                    .resizable()
                    .frame(width: 32, height: 32)
            }.padding(.bottom, 20)

            Label(L10n.accountDetailsPlusTitle, for: .title)

            if let freeTrialDuration {
                PlusFreeTrialLabel(freeTrialDuration, plan: .plus)
                    .padding(.top, 16)
            }

            let columns = [GridItem(.flexible()), GridItem(.flexible())]

            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                ForEach(features) { feature in
                    HStack {
                        Image(feature.iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16)

                        Label(feature.title, for: .featureName)
                    }
                }
            }.padding(.top, 20)

            Button(L10n.plusMarketingUpgradeButton) {
                viewModel.upgradeTapped()
            }.buttonStyle(PlusGradientFilledButtonStyle(isLoading: viewModel.priceAvailability == .loading, plan: .plus)).padding(.top, 30)
        }.padding().background (
            ProportionalValueFrameCalculator {
                PlusPromptBackgroundView()
            }
        )
    }

    private let features = [
        PlusMiniFeature(iconName: "plus-feature-desktop", title: L10n.plusMarketingDesktopAppsTitle),
        PlusMiniFeature(iconName: "plus-feature-watch", title: L10n.plusMarketingWatchPlaybackTitle),
        PlusMiniFeature(iconName: "plus-feature-cloud", title: L10n.plusCloudStorageLimitFormat(Constants.RemoteParams.customStorageLimitGBDefault.localized())),
        PlusMiniFeature(iconName: "plus-feature-folders", title: L10n.folders),
        PlusMiniFeature(iconName: "plus-feature-themes", title: L10n.plusMarketingThemesIconsTitle)
    ]
}

// MARK: - Model
private struct PlusMiniFeature: Identifiable, Hashable {
    let iconName: String
    let title: String

    var id: String { title }
}

// MARK: - Views
private struct Label: View {
    enum LabelStyle {
        case title
        case featureName
    }

    let text: String
    let labelStyle: LabelStyle

    init(_ text: String, for style: LabelStyle) {
        self.text = text
        self.labelStyle = style
    }

    var body: some View {
        Text(text)
            .fixedSize(horizontal: false, vertical: true)
            .modifier(LabelFont(labelStyle: labelStyle))
            .foregroundColor(.white)
    }

    private struct LabelFont: ViewModifier {
        let labelStyle: LabelStyle

        func body(content: Content) -> some View {
            switch labelStyle {
            case .title, .featureName:
                return content.font(style: .caption, weight: .semibold, maxSizeCategory: .extraExtraExtraLarge)
            }
        }
    }
}

private struct PlusPromptBackgroundView: View {
    @ProportionalValue(with: .width) var leftCircleSize = 0.936
    @ProportionalValue(with: .height) var leftCircleSizeHeight = 0.93597561
    @ProportionalValue(with: .width) var leftCircleX = -0.29315068
    @ProportionalValue(with: .height) var leftCircleY = -0.375

    @ProportionalValue(with: .width) var rightCircleSize = 0.8445122
    @ProportionalValue(with: .height) var rightCircleSizeHeight = 0.73780488
    @ProportionalValue(with: .width) var rightCircleX = 0.54133333
    @ProportionalValue(with: .height) var rightCircleY = -0.07317073

    var body: some View {
        ZStack {
            Color.plusBackgroundColor
            ZStack {
                // Right Circle
                Ellipse()
                    .foregroundColor(.plusRightCircleColor)
                    .frame(width: rightCircleSize, height: rightCircleSizeHeight)
                    .position(x: rightCircleX, y: rightCircleY)
                    .offset(x: rightCircleSize * 0.5, y: rightCircleSizeHeight * 0.5)
                    .blur(radius: 73)

                // Left Circle
                Ellipse()
                    .foregroundColor(.plusLeftCircleColor)
                    .frame(width: leftCircleSize, height: leftCircleSizeHeight)
                    .position(x: leftCircleX, y: leftCircleY)
                    .offset(x: leftCircleSize * 0.5, y: leftCircleSizeHeight * 0.5)
                    .blur(radius: 81)
            }.blur(radius: 16)

            // Overlay view
            Rectangle()
                .foregroundColor(.plusBackgroundColor)
                .opacity(0.28)
        }.ignoresSafeArea().clipped()
    }
}
