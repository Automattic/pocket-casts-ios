import SwiftUI

fileprivate extension String {
    func wrapInSmartQuotes() -> String {
        let leftSmartQuote = "\u{201C}"  // Left double quotation mark
        let rightSmartQuote = "\u{201D}" // Right double quotation mark
        return "\(leftSmartQuote)\(self)\(rightSmartQuote)"
    }
}

class IntroCarouselHostingController<Content>: OnboardingHostingViewController<Content> where Content: View {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }
}

struct IntroCarouselView: View {
    @EnvironmentObject var theme: Theme

    let coordinator: LoginCoordinator

    private let carouselItems = [
        CarouselItem(
            contentView: {
                VStack(spacing: 100) {
                    Image(AppTheme.pcLogoSmallHorizontalForBackgroundImageName())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 40)

                    Image("intro-carousel-podcasts")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            },
            title: L10n.onboardingQuoteBest.wrapInSmartQuotes(),
            description: L10n.onboardingQuoteAuthor
        ),
        CarouselItem(
            contentView: {
                Image("intro-carousel-effects")
                    .mask(
                        LinearGradient(
                            stops: [
                                Gradient.Stop(color: .clear, location: 0.0),
                                Gradient.Stop(color: .black, location: 0.1),
                                Gradient.Stop(color: .black, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            },
            title: L10n.onboardingQuoteCustomization.wrapInSmartQuotes(),
            description: L10n.onboardingQuoteAuthor
        ),
        CarouselItem(
            contentView: {
                Image("intro-carousel-folders")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            },
            title: L10n.onboardingQuoteFolders.wrapInSmartQuotes(),
            description: L10n.onboardingQuoteAuthor
        )
    ]

    private var configuration: StoriesConfiguration {
        let configuration = StoriesConfiguration()
        configuration.shouldShowDismissButton = false
        configuration.indicatorHeight = 4
        configuration.indicatorSpacing = 4
        return configuration
    }

    var body: some View {
        VStack(spacing: 36) {
            StoriesView(
                dataSource: IntroCarouselDataSource(items: carouselItems, theme: theme),
                configuration: configuration
            )

            VStack(spacing: 16) {
                Button(L10n.eacInformationalViewModalGetStartedButton) {
                    coordinator.getStartedTapped()
                }
                .buttonStyle(RoundedButtonStyle(theme: theme))

                Button(L10n.accountLogin) {
                    coordinator.loginTapped()
                }
                .foregroundColor(theme.primaryText01)
                .font(.system(size: 18, weight: .semibold))
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 10)
        }
        .modifier(DefaultThemeSettings())
    }
}

struct CarouselItem {
    let contentView: () -> any View
    let title: String
    let description: String
}
