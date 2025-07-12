import SwiftUI
import PocketCastsServer
import PocketCastsUtils

struct SurveyDebugInfoView: View {
    @State private var surveyPresentationDates: [Date] = []
    @State private var lastSurveyNotReallyDate: Date?
    @State private var reviewRequestDates: [Date] = []
    @State private var episodeCompletionCount: Int = 0
    @State private var plusUpgradeDate: Date?
    @State private var canShowSurvey: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Survey Eligibility")
                .font(.headline)

            HStack {
                Text("Can Show Survey:")
                Spacer()
                Text(canShowSurvey ? "YES" : "NO")
                    .foregroundColor(canShowSurvey ? .green : .red)
                    .fontWeight(.bold)
            }

            Divider()

            Text("Survey Presentation History")
                .font(.subheadline)
                .fontWeight(.semibold)

            if surveyPresentationDates.isEmpty {
                Text("No surveys shown yet")
                    .foregroundColor(.secondary)
            } else {
                ForEach(surveyPresentationDates.indices, id: \.self) { index in
                    Text("• \(surveyPresentationDates[index].formatted())")
                        .font(.caption)
                }
            }

            Divider()

            Text("Last 'Not Really' Response")
                .font(.subheadline)
                .fontWeight(.semibold)

            if let notReallyDate = lastSurveyNotReallyDate {
                Text(notReallyDate.formatted())
                    .font(.caption)
            } else {
                Text("Never responded 'Not Really'")
                    .foregroundColor(.secondary)
            }

            Divider()

            Text("Review Request History")
                .font(.subheadline)
                .fontWeight(.semibold)

            if reviewRequestDates.isEmpty {
                Text("No review requests shown")
                    .foregroundColor(.secondary)
            } else {
                ForEach(reviewRequestDates.indices, id: \.self) { index in
                    Text("• \(reviewRequestDates[index].formatted())")
                        .font(.caption)
                }
            }

            Divider()

            Text("User")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack {
                Text("Episode Completions:")
                Spacer()
                Text("\(episodeCompletionCount)")
            }
            .font(.caption)

            HStack {
                Text("Subscription Tier:")
                Spacer()
                Text(SubscriptionHelper.hasActiveSubscription() ? "Plus/Patron" : "Free")
            }
            .font(.caption)

            if let upgradeDate = plusUpgradeDate {
                HStack {
                    Text("Plus Upgrade Date:")
                    Spacer()
                    Text(upgradeDate.formatted())
                }
                .font(.caption)
            }

            HStack {
                Button("Reset") {
                    Settings.resetReviewRequests()
                    Settings.resetSurveyData()
                    loadDebugData()
                }.buttonStyle(.bordered)

                Button("Present") {
                    (SceneHelper.rootViewController() as? MainTabBarController)?.showUserSatisfactionSurvey()
                }.buttonStyle(.bordered)
            }
        }
        .padding()
        .onAppear {
            loadDebugData()
        }
    }

    private func loadDebugData() {
        surveyPresentationDates = Settings.surveyPresentationDates()

        lastSurveyNotReallyDate = Settings.lastSurveyNotReallyDate()

        reviewRequestDates = Settings.reviewRequestDates()

        episodeCompletionCount = SurveyEventTracker.shared.episodeCompletionCount

        // Check Plus upgrade date
        if SubscriptionHelper.hasActiveSubscription() {
            // Use the subscription start date as a proxy for upgrade date
            if let expiryDate = SubscriptionHelper.subscriptionRenewalDate() {
                let frequency = SubscriptionHelper.subscriptionFrequencyValue()

                if frequency == .monthly {
                    plusUpgradeDate = Calendar.current.date(byAdding: .month, value: -1, to: expiryDate)
                } else if frequency == .yearly {
                    plusUpgradeDate = Calendar.current.date(byAdding: .year, value: -1, to: expiryDate)
                }
            }
        }

        // Check if survey can be shown for any event
        #if !os(watchOS) && !APPCLIP
        canShowSurvey = UserSatisfactionSurveyManager.shared.shouldShowSurvey(for: .firstEpisodeCompleted) ||
                       UserSatisfactionSurveyManager.shared.shouldShowSurvey(for: .thirdEpisodeCompleted) ||
                       UserSatisfactionSurveyManager.shared.shouldShowSurvey(for: .episodeStarred) ||
                       UserSatisfactionSurveyManager.shared.shouldShowSurvey(for: .showRated) ||
                       UserSatisfactionSurveyManager.shared.shouldShowSurvey(for: .filterCreated) ||
                       UserSatisfactionSurveyManager.shared.shouldShowSurvey(for: .plusUpgraded) ||
                       UserSatisfactionSurveyManager.shared.shouldShowSurvey(for: .folderCreated) ||
                       UserSatisfactionSurveyManager.shared.shouldShowSurvey(for: .bookmarkCreated) ||
                       UserSatisfactionSurveyManager.shared.shouldShowSurvey(for: .customThemeSet) ||
                       UserSatisfactionSurveyManager.shared.shouldShowSurvey(for: .referralShared)
        #else
        canShowSurvey = false
        #endif
    }
}

struct SurveyDebugInfoView_Previews: PreviewProvider {
    static var previews: some View {
        SurveyDebugInfoView()
    }
}
