import AppsFlyerLib
import PocketCastsUtils

class AppsFlyerAdapter: AnalyticsAdapter {
    private let appsFlyer = AppsFlyerLib.shared()
    private let dataProvider: AppsFlyerDataProvider
    private let notificationCenter: NotificationCenter
    private var appTrackingTransparencyProvider: AppTrackingTransparencyProvider

    deinit {
        notificationCenter.removeObserver(self)
    }

    init(
        dataProvider: AppsFlyerDataProvider = AppsFlyerDataProvider(),
        notificationCenter: NotificationCenter = .default,
        appTrackingTransparencyProvider: AppTrackingTransparencyProvider
    ) {
        self.dataProvider = dataProvider
        self.notificationCenter = notificationCenter
        self.appTrackingTransparencyProvider = appTrackingTransparencyProvider
        startObserver()
        setup()
    }

    func track(name: String, properties: [AnyHashable: Any]?) {
        guard
            FeatureFlag.podcastNewformAppsFlyer.enabled,
            dataProvider.userId != nil,
            appTrackingTransparencyProvider.userGaveConsent()
        else {
            return
        }
        appsFlyer.logEvent(name, withValues: properties)
    }

    private func setup() {
        guard FeatureFlag.podcastNewformAppsFlyer.enabled,
        let userId = dataProvider.userId else {
            return
        }
        if appTrackingTransparencyProvider.userDeniedConsent() {
            return
        }
        appsFlyer.appsFlyerDevKey = dataProvider.devKey
        appsFlyer.appleAppID = dataProvider.appleAppID
        appsFlyer.customerUserID = userId
#if DEBUG
        appsFlyer.isDebug = true
#endif
        let shouldShowPrompt = appTrackingTransparencyProvider.shouldShowPrompt()
        if !shouldShowPrompt, appTrackingTransparencyProvider.userGaveConsent() {
            start()
        } else if shouldShowPrompt {
            appsFlyer.waitForATTUserAuthorization(timeoutInterval: 60)
            appTrackingTransparencyProvider.authorizationStatusUpdated = { [weak self] authorized in
                if authorized {
                    self?.start()
                }
            }
        }
    }

    private func start() {
        appsFlyer.start {  params, error in
            if let error {
                FileLog.shared.addMessage("AppsFlyer start error: \(error)")
            } else {
                FileLog.shared.addMessage("AppsFlyer start success: \(params ?? [:])")
            }
        }
    }

    private func startObserver() {
        notificationCenter.addObserver(
            forName: .userLoginDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setup()
        }
    }
}
