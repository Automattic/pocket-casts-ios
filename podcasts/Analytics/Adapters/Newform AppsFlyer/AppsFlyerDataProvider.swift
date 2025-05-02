import PocketCastsServer

struct AppsFlyerDataProvider: AnonymousIdentifiable {
    let devKey = ApiCredentials.appsFlyerDevKey
    let appleAppID = "414834813"
    let fbAppID = ApiCredentials.a8cFBAppID
    let fbClientToken = ApiCredentials.a8cFBClientToken
    let fbAppDisplayName = ApiCredentials.a8cFBAppName
    let userDefaults: UserDefaults
    let supportedEvents: Set<String> = [
        "application_installed",
        "application_opened",
        "user_signed_in",
        "user_account_created",
        "sso_started",
        "purchase_successful",
        "purchase_cancelled",
        "setup_account_shown",
        "setup_account_button_tapped",
        "setup_account_dismissed",
        "setup_account_link_tapped",
        "signin_shown",
        "signin_dismissed",
        "select_account_type_shown",
        "select_account_type_button_tapped",
        "create_account_shown",
        "create_account_dismissed",
        "create_account_clicked",
        "select_payment_frequency_shown",
        "select_payment_frequency_dismissed",
        "select_payment_frequency_next_button_tapped",
        "select_payment_frequency_link_tapped",
        "podcasts_list_shown",
        "podcasts_tab_opened",
        "filters_tab_opened",
        "discover_tab_opened",
        "profile_tab_opened",
        "up_next_tab_opened",
        "profile_shown",
        "podcast_screen_shown",
        "playback_play",
        "filter_list_shown",
        "discover_shown",
        "podcast_subscribed"
    ]

    var anonymousUUID: String {
        generateAnonymousUUID()
    }

    init(
        userDefaults: UserDefaults? = UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId)
    ) {
        self.userDefaults = userDefaults ?? .standard
    }

    var isNewInstall: Bool {
        (UIApplication.shared.delegate as? AppDelegate)?.appInstallState == .installed
    }
}
