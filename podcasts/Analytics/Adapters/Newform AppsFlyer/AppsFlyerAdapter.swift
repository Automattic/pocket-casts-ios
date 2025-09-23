import AppsFlyerLib
import PocketCastsUtils
import FacebookCore

class AppsFlyerAdapter: AnalyticsAdapter {
    let isThirdPartyAdapter = true

    private let appsFlyer = AppsFlyerLib.shared()
    private let dataProvider: AppsFlyerDataProvider
    private var appTrackingTransparencyProvider: AppTrackingTransparencyProvider

    init(
        dataProvider: AppsFlyerDataProvider = AppsFlyerDataProvider(),
        appTrackingTransparencyProvider: AppTrackingTransparencyProvider
    ) {
        self.dataProvider = dataProvider
        self.appTrackingTransparencyProvider = appTrackingTransparencyProvider
        appsFlyerSetup()
        checkUserConsent()
#if DEBUG
        FileLog.shared.console("AppsFlyer anonymous UUID \(dataProvider.anonymousUUID)")
#endif
    }

    func track(name: String, properties: [AnyHashable: Any]?) {
        guard
            appTrackingTransparencyProvider.userGaveConsent(),
            dataProvider.supportedEvents.contains(name)
        else {
            return
        }
        appsFlyer.logEvent(name, withValues: properties)
        facebookTrack(name: name, properties: properties)
    }

    private func appsFlyerSetup() {
        appsFlyer.appsFlyerDevKey = dataProvider.devKey
        appsFlyer.appleAppID = dataProvider.appleAppID
        appsFlyer.customerUserID = dataProvider.anonymousUUID
#if DEBUG
        appsFlyer.isDebug = FeatureFlag.appsFlyerLogging.enabled
#endif
        // Facebook AEM Analytics
        FacebookCore.Settings.shared.appID = dataProvider.fbAppID
        FacebookCore.Settings.shared.displayName = dataProvider.fbAppDisplayName
        FacebookCore.Settings.shared.clientToken = dataProvider.fbClientToken
        FacebookCore.Settings.shared.isAutoLogAppEventsEnabled = true
        FacebookCore.Settings.shared.isAdvertiserIDCollectionEnabled = true

        setAdvertiserTrackingEnabled()
    }

    private func checkUserConsent() {
        if appTrackingTransparencyProvider.userDeniedConsent() {
            FileLog.shared.addMessage("AppsFlyer setup not possible as ATT is denied")
            return
        }
        let shouldShowPrompt = appTrackingTransparencyProvider.shouldShowPrompt()
        if !shouldShowPrompt, appTrackingTransparencyProvider.userGaveConsent() {
            start()
        } else if shouldShowPrompt {
            FileLog.shared.addMessage("AppsFlyer ATT not determined: wait for user to give consent")
            appTrackingTransparencyProvider.authorizationStatusUpdated = { [weak self] authorized, status in
                FileLog.shared.addMessage("AppsFlyer ATT auth state changed: authorized \(authorized), statusd \(status)")
                if authorized {
                    self?.start()
                    self?.setAdvertiserTrackingEnabled()
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
                DispatchQueue.main.async { [weak self] in
                    self?.trackApplicationInstalledIfNeeded()
                }
            }
        }
    }

    private func trackApplicationInstalledIfNeeded() {
        if dataProvider.isNewInstall {
            track(name: "application_installed", properties: nil)
            track(name: "application_opened", properties: nil)
        }
    }

    private func setAdvertiserTrackingEnabled() {
        if #unavailable(iOS 17.0) {
            FacebookCore.Settings.shared.isAdvertiserTrackingEnabled = appTrackingTransparencyProvider.userGaveConsent()
        }
    }

    private func facebookTrack(name: String, properties: [AnyHashable: Any]?) {
        let parameters: [AppEvents.ParameterName: Any]? = properties?.reduce([:]) { (dict, element) in
            let (key, value) = element
            var modDict = dict
            if let keyString = key as? String {
                let paramName = AppEvents.ParameterName(rawValue: keyString)
                modDict[paramName] = value
            }
            return modDict
        }
        FacebookCore.AppEvents.shared.logEvent(AppEvents.Name(name), parameters: parameters ?? [:])
    }
}
