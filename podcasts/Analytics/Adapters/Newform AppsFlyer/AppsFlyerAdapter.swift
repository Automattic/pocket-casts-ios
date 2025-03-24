import AppsFlyerLib
import PocketCastsUtils

class AppsFlyerAdapter: AnalyticsAdapter {
    private let appsFlyer = AppsFlyerLib.shared()
    private let dataProvider: AppsFlyerDataProvider
    private let notificationCenter: NotificationCenter
    private var canTrack: Bool {
        FeatureFlag.podcastNewformAppsFlyer.enabled &&
        dataProvider.userId != nil
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    init(
        dataProvider: AppsFlyerDataProvider = AppsFlyerDataProvider(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.dataProvider = dataProvider
        self.notificationCenter = notificationCenter
        startObserver()
        setup()
    }

    func track(name: String, properties: [AnyHashable: Any]?) {
        guard FeatureFlag.podcastNewformAppsFlyer.enabled else {
            return
        }
        appsFlyer.logEvent(name, withValues: properties)
    }

    private func setup() {
        guard FeatureFlag.podcastNewformAppsFlyer.enabled,
        let userId = dataProvider.userId else {
            return
        }
        appsFlyer.appsFlyerDevKey = dataProvider.devKey
        appsFlyer.appleAppID = dataProvider.appleAppID
        appsFlyer.customerUserID = userId
#if DEBUG
        appsFlyer.isDebug = true
#endif
        //Check ATT status
//        appsFlyer.waitForATTUserAuthorization(timeoutInterval: 60)
        //start()
    }

    private func start() {
#if DEBUG
        appsFlyer.start {  params, error in
            if let error {
                FileLog.shared.console("AppsFlyer start error: \(error)")
            } else {
                FileLog.shared.console("AppsFlyer start success: \(params ?? [:])")
            }
        }
#else
        appsFlyer.start()
#endif
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
