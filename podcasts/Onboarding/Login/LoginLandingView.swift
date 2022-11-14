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
    let coordinator: LoginCoordinator
    @ProportionalValue(with: .height) var calculatedHeight: Double

    init(coordinator: LoginCoordinator) {
        self.coordinator = coordinator

        // Find the value that will appear the lowest, and use that to calculate the
        // "total view height" since the actual view height doesn't account correctly
        let maxModel = models.max {
            $0.y < $1.y
        }

        calculatedHeight = maxModel?.y ?? 0
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.color(for: .primaryUi01, theme: theme).ignoresSafeArea()
            LoginHeader(models: models, topPadding: Config.padding)

            ScrollViewIfNeeded {
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
                .padding(.top, calculatedHeight + (Config.padding * 2))
                .padding(.bottom)
            }
        }
    }

    // Cover Models 📸
    private let models: [CoverModel] = [
        CoverModel(imageName: "login-cover-1", size: 0.26, x: -0.1973, y: 0.2606),
        CoverModel(imageName: "login-cover-2", size: 0.17, x: 0.2029, y: 0.3751),
        CoverModel(imageName: "login-cover-3", size: 0.16, x: 0.1349, y: 0.1626),
        CoverModel(imageName: "login-cover-4", size: 0.26, x: 0.2656, y: 0.2078),
        CoverModel(imageName: "login-cover-5", size: 0.16, x: 0.5869, y: 0.3600),
        CoverModel(imageName: "login-cover-6", size: 0.26, x: 0.8592, y: 0.2606),
        CoverModel(imageName: "login-cover-7", size: 0.26, x: 0.6468, y: 0.1626),
    ]

    private enum Config {
        static let padding: Double = 24
    }
}

// MARK: - Models
private struct CoverModel: Identifiable {
    let imageName: String
    let size: Double
    let x: Double
    let y: Double

    var id: String { imageName }
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

        func body(content: Content) -> some View {
            switch labelStyle {
            case .title:
                return content.font(size: 30, style: .title, weight: .bold, maxSizeCategory: .extraExtraLarge)
            case .subtitle:
                return content.font(size: 18, style: .body, weight: .regular, maxSizeCategory: .extraExtraLarge)
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

    var body: some View {
        PodcastCoverImage(imageName: model.imageName)
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
            SocialLoginButtons(coordinator: coordinator)

            Button("Sign Up") {
                coordinator.signUpTapped()
            }.buttonStyle(RoundedButtonStyle(theme: theme))

            Button("Login") {
                coordinator.loginTapped()
            }.buttonStyle(SimpleTextButtonStyle(theme: theme))

            Action {
                print(theme.activeTheme)
            }
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

// MARK: - Preview
struct LoginLandingView_Previews: PreviewProvider {
    static var previews: some View {
        LoginLandingView(coordinator: LoginCoordinator())
            .preview(with: .contrastLight)
    }
}
