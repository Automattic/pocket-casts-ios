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
    @State private var surveyCheckResult: SurveyCheckResult = .canShow

    var body: some View {
        List {
            Section(header: Text("Eligibility")) {
                HStack {
                    Text("Can Show Survey")
                    Spacer()
                    Text(canShowSurvey ? "YES" : "NO")
                        .foregroundColor(canShowSurvey ? .green : .red)
                        .fontWeight(.bold)
                }

                HStack {
                    Text("Result")
                    Spacer()
                    Text(surveyCheckResult.displayReason)
                        .foregroundColor(surveyCheckResult == .canShow ? .green : .red)
                        .fontWeight(surveyCheckResult == .canShow ? .bold : .regular)
                }
            }

            Section(header: Text("Event History")) {
                HStack {
                    Text("Survey Presentation History")
                    Spacer()
                    if surveyPresentationDates.isEmpty {
                        Text("No surveys shown yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(surveyPresentationDates, id: \.self) { date in
                            Text(date.formatted())
                        }
                    }
                }
                HStack {
                    Text("Last 'Not Really' Response")
                    Spacer()
                    if let notReallyDate = lastSurveyNotReallyDate {
                        Text(notReallyDate.formatted())
                    } else {
                        Text("Never responded 'Not Really'")
                            .foregroundColor(.secondary)
                    }
                }
                HStack {
                    Text("Review Request")
                    Spacer()
                    if reviewRequestDates.isEmpty {
                        Text("No review requests shown")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(reviewRequestDates, id: \.self) { date in
                            Text(date.formatted())
                        }
                    }
                }
            }

            Section(header: Text("User")) {
                HStack {
                    Text("Episode Completions")
                    Spacer()
                    Text("\(episodeCompletionCount)")
                }

                HStack {
                    Text("Subscription Tier")
                    Spacer()
                    Text(SubscriptionHelper.hasActiveSubscription() ? "Plus/Patron" : "Free")
                }

                if let upgradeDate = plusUpgradeDate {
                    HStack {
                        Text("Upgrade Date")
                        Spacer()
                        Text(upgradeDate.formatted())
                    }
                }
            }

            Section {
                Button("Reset Survey & Reviews") {
                    Settings.resetReviewRequests()
                    Settings.resetSurveyData()
                    loadDebugData()
                }

                Button("Present Survey") {
                    guard let rootViewController = SceneHelper.rootViewController() else {
                        // Show an alert indicating failure
                        Toast.show("Failed to find root view controller from SceneHelper")
                        return
                    }
                    presentSurveyWithAnimation(from: rootViewController)
                }
            }
        }
        .listStyle(.insetGrouped)
        .miniPlayerSafeAreaInset()
        .navigationTitle("Survey Debug Info")
        .onAppear(perform: loadDebugData)
    }

    private var defaultEvent: SurveyTriggerEvent {
        return SubscriptionHelper.hasActiveSubscription() ? .folderCreated : .episodeStarred
    }

    private func presentSurveyWithAnimation(from rootViewController: UIViewController) {
        UserSatisfactionSurveyManager.shared.presentSurvey(from: rootViewController, event: defaultEvent, skipCheck: true)
    }

    private func loadDebugData() {
        surveyPresentationDates = Settings.surveyPresentationDates()
        lastSurveyNotReallyDate = Settings.lastSurveyNotReallyDate()
        reviewRequestDates = Settings.reviewRequestDates()
        episodeCompletionCount = UserSatisfactionSurveyManager.shared.episodeCompletionCount

        if SubscriptionHelper.hasActiveSubscription(),
           let expiryDate = SubscriptionHelper.subscriptionRenewalDate() {
            let frequency = SubscriptionHelper.subscriptionFrequencyValue()
            switch frequency {
            case .monthly:
                plusUpgradeDate = Calendar.current.date(byAdding: .month, value: -1, to: expiryDate)
            case .yearly:
                plusUpgradeDate = Calendar.current.date(byAdding: .year, value: -1, to: expiryDate)
            default:
                break
            }
        }

        #if !os(watchOS) && !APPCLIP
        surveyCheckResult = UserSatisfactionSurveyManager.shared.checkSurveyEligibility(for: defaultEvent)
        canShowSurvey = surveyCheckResult == .canShow
        #else
        canShowSurvey = false
        #endif
    }
}
