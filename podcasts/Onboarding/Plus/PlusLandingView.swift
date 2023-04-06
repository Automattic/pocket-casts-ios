import SwiftUI

struct PlusLandingView: View {
    @ObservedObject var viewModel: PlusLandingViewModel
    @Environment(\.accessibilityShowButtonShapes) var showButtonShapes: Bool
    @State var calculatedCardHeight: CGFloat?

    var body: some View {
        ZStack {
            PlusBackgroundGradientView()

            ScrollViewIfNeeded {
                VStack(alignment: .leading) {
                    HStack(alignment: .top, spacing: 12) {
                        Image("plus-pc-icon-white")
                        Image("plus-icon-white")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        PlusLabel(L10n.plusMarketingTitle, for: .title)
                        PlusLabel(L10n.plusMarketingSubtitle, for: .subtitle)
                    }.padding(.top, 24)

                    // Plus Features - Center between the text and the buttons
                    Spacer()

                    // Store the calculated card heights
                    var cardHeights: [CGFloat] = []

                    HorizontalScrollView {
                        ForEach(features) { model in
                            CardView(model: model, isLast: (model == features.last))
                                .overlay(
                                    // Calculate the height of the card after it's been laid out
                                    GeometryReader { proxy in
                                        Action {
                                            // Add the calculated height to the array
                                            cardHeights.append(proxy.size.height)

                                            // Determine the max height only once we've calculated all the heights
                                            if cardHeights.count == features.count {
                                                calculatedCardHeight = cardHeights.max()

                                                // Reset the card heights so any view changes won't use old data
                                                cardHeights = []
                                            }
                                        }
                                    }
                                )
                        }
                    }
                    .frame(height: calculatedCardHeight)
                    .padding(ViewConfig.padding.features)

                    Spacer()

                    // Buttons
                    VStack(alignment: .leading, spacing: 16) {
                        Button(L10n.plusButtonTitleUnlockAll) {
                            viewModel.unlockTapped()
                        }.buttonStyle(PlusGradientFilledButtonStyle(isLoading: viewModel.priceAvailability == .loading))

                        Button(L10n.eoyNotNow) {
                            viewModel.dismissTapped()
                        }.buttonStyle(PlusGradientStrokeButton())
                    }
                }
                .padding(ViewConfig.padding.viewReducedTop)
                .padding(.bottom)
            }
        }.enableProportionalValueScaling().ignoresSafeArea()
    }

    // Static list of the feature models to display
    private let features = [
        PlusFeature(iconName: "plus-feature-desktop",
                    title: L10n.plusMarketingDesktopAppsTitle,
                    description: L10n.plusMarketingUpdatedDesktopAppsDescription),
        PlusFeature(iconName: "plus-feature-folders",
                    title: L10n.folders,
                    description: L10n.plusMarketingUpdatedFoldersDescription),
        PlusFeature(iconName: "plus-feature-cloud",
                    title: L10n.plusCloudStorageLimitFormat(Constants.RemoteParams.customStorageLimitGBDefault.localized()),
                    description: L10n.plusMarketingUpdatedCloudStorageDescription),
        PlusFeature(iconName: "plus-feature-watch",
                    title: L10n.plusMarketingWatchPlaybackTitle,
                    description: L10n.plusMarketingWatchPlaybackDescription),
        PlusFeature(iconName: "plus-feature-themes",
                    title: L10n.plusMarketingThemesIconsTitle,
                    description: L10n.plusMarketingThemesIconsDescription)
    ]
}

// MARK: - Config
private extension Color {
    static let textColor = Color.white

    // Feature Cards
    static let cardGradient = LinearGradient(colors: [Color(hex: "2A2A2B"), Color(hex: "252525")],
                                             startPoint: .top, endPoint: .bottom)
    static let cardStroke = Color(hex: "383839")
}

private enum ViewConfig {
    struct padding {
        static let horizontal = 20.0

        static let view = EdgeInsets(top: 70,
                                     leading: Self.horizontal,
                                     bottom: 20,
                                     trailing: Self.horizontal)

        static let viewReducedTop = EdgeInsets(top: 44,
                                     leading: Self.horizontal,
                                     bottom: 20,
                                     trailing: Self.horizontal)

        // This resets the total view padding to allow the scrollview to go fully to the edges
        static let features = EdgeInsets(top: 36,
                                         leading: -Self.horizontal,
                                         bottom: 36,
                                         trailing: -Self.horizontal)

        static let featureCardMargin: Double = 15.0
    }

    static let horizontalPadding = 20.0
    static let cardWidth = 155.0
}

