import SwiftUI

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
    @ProportionalValue(with: .height) var calculatedHeight: Double
    @ProportionalValue(with: .height) var deviceHeight = 1
    private var smallHeight: Bool { deviceHeight < 600 }

    let coordinator: LoginCoordinator
    let models: [CoverModel]

    init(coordinator: LoginCoordinator) {
        self.coordinator = coordinator

        // Map the models to images
        var models = FeatureFlag.signInWithApple ? smallHeaderModels : largeHeaderModels
        for i in 0..<models.count {
            models[i].image = coordinator.headerImages[i]
         }

        self.models = models

        // Find the value that will appear the lowest, and use that to calculate the
        // "total view height" since the actual view height doesn't account correctly
        let maxModel = models.max {
            $0.y < $1.y
        }

        calculatedHeight = maxModel?.y ?? 0
    }

    var body: some View {
        ZStack(alignment: .top) {
            LoginHeader(models: models, topPadding: Config.padding)
                .clipped()

            VStack {
                // Title and Subtitle
                VStack(spacing: 8) {
                    LoginLabel("Discover your next favorite podcast", for: .title)
                    LoginLabel("Create an account to sync your listening experience across all your devices.", for: .subtitle)
                }

                Spacer()

                LoginButtons(coordinator: coordinator)
            }
            .padding([.leading, .trailing], Config.padding)
            .padding(.top, calculatedHeight + (smallHeight ? 30 : 56))
            .padding(.bottom)
        }.background(AppTheme.color(for: .primaryUi01, theme: theme).ignoresSafeArea())
    }

    private enum Config {
        static let padding: Double = 24
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
        if let podcast = model.image?.podcast {
            PodcastCover(podcastUuid: podcast.uuid, viewBackgroundStyle: .primaryUi01)
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
        if !FeatureFlag.signInWithApple {
            EmptyView()
        } else {
            Button("Continue with Apple") {
                coordinator.signInWithAppleTapped()
            }.buttonStyle(SocialButtonStyle(imageName: AppTheme.socialIconAppleImageName()))

            Button("Continue with Google") {
                coordinator.signInWithGoogleTapped()
            }.buttonStyle(SocialButtonStyle(imageName: AppTheme.socialIconGoogleImageName()))
        }
    }
}
