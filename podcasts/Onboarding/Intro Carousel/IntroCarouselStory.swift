import SwiftUI

struct IntroCarouselStory: StoryView {
    let item: CarouselItem
    let theme: Theme

    @State private var iconOpacity: Double = 0
    @State private var iconOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var descriptionOpacity: Double = 0
    @State private var descriptionOffset: CGFloat = 30

    var duration: TimeInterval { 7.0 }
    var identifier: String { item.title }
    var plusOnly: Bool { false }

    var body: some View {
        VStack {
            Spacer()

            AnyView(item.contentView())
                .opacity(iconOpacity)
                .offset(y: iconOffset)

            Spacer()

            VStack(spacing: 12) {
                Text(item.title)
                    .font(.system(size: 31, weight: .bold))
                    .foregroundColor(ThemeColor.primaryText01(for: theme.activeTheme).color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)

                Text(item.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(ThemeColor.primaryText02(for: theme.activeTheme).color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(descriptionOpacity)
                    .offset(y: descriptionOffset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.primaryUi01)
        .onAppear {
            startAnimations()
        }
        .id(identifier)
    }

    private func startAnimations() {
        // Reset to initial state
        iconOpacity = 0
        iconOffset = 30
        titleOpacity = 0
        titleOffset = 30
        descriptionOpacity = 0
        descriptionOffset = 30

        // Start sequential animations
        withAnimation(.easeOut(duration: 0.6)) {
            iconOpacity = 1
            iconOffset = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.6)) {
                titleOpacity = 1
                titleOffset = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.6)) {
                descriptionOpacity = 1
                descriptionOffset = 0
            }
        }
    }
}

#Preview {
    IntroCarouselStory(item:
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
                            title: "\"\(L10n.onboardingQuoteCustomization)\"",
                            description: L10n.onboardingQuoteAuthor
                        ), theme: Theme(previewTheme: .light))
}