// MARK: - Model
private struct PlusFeature: Identifiable, Equatable {
    let iconName: String
    let title: String
    let description: String
    var id: String { title }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

// MARK: - Internal Views
struct PlusLabel: View {
    enum PlusLabelStyle {
        case title
        case title2
        case subtitle
        case featureTitle
        case featureDescription
    }

    let text: String
    let labelStyle: PlusLabelStyle

    init(_ text: String, for style: PlusLabelStyle) {
        self.text = text
        self.labelStyle = style
    }

    var body: some View {
        Text(text)
            .foregroundColor(Color.textColor)
            .fixedSize(horizontal: false, vertical: true)
            .modifier(LabelFont(labelStyle: labelStyle))
    }

    private struct LabelFont: ViewModifier {
        let labelStyle: PlusLabelStyle

        func body(content: Content) -> some View {
            switch labelStyle {
            case .title:
                return content.font(size: 30, style: .title, weight: .bold, maxSizeCategory: .extraExtraLarge)
            case .title2:
                return content.font(style: .title2, weight: .bold, maxSizeCategory: .extraExtraLarge)
            case .subtitle:
                return content.font(size: 18, style: .body, weight: .regular, maxSizeCategory: .extraExtraLarge)
            case .featureTitle:
                return content.font(style: .footnote, maxSizeCategory: .extraExtraLarge)
            case .featureDescription:
                return content.font(style: .footnote, maxSizeCategory: .extraExtraLarge)
            }
        }
    }
}

private struct PlusBackgroundGradientView: View {
    @ProportionalValue(with: .width) var leftCircleSize = 0.836
    @ProportionalValue(with: .width) var leftCircleX = -0.28533333
    @ProportionalValue(with: .height) var leftCircleY = -0.10810811

    @ProportionalValue(with: .width) var rightCircleSize = 0.63866667
    @ProportionalValue(with: .width) var rightCircleX = 0.54133333
    @ProportionalValue(with: .height) var rightCircleY = -0.03316953

    var body: some View {
        ZStack {
            Color.plusBackgroundColor
            ZStack {
                // Right Circle
                Circle()
                    .foregroundColor(.plusRightCircleColor)
                    .frame(height: rightCircleSize)
                    .position(x: rightCircleX, y: rightCircleY)
                    .offset(x: rightCircleSize * 0.5, y: rightCircleSize * 0.5)

                // Left Circle
                Circle()
                    .foregroundColor(.plusLeftCircleColor)
                    .frame(height: leftCircleSize)
                    .position(x: leftCircleX, y: leftCircleY)
                    .offset(x: leftCircleSize * 0.5, y: leftCircleSize * 0.5)
            }.blur(radius: 100)

            // Overlay view
            Rectangle()
                .foregroundColor(.plusBackgroundColor)
                .opacity(0.28)
        }.ignoresSafeArea().clipped()
    }
}

private struct CardView: View {
    let model: PlusFeature
    let isLast: Bool

    var body: some View {
        ZStack {
            BackgroundView()
            VStack(alignment: .leading, spacing: 5) {
                Image(model.iconName)
                PlusLabel(model.title, for: .featureTitle)
                    .padding(.top, 10)

                PlusLabel(model.description, for: .featureDescription)
                    .opacity(0.72)
                Spacer()
            }
            .padding(.top, 20)
            .padding([.leading, .trailing], ViewConfig.padding.featureCardMargin)
        }
        .frame(width: ViewConfig.cardWidth)
        .padding(.leading, ViewConfig.padding.featureCardMargin)
        .padding(.trailing, isLast ? ViewConfig.padding.featureCardMargin : 0)
    }

    struct BackgroundView: View {
        func backgroundView() -> RoundedRectangle {
            RoundedRectangle(cornerRadius: 12.0)
        }

        var body: some View {
            backgroundView().fill(Color.cardGradient).overlay(
                backgroundView().stroke(Color.cardStroke, lineWidth: 1)
            )
        }
    }
}

private struct CloseButtonStyle: ButtonStyle {
    let showButtonShapes: Bool

    func makeBody(configuration: Configuration) -> some View {
        Image(systemName: "xmark")
            .font(style: .title3, weight: .bold, maxSizeCategory: .extraExtraLarge)
            .foregroundColor(.white)
            .padding(Constants.closeButtonPadding)
            .background(showButtonShapes ? Color.white.opacity(0.2) : nil)
            .cornerRadius(Constants.closeButtonRadius)
            .contentShape(Rectangle())
            .applyButtonEffect(isPressed: configuration.isPressed)
    }

    private enum Constants {
        static let closeButtonPadding: CGFloat = 13
        static let closeButtonRadius: CGFloat = 5
    }
}
