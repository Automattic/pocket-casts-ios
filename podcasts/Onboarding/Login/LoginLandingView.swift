import SwiftUI
import PocketCastsServer

struct LoginLandingView: View {
    @EnvironmentObject var theme: Theme
    let coordinator: LoginCoordinator

    var body: some View {
        ProportionalValueFrameCalculator {
            LoginLandingContent(coordinator: coordinator)
        }
    }
}

private struct LoginLandingContent: View {
    @EnvironmentObject var theme: Theme
    @Environment(\.sizeCategory) var sizeCategory

    @ProportionalValue(with: .height) var calculatedHeaderHeightLarge: Double
    @ProportionalValue(with: .height) var calculatedHeaderHeightSmall: Double
    @ProportionalValue(with: .height) var deviceHeight = 1

    /// Determines if we should compact the view for smaller devices such as the iPhone SE / iPhone 12 Mini
    private var smallHeight: Bool { deviceHeight < 700 }

    /// Reduce the header height to allow the buttons to fit for larger size categories
    private var useSmallHeader: Bool {
        (smallHeight && sizeCategory > .extraLarge) || FeatureFlag.signInWithApple.enabled
    }

    let coordinator: LoginCoordinator

    init(coordinator: LoginCoordinator) {
        self.coordinator = coordinator

        // Find the value that will appear the lowest, and use that to calculate the
        // "total view height" since the actual view height doesn't account correctly
        calculatedHeaderHeightLarge = {
            let maxModel = largeHeaderModels.max {
                $0.y < $1.y
            }

            return maxModel?.y ?? 0
        }()

        // Calculate the header height for the small header too
        calculatedHeaderHeightSmall = {
            let maxModel = smallHeaderModels.max {
                $0.y < $1.y
            }

            return maxModel?.y ?? 0
        }()
    }

    // If the content will go offscreen
    // Show a gradient behind the content to make sure it's visible
    @State var showGradient: Bool? = nil

    /// The amount to reduce the top padding by to make sure the buttons are all visible
    @State var headerHeightOffset: CGFloat = 0

    var body: some View {
        let backgroundColor = AppTheme.color(for: .primaryUi01, theme: theme)
        let headerHeight = loginHeaderHeight - headerHeightOffset

        ZStack(alignment: .top) {
            GeometryReader { viewSizeProxy in
                LoginHeader(models: calculatedModels, topPadding: Config.padding)
                    .clipped()

                    VStack {
                        // Title and Subtitle
                        VStack(spacing: 8) {
                            LoginLabel(L10n.loginTitle, for: .title)
                            LoginLabel(L10n.loginSubtitle, for: .subtitle)
                        }

                        Spacer()

                        LoginButtons(coordinator: coordinator)
                    }
                    .padding([.leading, .trailing], Config.padding)
                    .padding(.top, headerHeight)
                    .padding(.bottom)
                    .background(
                        GeometryReader { contentSizeProxy in
                            let contentHeight = contentSizeProxy.size.height
                            let viewHeight = viewSizeProxy.size.height

                            Action {
                                // Only calculate the frame once
                                if showGradient == nil {
                                    // Show the gradient if the content is going to go off screen
                                    let willOverflow = contentHeight > viewHeight
                                    showGradient = willOverflow

                                    // Calculate how much the content will go offscreen so we can reduce the top
                                    // padding to ensure it's visible
                                    headerHeightOffset = willOverflow ? contentHeight - viewHeight : 0
                                }
                            }

                            if showGradient == true {
                                // Determine how much of the login header takes up of the height
                                // Then make sure the gradient stops there so the content is covered in a solid background
                                let headerPercentage = headerHeight / viewHeight

                                LinearGradient(gradient: Gradient(stops: [
                                    Gradient.Stop(color: backgroundColor.opacity(0.0), location: 0.0),
                                    Gradient.Stop(color: backgroundColor, location: headerPercentage),
                                ]), startPoint: .top, endPoint: .bottom)
                            }
                        }
                    )
            }
        }
        .background(backgroundColor.ignoresSafeArea())
    }

    private enum Config {
        static let padding: Double = 24
        static let topPadding: Double = 56
        static let topPaddingSmallDevice: Double = 35
    }

    // Smaller header image sizes for when there are more login options
    private var smallHeaderModels: [CoverModel] = [
        CoverModel(size: 0.26, x: -0.1973, y: 0.2606),
        CoverModel(size: 0.17, x: 0.2029, y: 0.3751),
        CoverModel(size: 0.16, x: 0.1349, y: 0.1626),
        CoverModel(size: 0.26, x: 0.2656, y: 0.2078),
        CoverModel(size: 0.16, x: 0.5869, y: 0.3600),
        CoverModel(size: 0.26, x: 0.8592, y: 0.2606),
        CoverModel(size: 0.26, x: 0.6468, y: 0.1626),
    ]

    // Smaller header image sizes for when there are less login options
    private var largeHeaderModels: [CoverModel] = [
        CoverModel(size: 0.38133333, x: -0.304, y: 0.31931669),
        CoverModel(size: 0.24, x: 0.2154, y: 0.47700394),
        CoverModel(size: 0.24, x: 0.127, y: 0.13396846),
        CoverModel(size: 0.38133333, x: 0.2966, y: 0.2457293),
        CoverModel(size: 0.24, x: 0.7135, y: 0.45729304),
        CoverModel(size: 0.38133333, x: 1.06, y: 0.31931669),
        CoverModel(size: 0.38133333, x: 0.7912, y: 0.18396846),
    ]

