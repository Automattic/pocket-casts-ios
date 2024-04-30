import PocketCastsServer
import PocketCastsUtils
import SwiftUI

/// A view that displays information about the user on the profile view
struct ProfileHeaderView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: ProfileHeaderViewModel

    /// Update the UI depending on the size of the screen
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isShowingVertically: Bool {
        sizeClass == .compact
    }

    var body: some View {
        container { geometryProxy in
            if viewModel.shouldShowProfileInfo {
                profileImage(geometryProxy)
            }
            profileInfo()
            stats()
        }
    }

    // MARK: - Private: Views

    /// Shows the profile image with subscription information
    @ViewBuilder
    private func profileImage(_ proxy: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            SubscriptionProfileImage(viewModel: viewModel)
                .frame(width: Constants.imageSize, height: Constants.imageSize)

            // Show the patron badge
            if let subscription = viewModel.subscription {
                if subscription.tier == .patron {
                    SubscriptionBadge(tier: subscription.tier)
                        .padding(.top, -10)
                }

                // Display the expiration date if needed
                if subscription.expirationProgress < 1, let expirationDate = subscription.expirationDate {
                    let time = TimeFormatter.shared.appleStyleTillString(date: expirationDate) ?? L10n.timeFormatNever
                    let message = L10n.subscriptionExpiresIn(time)

                    Text(message.localizedUppercase)
                        .font(style: .caption, weight: .semibold)
                        .foregroundColor(theme.red)
                        .padding(.top, Constants.spacing)
                }
            }
        }
    }

    /// Shows the display name, email, and account button
    @ViewBuilder
    private func profileInfo() -> some View {
        let alignment: HorizontalAlignment = isShowingVertically ? .center : .leading

        VStack(alignment: alignment, spacing: Constants.spacing) {
            if viewModel.shouldShowProfileInfo {
                ProfileInfoLabels(profile: viewModel.profile, alignment: alignment, spacing: Constants.spacing)
            }
            Button(viewModel.profile.isLoggedIn ? L10n.account : L10n.setupAccount) {
                viewModel.accountTapped()
            }
            .buttonStyle(ProfileStrokeButtonStyle())
        }
        // The top spacing appears too high when showing the badge or exp date for some reason so we'll offset it a bit to balance it out
        .padding(.top, {
            guard
                let subscription = viewModel.subscription,
                subscription.tier == .patron,
                subscription.expirationDate != nil
            else {
                return 0
            }

            return -5
        }())
    }

    /// Renders the podcast, listening, and saved time stats
    private func stats() -> some View {
        // Stats
        HStack(alignment: .top) {
            let stats = viewModel.stats

            // Podcast Count
            StatView(value: stats.podcastCount, labels: .init(nonPlural: L10n.podcastSingular, plural: L10n.podcastsPlural))

            // Listening Time
            StatView(formatValues: stats.listeningTime.formatValues, labels: [
                .day: .init(nonPlural: L10n.dayListened, plural: L10n.daysListened),
                .minute: .init(nonPlural: L10n.minuteListened, plural: L10n.minutesListened),
                .hour: .init(nonPlural: L10n.hourListened, plural: L10n.hoursListened),
                .second: .init(nonPlural: L10n.secondsListened, plural: L10n.secondsListened)
            ])

            // Time Saved
            StatView(formatValues: stats.savedTime.formatValues, labels: [
                .day: .init(nonPlural: L10n.daySaved, plural: L10n.daysSaved),
                .minute: .init(nonPlural: L10n.minuteSaved, plural: L10n.minutesSaved),
                .hour: .init(nonPlural: L10n.hourSaved, plural: L10n.hoursSaved),
                .second: .init(nonPlural: L10n.secondsSaved, plural: L10n.secondsSaved)
            ])
        }
    }

    // MARK: - Private: Wrapper Views
    @ViewBuilder
    /// Wraps the main content in the auto sizing content height view, and adds the necessary padding
    private func container<Content: View>(@ViewBuilder _ content: @escaping (GeometryProxy) -> Content) -> some View {
        ContentSizeGeometryReader { proxy in
            contentWrapper(size: proxy.size) {
                content(proxy)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, Constants.paddingTop)
            .padding(.bottom, Constants.paddingBottomAndSides)
            .padding(.horizontal, Constants.paddingBottomAndSides)
        } contentSizeUpdated: { size in
            viewModel.contentSizeChanged(size)
        }
    }

    @ViewBuilder
    /// Wraps the content in an HStack on wide screens like iPad, and a VStack on compact ones like iPhone
    private func contentWrapper<Content: View>(size: CGSize, @ViewBuilder _ content: @escaping () -> Content) -> some View {
        if isShowingVertically {
            VStack(spacing: Constants.spacing) {
                content()
            }
        } else {
            HStack {
                Spacer()

                HStack(spacing: Constants.spacing) {
                    content()
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: -

    // MARK: StatView: Renders the stat value + label
    private struct StatView: View {
        @EnvironmentObject var theme: Theme

        let value: Int
        let label: String?

        /// Takes just a value and determines which label to display depending on if it's singular or not
        init(value: Int, labels: PluralStrings) {
            self.value = value
            self.label = value == 1 ? labels.nonPlural : labels.plural
        }

        /// Maps a the "time format" to the correct labels, in the tuple $0 is singular and $1 is plural
        init(formatValues: Double.TimeFormatValueType, labels: [Double.TimeFormatUnit: PluralStrings]) {
            let (value, unit) = formatValues
            let intValue = Int(value)

            self.value = intValue
            self.label = labels[unit].map { intValue == 1 ? $0.nonPlural : $0.plural }
        }

        var body: some View {
            label.map { label in
                VStack(spacing: 4) {
                    Text("\(value.abbreviated)")
                        .font(size: 18, style: .body, weight: .bold)
                        .foregroundColor(theme.primaryText01)

                    Text(label.localizedUppercase)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .font(style: .caption2, weight: .semibold)
                        .foregroundColor(theme.primaryText02)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
        }

        struct PluralStrings {
            let nonPlural: String
            let plural: String
        }
    }

    // MARK: ProfileStrokeButtonStyle: Simple rounded border button for the profile view
    private struct ProfileStrokeButtonStyle: ButtonStyle {
        @EnvironmentObject var theme: Theme

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(style: .subheadline, weight: .medium)
                .foregroundColor(theme.primaryText01)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: ViewConstants.buttonCornerRadius)
                        .stroke(theme.primaryUi05, lineWidth: ViewConstants.buttonStrokeWidth)
                )
                .applyButtonEffect(isPressed: configuration.isPressed)
                .contentShape(Rectangle())
        }
    }

    // MARK: - View Constants
    private enum Constants {
        static let spacing = 16.0
        static let imageSize = 104.0
        static let paddingTop = 30.0
        static let paddingBottomAndSides = 20.0
    }
}

// MARK: - Previews
struct ProfileHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewContent()
    }

    struct PreviewContent: View {
        var body: some View {
            VStack {
                ProfileHeaderView(viewModel: .init())
                Spacer()
            }.setupDefaultEnvironment()
        }
    }
}