    /// Return the models to use in the header and allow them to be
    /// swapped out dynamically
    var calculatedModels: [CoverModel] {
        var models: [CoverModel]
        if useSmallHeader {
            models = smallHeaderModels
        } else {
            models = largeHeaderModels
        }

        // Map the models to images
        for i in 0..<models.count {
            models[i].image = coordinator.headerImages[i]
        }

        return models
    }

    var loginHeaderHeight: Double {
        let height = useSmallHeader ? calculatedHeaderHeightSmall : calculatedHeaderHeightLarge
        return height + (smallHeight ? Config.topPaddingSmallDevice : Config.topPadding)
    }

}

// MARK: - Models
private struct CoverModel: Identifiable {
    var image: LoginCoordinator.LoginHeaderImage? = nil
    let size: Double
    let x: Double
    let y: Double

    var id: String { image?.podcast?.uuid ?? image?.imageName ?? UUID().uuidString }
}

// MARK: - Internal Views
private struct LoginLabel: View {
    @EnvironmentObject var theme: Theme

    enum LabelStyle {
        case title
        case subtitle
    }

    let text: String
    let style: LabelStyle

    init(_ text: String, for style: LabelStyle) {
        self.text = text
        self.style = style
    }

    var body: some View {
        Text(text)
            .multilineTextAlignment(.center)
            .foregroundColor(AppTheme.color(for: textColor, theme: theme))
            .fixedSize(horizontal: false, vertical: true)
            .modifier(font)
    }

    private var font: LabelFont {
        LabelFont(labelStyle: style)
    }

    private var textColor: ThemeStyle {
        switch style {
        case .title:
            return .primaryText01
        case .subtitle:
            return .primaryText02
        }
    }

    private struct LabelFont: ViewModifier {
        let labelStyle: LabelStyle

        @ProportionalValue(with: .height) var deviceHeight = 1
        var smallHeight: Bool { deviceHeight < 600 }

        func body(content: Content) -> some View {
            switch labelStyle {
            case .title:
                return content.font(size: smallHeight ? 24 : 30, style: .title, weight: .bold, maxSizeCategory: .extraExtraLarge)
            case .subtitle:
                return content.font(size: smallHeight ? 16 : 18, style: .body, weight: .regular, maxSizeCategory: .extraExtraLarge)
            }
        }
    }
}

private struct LoginHeader: View {
    @StateObject var motion = MotionManager(options: .attitude)

    let models: [CoverModel]
    let topPadding: Double

    var body: some View {
        ZStack {
            ForEach(models) { model in
                LoginPodcastCover(model: model,
                                  topPadding: topPadding,
                                  manager: motion)
            }
        }.onDisappear() {
            motion.stop()
        }.onAppear() {
            motion.start()
        }

        .ignoresSafeArea()
    }
}

private struct LoginPodcastCover: View {
    @ProportionalValue(with: .width) var size: Double
    @ProportionalValue(with: .width) var x: Double
    @ProportionalValue(with: .height) var y: Double

    @ObservedObject var manager: MotionManager

    let model: CoverModel
    let topPadding: Double

    init(model: CoverModel, topPadding: Double, manager: MotionManager) {
        self.topPadding = topPadding
        self.manager = manager
        self.model = model
        self.size = model.size
        self.x = model.x
        self.y = model.y
    }

    private var offset: CGSize {
        let magnitude = size * Config.parallaxMagnitude

        let x = (size * 0.5) + manager.roll * magnitude
        let y = manager.pitch * magnitude

        return .init(width: x, height: y)
    }

    @State var isTapped: Bool = false

    @ViewBuilder
    var cover: some View {
        if let model = model.image, let podcast = model.podcast {
            LoginLandingCoverImage(podcastUuid: podcast.uuid,
                                   viewBackgroundStyle: .primaryUi01,
                                   placeholderImage: model.placeholderImageName)
        } else if let imageName = model.image?.imageName {
            PodcastCoverImage(imageName: imageName)
        } else {
            EmptyView()
        }
    }

    var body: some View {
        cover
            .frame(width: size, height: size)
            .position(x: x, y: y + topPadding)
            .offset(offset)
            .onTapGesture {
                isTapped.toggle()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isTapped.toggle()
                }
            }
            .applyButtonEffect(isPressed: isTapped)
    }

    private enum Config {
        /// How much parallax effect to give each cover based on its size
        static let parallaxMagnitude: Double = 0.1
    }
}

private struct LoginButtons: View {
    @EnvironmentObject var theme: Theme
    let coordinator: LoginCoordinator

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            SocialLoginButtons(coordinator: coordinator)

            Button("Sign Up") {
                coordinator.signUpTapped()
            }.buttonStyle(RoundedButtonStyle(theme: theme))

            Button("Login") {
                coordinator.loginTapped()
            }.buttonStyle(SimpleTextButtonStyle(theme: theme))
        }
    }
}

private struct SocialLoginButtons: View {
    @EnvironmentObject var theme: Theme
    let coordinator: LoginCoordinator

    var body: some View {
        if !FeatureFlag.signInWithApple.enabled {
            EmptyView()
        } else {
            ForEach(SocialAuthProvider.allCases, id: \.self) { provider in
                switch provider {
                case .apple:
                    Button(L10n.socialSignInContinueWithApple) {
                        coordinator.signIn(with: provider)
                    }.buttonStyle(SocialButtonStyle(imageName: AppTheme.socialIconAppleImageName()))
                case .google:
                    Button(L10n.socialSignInContinueWithGoogle) {
                        coordinator.signIn(with: provider)
                    }.buttonStyle(SocialButtonStyle(imageName: AppTheme.socialIconGoogleImageName()))
                }
            }
        }
    }
}
