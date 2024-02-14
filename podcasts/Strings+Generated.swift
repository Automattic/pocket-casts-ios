// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Automattic Family
  internal static var aboutA8cFamily: String { return L10n.tr("Localizable", "about_a8c_family") }
  /// Acknowledgements
  internal static var aboutAcknowledgements: String { return L10n.tr("Localizable", "about_acknowledgements") }
  /// Join From Anywhere
  internal static var aboutJoinFromAnywhere: String { return L10n.tr("Localizable", "about_join_from_anywhere") }
  /// Legal and More
  internal static var aboutLegalAndMore: String { return L10n.tr("Localizable", "about_legal_and_more") }
  /// Privacy Policy
  internal static var aboutPrivacyPolicy: String { return L10n.tr("Localizable", "about_privacy_policy") }
  /// Rate Us
  internal static var aboutRateUs: String { return L10n.tr("Localizable", "about_rate_us") }
  /// Share With Friends
  internal static var aboutShareFriends: String { return L10n.tr("Localizable", "about_share_friends") }
  /// Terms of service
  internal static var aboutTermsOfService: String { return L10n.tr("Localizable", "about_terms_of_service") }
  /// Website
  internal static var aboutWebsite: String { return L10n.tr("Localizable", "about_website") }
  /// Work With Us
  internal static var aboutWorkWithUs: String { return L10n.tr("Localizable", "about_work_with_us") }
  /// Cancel multiselect
  internal static var accessibilityCancelMultiselect: String { return L10n.tr("Localizable", "accessibility_cancel_multiselect") }
  /// Close dialog
  internal static var accessibilityCloseDialog: String { return L10n.tr("Localizable", "accessibility_close_dialog") }
  /// Deselect Episode
  internal static var accessibilityDeselectEpisode: String { return L10n.tr("Localizable", "accessibility_deselect_episode") }
  /// Disabled
  internal static var accessibilityDisabled: String { return L10n.tr("Localizable", "accessibility_disabled") }
  /// Dismiss
  internal static var accessibilityDismiss: String { return L10n.tr("Localizable", "accessibility_dismiss") }
  /// Episode Playback
  internal static var accessibilityEpisodePlayback: String { return L10n.tr("Localizable", "accessibility_episode_playback") }
  /// Tap to hide filter details
  internal static var accessibilityHideFilterDetails: String { return L10n.tr("Localizable", "accessibility_hide_filter_details") }
  /// Tap to navigate to main podcast information page
  internal static var accessibilityHintPlayerNavigateToPodcastLabel: String { return L10n.tr("Localizable", "accessibility_hint_player_navigate_to_podcast_label") }
  /// Double tap to star episode
  internal static var accessibilityHintStar: String { return L10n.tr("Localizable", "accessibility_hint_star") }
  /// Double tap to remove star from episode
  internal static var accessibilityHintUnstar: String { return L10n.tr("Localizable", "accessibility_hint_unstar") }
  /// More actions
  internal static var accessibilityMoreActions: String { return L10n.tr("Localizable", "accessibility_more_actions") }
  /// Locked, Patron Feature
  internal static var accessibilityPatronOnly: String { return L10n.tr("Localizable", "accessibility_patron_only") }
  /// %1$@ percent completed
  internal static func accessibilityPercentCompleteFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "accessibility_percent_complete_format", String(describing: p1))
  }
  /// %1$@ of %2$@
  internal static func accessibilityPlaybackProgress(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "accessibility_playback_progress", String(describing: p1), String(describing: p2))
  }
  /// Playback speed %1$@ times
  internal static func accessibilityPlayerEffectsPlaybackSpeed(_ p1: Any) -> String {
    return L10n.tr("Localizable", "accessibility_player_effects_playback_speed", String(describing: p1))
  }
  /// Playlist color %1$@
  internal static func accessibilityPlaylistColor(_ p1: Any) -> String {
    return L10n.tr("Localizable", "accessibility_playlist_color", String(describing: p1))
  }
  /// Locked, Plus Feature
  internal static var accessibilityPlusOnly: String { return L10n.tr("Localizable", "accessibility_plus_only") }
  /// Pocket Casts Settings
  internal static var accessibilityProfileSettings: String { return L10n.tr("Localizable", "accessibility_profile_settings") }
  /// Select Episode
  internal static var accessibilitySelectEpisode: String { return L10n.tr("Localizable", "accessibility_select_episode") }
  /// Tap to show filter details
  internal static var accessibilityShowFilterDetails: String { return L10n.tr("Localizable", "accessibility_show_filter_details") }
  /// Tap to view or setup account
  internal static var accessibilitySignIn: String { return L10n.tr("Localizable", "accessibility_sign_in") }
  /// Sort and Options
  internal static var accessibilitySortAndOptions: String { return L10n.tr("Localizable", "accessibility_sort_and_options") }
  /// Account
  internal static var account: String { return L10n.tr("Localizable", "account") }
  /// Change Email
  internal static var accountChangeEmail: String { return L10n.tr("Localizable", "account_change_email") }
  /// Almost There!
  internal static var accountCompletionNudge: String { return L10n.tr("Localizable", "account_completion_nudge") }
  /// Finalize your payment to finish upgrading your account.
  internal static var accountCompletionNudgeMsg: String { return L10n.tr("Localizable", "account_completion_nudge_msg") }
  /// Account Created
  internal static var accountCreated: String { return L10n.tr("Localizable", "account_created") }
  /// Complete Account
  internal static var accountCreationComplete: String { return L10n.tr("Localizable", "account_creation_complete") }
  /// Delete Account
  internal static var accountDeleteAccount: String { return L10n.tr("Localizable", "account_delete_account") }
  /// Yes, Delete It
  internal static var accountDeleteAccountConf: String { return L10n.tr("Localizable", "account_delete_account_conf") }
  /// Delete Account Failed
  internal static var accountDeleteAccountError: String { return L10n.tr("Localizable", "account_delete_account_error") }
  /// Unable to delete account.
  internal static var accountDeleteAccountErrorMsg: String { return L10n.tr("Localizable", "account_delete_account_error_msg") }
  /// Last chance, you definitely want to delete your account? You will lose all your subscriptions and play history permanently!
  internal static var accountDeleteAccountFinalAlertMsg: String { return L10n.tr("Localizable", "account_delete_account_final_alert_msg") }
  /// Are you sure you want to delete your account, there's no way to undo this!
  internal static var accountDeleteAccountFirstAlertMsg: String { return L10n.tr("Localizable", "account_delete_account_first_alert_msg") }
  /// Delete Account?
  internal static var accountDeleteAccountTitle: String { return L10n.tr("Localizable", "account_delete_account_title") }
  /// Free Account
  internal static var accountDetailsFreeAccount: String { return L10n.tr("Localizable", "account_details_free_account") }
  /// Listened for %1$@
  internal static func accountDetailsListenedFor(_ p1: Any) -> String {
    return L10n.tr("Localizable", "account_details_listened_for", String(describing: p1))
  }
  /// Take your podcasting experience to the next level with exclusive access to features and customisation options.
  internal static var accountDetailsPlusTitle: String { return L10n.tr("Localizable", "account_details_plus_title") }
  /// Log in
  internal static var accountLogin: String { return L10n.tr("Localizable", "account_login") }
  /// Renews automatically monthly
  internal static var accountPaymentRenewsMonthly: String { return L10n.tr("Localizable", "account_payment_renews_monthly") }
  /// Renews automatically yearly
  internal static var accountPaymentRenewsYearly: String { return L10n.tr("Localizable", "account_payment_renews_yearly") }
  /// Privacy Policy
  internal static var accountPrivacyPolicy: String { return L10n.tr("Localizable", "account_privacy_policy") }
  /// Registration failed, please try again later
  internal static var accountRegistrationFailed: String { return L10n.tr("Localizable", "account_registration_failed") }
  /// Select Account Type
  internal static var accountSelectType: String { return L10n.tr("Localizable", "account_select_type") }
  /// Sign Out
  internal static var accountSignOut: String { return L10n.tr("Localizable", "account_sign_out") }
  /// Signing out will remove %1$@ supported podcasts from this device. Are you sure?
  internal static func accountSignOutSupporterPrompt(_ p1: Any) -> String {
    return L10n.tr("Localizable", "account_sign_out_supporter_prompt", String(describing: p1))
  }
  /// You can sign in again to regain access.
  internal static var accountSignOutSupporterSubtitle: String { return L10n.tr("Localizable", "account_sign_out_supporter_subtitle") }
  /// Turns out, if you type Google into Google, you can break the internet. 🫢 
  /// 
  /// Tap the button below to sign into your Pocket Casts account again.
  internal static var accountSignedOutAlertMessage: String { return L10n.tr("Localizable", "account_signed_out_alert_message") }
  /// You've been signed out.
  internal static var accountSignedOutAlertTitle: String { return L10n.tr("Localizable", "account_signed_out_alert_title") }
  /// Sign in failed. Please try again.
  internal static var accountSsoFailed: String { return L10n.tr("Localizable", "account_sso_failed") }
  /// Pocket Casts Account
  internal static var accountTitle: String { return L10n.tr("Localizable", "account_title") }
  /// Account Upgraded
  internal static var accountUpgraded: String { return L10n.tr("Localizable", "account_upgraded") }
  /// Welcome to Pocket Casts!
  internal static var accountWelcome: String { return L10n.tr("Localizable", "account_welcome") }
  /// Welcome to Pocket Casts Plus!
  internal static var accountWelcomePlus: String { return L10n.tr("Localizable", "account_welcome_plus") }
  /// Add Bookmark
  internal static var addBookmark: String { return L10n.tr("Localizable", "add_bookmark") }
  /// Add an optional title to identify this bookmark
  internal static var addBookmarkSubtitle: String { return L10n.tr("Localizable", "add_bookmark_subtitle") }
  /// Add to Up Next
  internal static var addToUpNext: String { return L10n.tr("Localizable", "add_to_up_next") }
  /// After Playing
  internal static var afterPlaying: String { return L10n.tr("Localizable", "after_playing") }
  /// If your Up Next queue is empty and you start listening to an episode, Autoplay will keep playing episodes from that show or list.
  internal static var announcementAutoplayDescription: String { return L10n.tr("Localizable", "announcement_autoplay_description") }
  /// Autoplay is here!
  internal static var announcementAutoplayTitle: String { return L10n.tr("Localizable", "announcement_autoplay_title") }
  /// You can now save timestamps of episodes from the actions menu in the player or with a headphones action.
  internal static var announcementBookmarksDescription: String { return L10n.tr("Localizable", "announcement_bookmarks_description") }
  /// Bookmarks are here!
  internal static var announcementBookmarksTitle: String { return L10n.tr("Localizable", "announcement_bookmarks_title") }
  /// Join us in the beta testing for bookmarks!
  internal static var announcementBookmarksTitleBeta: String { return L10n.tr("Localizable", "announcement_bookmarks_title_beta") }
  /// App Badge
  internal static var appBadge: String { return L10n.tr("Localizable", "app_badge") }
  /// Classic
  internal static var appIconClassic: String { return L10n.tr("Localizable", "app_icon_classic") }
  /// Dark
  internal static var appIconDark: String { return L10n.tr("Localizable", "app_icon_dark") }
  /// Default
  internal static var appIconDefault: String { return L10n.tr("Localizable", "app_icon_default") }
  /// Electric Blue
  internal static var appIconElectricBlue: String { return L10n.tr("Localizable", "app_icon_electric_blue") }
  /// Electric Pink
  internal static var appIconElectricPink: String { return L10n.tr("Localizable", "app_icon_electric_pink") }
  /// Halloween
  internal static var appIconHalloween: String { return L10n.tr("Localizable", "app_icon_halloween") }
  /// Indigo
  internal static var appIconIndigo: String { return L10n.tr("Localizable", "app_icon_indigo") }
  /// Patron Chrome
  internal static var appIconPatronChrome: String { return L10n.tr("Localizable", "app_icon_patron_chrome") }
  /// Patron Dark
  internal static var appIconPatronDark: String { return L10n.tr("Localizable", "app_icon_patron_dark") }
  /// Patron Glow
  internal static var appIconPatronGlow: String { return L10n.tr("Localizable", "app_icon_patron_glow") }
  /// Patron Round
  internal static var appIconPatronRound: String { return L10n.tr("Localizable", "app_icon_patron_round") }
  /// Plus
  internal static var appIconPlus: String { return L10n.tr("Localizable", "app_icon_plus") }
  /// Pocket Cats
  internal static var appIconPocketCats: String { return L10n.tr("Localizable", "app_icon_pocket_cats") }
  /// Radioactivity
  internal static var appIconRadioactivity: String { return L10n.tr("Localizable", "app_icon_radioactivity") }
  /// Red Velvet
  internal static var appIconRedVelvet: String { return L10n.tr("Localizable", "app_icon_red_velvet") }
  /// Rosé
  internal static var appIconRose: String { return L10n.tr("Localizable", "app_icon_rose") }
  /// Round Dark
  internal static var appIconRoundDark: String { return L10n.tr("Localizable", "app_icon_round_dark") }
  /// Round Light
  internal static var appIconRoundLight: String { return L10n.tr("Localizable", "app_icon_round_light") }
  /// Hey! Here is a link to download the Pocket Casts app. I'm really enjoying it and thought you might too.
  internal static var appShareText: String { return L10n.tr("Localizable", "app_share_text") }
  /// Version %1$@ (%2$@)
  internal static func appVersion(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "app_version", String(describing: p1), String(describing: p2))
  }
  /// App Icon
  internal static var appearanceAppIconHeader: String { return L10n.tr("Localizable", "appearance_app_icon_header") }
  /// Podcast Artwork
  internal static var appearanceArtworkHeader: String { return L10n.tr("Localizable", "appearance_artwork_header") }
  /// Dark Theme
  internal static var appearanceDarkTheme: String { return L10n.tr("Localizable", "appearance_dark_theme") }
  /// Use Embedded Artwork
  internal static var appearanceEmbeddedArtwork: String { return L10n.tr("Localizable", "appearance_embedded_artwork") }
  /// Shows artwork from the downloaded file (if it exists) in the player instead of using the show's artwork.
  internal static var appearanceEmbeddedArtworkSubtitle: String { return L10n.tr("Localizable", "appearance_embedded_artwork_subtitle") }
  /// Light Theme
  internal static var appearanceLightTheme: String { return L10n.tr("Localizable", "appearance_light_theme") }
  /// Use iOS Light/Dark Mode
  internal static var appearanceMatchDeviceTheme: String { return L10n.tr("Localizable", "appearance_match_device_theme") }
  /// Refresh All Podcast Artwork
  internal static var appearanceRefreshAllArtwork: String { return L10n.tr("Localizable", "appearance_refresh_all_artwork") }
  /// Refreshing your artwork now
  internal static var appearanceRefreshAllArtworkConfMsg: String { return L10n.tr("Localizable", "appearance_refresh_all_artwork_conf_msg") }
  /// Aye Aye Captain
  internal static var appearanceRefreshAllArtworkConfTitle: String { return L10n.tr("Localizable", "appearance_refresh_all_artwork_conf_title") }
  /// Theme
  internal static var appearanceThemeHeader: String { return L10n.tr("Localizable", "appearance_theme_header") }
  /// Select Theme
  internal static var appearanceThemeSelect: String { return L10n.tr("Localizable", "appearance_theme_select") }
  /// Archive
  internal static var archive: String { return L10n.tr("Localizable", "archive") }
  /// Are You Sure?
  internal static var areYouSure: String { return L10n.tr("Localizable", "are_you_sure") }
  /// Auto Add To
  internal static var autoAdd: String { return L10n.tr("Localizable", "auto_add") }
  /// To Bottom
  internal static var autoAddToBottom: String { return L10n.tr("Localizable", "auto_add_to_bottom") }
  /// To Top
  internal static var autoAddToTop: String { return L10n.tr("Localizable", "auto_add_to_top") }
  /// Stop Adding New Episodes
  internal static var autoAddToUpNextStop: String { return L10n.tr("Localizable", "auto_add_to_up_next_stop") }
  /// Stop Adding
  internal static var autoAddToUpNextStopShort: String { return L10n.tr("Localizable", "auto_add_to_up_next_stop_short") }
  /// Only Add To Top
  internal static var autoAddToUpNextTopOnly: String { return L10n.tr("Localizable", "auto_add_to_up_next_top_only") }
  /// Only Add To Top
  internal static var autoAddToUpNextTopOnlyShort: String { return L10n.tr("Localizable", "auto_add_to_up_next_top_only_short") }
  /// Auto Download First
  internal static var autoDownloadFirst: String { return L10n.tr("Localizable", "auto_download_first") }
  /// Enable to auto download episodes in this filter
  internal static var autoDownloadOffSubtitle: String { return L10n.tr("Localizable", "auto_download_off_subtitle") }
  /// The first %1$@ episodes in this filter will be automatically downloaded
  internal static func autoDownloadOnPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "auto_download_on_plural_format", String(describing: p1))
  }
  /// First
  internal static var autoDownloadPromptFirst: String { return L10n.tr("Localizable", "auto_download_prompt_first") }
  /// Back
  internal static var back: String { return L10n.tr("Localizable", "back") }
  /// Please download Pocket Casts from the App Store to purchase %1$@.
  internal static func betaPurchaseDisabled(_ p1: Any) -> String {
    return L10n.tr("Localizable", "beta_purchase_disabled", String(describing: p1))
  }
  /// Thank you for beta testing!
  internal static var betaThankYou: String { return L10n.tr("Localizable", "beta_thank_you") }
  /// Bookmark added
  internal static var bookmarkAdded: String { return L10n.tr("Localizable", "bookmark_added") }
  /// View
  internal static var bookmarkAddedButtonTitle: String { return L10n.tr("Localizable", "bookmark_added_button_title") }
  /// Bookmark "%1$@" added
  internal static func bookmarkAddedNotification(_ p1: Any) -> String {
    return L10n.tr("Localizable", "bookmark_added_notification", String(describing: p1))
  }
  /// Bookmark
  internal static var bookmarkDefaultTitle: String { return L10n.tr("Localizable", "bookmark_default_title") }
  /// Are you sure you want to delete these bookmarks, there’s no way to undo it!
  internal static var bookmarkDeleteWarningBody: String { return L10n.tr("Localizable", "bookmark_delete_warning_body") }
  /// Delete Bookmarks?
  internal static var bookmarkDeleteWarningTitle: String { return L10n.tr("Localizable", "bookmark_delete_warning_title") }
  /// We couldn't find any bookmarks for that search.
  internal static var bookmarkSearchNoResultsMessage: String { return L10n.tr("Localizable", "bookmark_search_no_results_message") }
  /// No bookmarks found
  internal static var bookmarkSearchNoResultsTitle: String { return L10n.tr("Localizable", "bookmark_search_no_results_title") }
  /// Bookmark "%1$@" updated
  internal static func bookmarkUpdatedNotification(_ p1: Any) -> String {
    return L10n.tr("Localizable", "bookmark_updated_notification", String(describing: p1))
  }
  /// Bookmarks
  internal static var bookmarks: String { return L10n.tr("Localizable", "bookmarks") }
  /// %1$@ bookmarks
  internal static func bookmarksCountPlural(_ p1: Any) -> String {
    return L10n.tr("Localizable", "bookmarks_count_plural", String(describing: p1))
  }
  /// 1 bookmark
  internal static var bookmarksCountSingular: String { return L10n.tr("Localizable", "bookmarks_count_singular") }
  /// Unlock this feature and many more with Pocket Casts %1$@ and save timestamps of your favorite episodes. Available for %2$@ subscribers soon.
  internal static func bookmarksEarlyAccessLockedMessage(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "bookmarks_early_access_locked_message", String(describing: p1), String(describing: p2))
  }
  /// Unlock this feature and many more with Pocket Casts %1$@ and save timestamps of your favorite episodes.
  internal static func bookmarksLockedMessage(_ p1: Any) -> String {
    return L10n.tr("Localizable", "bookmarks_locked_message", String(describing: p1))
  }
  /// Bottom
  internal static var bottom: String { return L10n.tr("Localizable", "bottom") }
  /// Bulk downloads are limited to %1$@.
  internal static func bulkDownloadMaxFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "bulk_download_max_format", String(describing: p1))
  }
  /// Cancel
  internal static var cancel: String { return L10n.tr("Localizable", "cancel") }
  /// Yes, Cancel my Subscription
  internal static var cancelConfirmCancelButtonTitle: String { return L10n.tr("Localizable", "cancel_confirm_cancel_button_title") }
  /// Your folders will be removed and their contents will move back to the Podcasts screen.
  internal static var cancelConfirmItemFolders: String { return L10n.tr("Localizable", "cancel_confirm_item_folders") }
  /// Access to Pocket Casts Plus features will be locked after this date.
  internal static var cancelConfirmItemPlus: String { return L10n.tr("Localizable", "cancel_confirm_item_plus") }
  /// All files uploaded to your Pocket Casts account will be deleted (but downloaded files on your mobile devices will remain)
  internal static var cancelConfirmItemUploads: String { return L10n.tr("Localizable", "cancel_confirm_item_uploads") }
  /// You will no longer be able to access Pocket Casts using your web browser, or desktop computer.
  internal static var cancelConfirmItemWebPlayer: String { return L10n.tr("Localizable", "cancel_confirm_item_web_player") }
  /// Actually, I want to stay
  internal static var cancelConfirmStayButtonTitle: String { return L10n.tr("Localizable", "cancel_confirm_stay_button_title") }
  /// Your current subscription will remain active until %1$@.
  internal static func cancelConfirmSubExpiry(_ p1: Any) -> String {
    return L10n.tr("Localizable", "cancel_confirm_sub_expiry", String(describing: p1))
  }
  /// your expiration date
  internal static var cancelConfirmSubExpiryDateFallback: String { return L10n.tr("Localizable", "cancel_confirm_sub_expiry_date_fallback") }
  /// This will change your plan to a free account.
  internal static var cancelConfirmSubtitle: String { return L10n.tr("Localizable", "cancel_confirm_subtitle") }
  /// Cancel Download
  internal static var cancelDownload: String { return L10n.tr("Localizable", "cancel_download") }
  /// Unable To Cancel
  internal static var cancelFailed: String { return L10n.tr("Localizable", "cancel_failed") }
  /// Cancel Subscription
  internal static var cancelSubscription: String { return L10n.tr("Localizable", "cancel_subscription") }
  /// Canceling...
  internal static var canceling: String { return L10n.tr("Localizable", "canceling") }
  /// %1$@ of %2$@. %3$@
  internal static func carplayChapterCount(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return L10n.tr("Localizable", "carplay_chapter_count", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// More
  internal static var carplayMore: String { return L10n.tr("Localizable", "carplay_more") }
  /// Playback Speed
  internal static var carplayPlaybackSpeed: String { return L10n.tr("Localizable", "carplay_playback_speed") }
  /// Up Next Queue
  internal static var carplayUpNextQueue: String { return L10n.tr("Localizable", "carplay_up_next_queue") }
  /// Change App Icon
  internal static var changeAppIcon: String { return L10n.tr("Localizable", "change_app_icon") }
  /// Change the title that identifies this bookmark
  internal static var changeBookmarkSubtitle: String { return L10n.tr("Localizable", "change_bookmark_subtitle") }
  /// Change title
  internal static var changeBookmarkTitle: String { return L10n.tr("Localizable", "change_bookmark_title") }
  /// Change Email Address
  internal static var changeEmail: String { return L10n.tr("Localizable", "change_email") }
  /// Email Address Changed
  internal static var changeEmailConf: String { return L10n.tr("Localizable", "change_email_conf") }
  /// Change Password
  internal static var changePassword: String { return L10n.tr("Localizable", "change_password") }
  /// Password Changed
  internal static var changePasswordConf: String { return L10n.tr("Localizable", "change_password_conf") }
  /// Unable to change password. Invalid password.
  internal static var changePasswordError: String { return L10n.tr("Localizable", "change_password_error") }
  /// Passwords do not match
  internal static var changePasswordErrorMismatch: String { return L10n.tr("Localizable", "change_password_error_mismatch") }
  /// Must be at least 6 characters
  internal static var changePasswordLengthError: String { return L10n.tr("Localizable", "change_password_length_error") }
  /// Chapters
  internal static var chapters: String { return L10n.tr("Localizable", "chapters") }
  /// %1$@ Podcasts Chosen
  internal static func chosenPodcastsPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "chosen_podcasts_plural_format", String(describing: p1))
  }
  /// 1 Podcast Chosen
  internal static var chosenPodcastsSingular: String { return L10n.tr("Localizable", "chosen_podcasts_singular") }
  /// Cast to
  internal static var chromecastCastTo: String { return L10n.tr("Localizable", "chromecast_cast_to") }
  /// Connected
  internal static var chromecastConnected: String { return L10n.tr("Localizable", "chromecast_connected") }
  /// Connected to device
  internal static var chromecastConnectedToDevice: String { return L10n.tr("Localizable", "chromecast_connected_to_device") }
  /// Unable to cast local file
  internal static var chromecastError: String { return L10n.tr("Localizable", "chromecast_error") }
  /// Nothing is playing
  internal static var chromecastNothingPlaying: String { return L10n.tr("Localizable", "chromecast_nothing_playing") }
  /// Un-named device
  internal static var chromecastUnnamedDevice: String { return L10n.tr("Localizable", "chromecast_unnamed_device") }
  /// Clean Up
  internal static var cleanUp: String { return L10n.tr("Localizable", "clean_up") }
  /// Clear
  internal static var clear: String { return L10n.tr("Localizable", "clear") }
  /// Clear Search
  internal static var clearSearch: String { return L10n.tr("Localizable", "clear_search") }
  /// Clear Up Next
  internal static var clearUpNext: String { return L10n.tr("Localizable", "clear_up_next") }
  /// Are you sure you want to clear your Up Next queue?
  internal static var clearUpNextMessage: String { return L10n.tr("Localizable", "clear_up_next_message") }
  /// Token authentication failed.
  internal static var clientErrorTokenDeauth: String { return L10n.tr("Localizable", "client_error_token_deauth") }
  /// Close
  internal static var close: String { return L10n.tr("Localizable", "close") }
  /// Color
  internal static var color: String { return L10n.tr("Localizable", "color") }
  /// Confirm
  internal static var confirm: String { return L10n.tr("Localizable", "confirm") }
  /// Confirm New Password
  internal static var confirmNewPasswordPrompt: String { return L10n.tr("Localizable", "confirm_new_password_prompt") }
  /// Continue
  internal static var `continue`: String { return L10n.tr("Localizable", "continue") }
  /// Copy
  internal static var copy: String { return L10n.tr("Localizable", "copy") }
  /// Create Account
  internal static var createAccount: String { return L10n.tr("Localizable", "create_account") }
  /// Pocket Casts is having trouble connecting to the App Store. Please check your connection and try again.
  internal static var createAccountAppStoreErrorMessage: String { return L10n.tr("Localizable", "create_account_app_store_error_message") }
  /// Unable to contact App Store
  internal static var createAccountAppStoreErrorTitle: String { return L10n.tr("Localizable", "create_account_app_store_error_title") }
  /// Find out more about Pocket Casts Plus
  internal static var createAccountFindOutMorePlus: String { return L10n.tr("Localizable", "create_account_find_out_more_plus") }
  /// Regular
  internal static var createAccountFreeAccountType: String { return L10n.tr("Localizable", "create_account_free_account_type") }
  /// Almost everything
  internal static var createAccountFreeDetails: String { return L10n.tr("Localizable", "create_account_free_details") }
  /// Free
  internal static var createAccountFreePrice: String { return L10n.tr("Localizable", "create_account_free_price") }
  /// Everything unlocked
  internal static var createAccountPlusDetails: String { return L10n.tr("Localizable", "create_account_plus_details") }
  /// Create Filter
  internal static var createFilter: String { return L10n.tr("Localizable", "create_filter") }
  /// Current Email
  internal static var currentEmailPrompt: String { return L10n.tr("Localizable", "current_email_prompt") }
  /// Current Password
  internal static var currentPasswordPrompt: String { return L10n.tr("Localizable", "current_password_prompt") }
  /// Custom Episode
  internal static var customEpisode: String { return L10n.tr("Localizable", "custom_episode") }
  /// Cancel Upload
  internal static var customEpisodeCancelUpload: String { return L10n.tr("Localizable", "custom_episode_cancel_upload") }
  /// Remove from Cloud
  internal static var customEpisodeRemoveUpload: String { return L10n.tr("Localizable", "custom_episode_remove_upload") }
  /// Upload to Cloud
  internal static var customEpisodeUpload: String { return L10n.tr("Localizable", "custom_episode_upload") }
  /// Day listened
  internal static var dayListened: String { return L10n.tr("Localizable", "day_listened") }
  /// Day saved
  internal static var daySaved: String { return L10n.tr("Localizable", "day_saved") }
  /// Days listened
  internal static var daysListened: String { return L10n.tr("Localizable", "days_listened") }
  /// Days saved
  internal static var daysSaved: String { return L10n.tr("Localizable", "days_saved") }
  /// Delete
  internal static var delete: String { return L10n.tr("Localizable", "delete") }
  /// Delete Download
  internal static var deleteDownload: String { return L10n.tr("Localizable", "delete_download") }
  /// Delete From Everywhere
  internal static var deleteEverywhere: String { return L10n.tr("Localizable", "delete_everywhere") }
  /// Delete Everywhere
  internal static var deleteEverywhereShort: String { return L10n.tr("Localizable", "delete_everywhere_short") }
  /// Delete File
  internal static var deleteFile: String { return L10n.tr("Localizable", "delete_file") }
  /// Are you sure you want to delete this file?
  internal static var deleteFileMessage: String { return L10n.tr("Localizable", "delete_file_message") }
  /// Delete From Cloud
  internal static var deleteFromCloud: String { return L10n.tr("Localizable", "delete_from_cloud") }
  /// Delete From Device
  internal static var deleteFromDevice: String { return L10n.tr("Localizable", "delete_from_device") }
  /// Delete From Device Only
  internal static var deleteFromDeviceOnly: String { return L10n.tr("Localizable", "delete_from_device_only") }
  /// Deselect All
  internal static var deselectAll: String { return L10n.tr("Localizable", "deselect_all") }
  /// Discover
  internal static var discover: String { return L10n.tr("Localizable", "discover") }
  /// All Episodes
  internal static var discoverAllEpisodes: String { return L10n.tr("Localizable", "discover_all_episodes") }
  /// All Podcasts
  internal static var discoverAllPodcasts: String { return L10n.tr("Localizable", "discover_all_podcasts") }
  /// Browse By Category
  internal static var discoverBrowseByCategory: String { return L10n.tr("Localizable", "discover_browse_by_category") }
  /// Arts
  internal static var discoverBrowseByCategoryArt: String { return L10n.tr("Localizable", "discover_browse_by_category_art") }
  /// Business
  internal static var discoverBrowseByCategoryBusiness: String { return L10n.tr("Localizable", "discover_browse_by_category_business") }
  /// Comedy
  internal static var discoverBrowseByCategoryComedy: String { return L10n.tr("Localizable", "discover_browse_by_category_comedy") }
  /// Education
  internal static var discoverBrowseByCategoryEducation: String { return L10n.tr("Localizable", "discover_browse_by_category_education") }
  /// Family
  internal static var discoverBrowseByCategoryFamily: String { return L10n.tr("Localizable", "discover_browse_by_category_family") }
  /// Fiction
  internal static var discoverBrowseByCategoryFiction: String { return L10n.tr("Localizable", "discover_browse_by_category_fiction") }
  /// Games & Hobbies
  internal static var discoverBrowseByCategoryGamesAndHobbies: String { return L10n.tr("Localizable", "discover_browse_by_category_games_and_hobbies") }
  /// Government
  internal static var discoverBrowseByCategoryGovernment: String { return L10n.tr("Localizable", "discover_browse_by_category_government") }
  /// Government & Organizations
  internal static var discoverBrowseByCategoryGovernmentAndOrganizations: String { return L10n.tr("Localizable", "discover_browse_by_category_government_and_organizations") }
  /// Health
  internal static var discoverBrowseByCategoryHealth: String { return L10n.tr("Localizable", "discover_browse_by_category_health") }
  /// Health & Fitness
  internal static var discoverBrowseByCategoryHealthAndFitness: String { return L10n.tr("Localizable", "discover_browse_by_category_health_and_fitness") }
  /// History
  internal static var discoverBrowseByCategoryHistory: String { return L10n.tr("Localizable", "discover_browse_by_category_history") }
  /// Kids & Family
  internal static var discoverBrowseByCategoryKidsAndFamily: String { return L10n.tr("Localizable", "discover_browse_by_category_kids_and_family") }
  /// Leisure
  internal static var discoverBrowseByCategoryLeisure: String { return L10n.tr("Localizable", "discover_browse_by_category_leisure") }
  /// Music
  internal static var discoverBrowseByCategoryMusic: String { return L10n.tr("Localizable", "discover_browse_by_category_music") }
  /// News
  internal static var discoverBrowseByCategoryNews: String { return L10n.tr("Localizable", "discover_browse_by_category_news") }
  /// News & Politics
  internal static var discoverBrowseByCategoryNewsAndPolitics: String { return L10n.tr("Localizable", "discover_browse_by_category_news_and_politics") }
  /// Religion & Spirituality
  internal static var discoverBrowseByCategoryReligionAndSpirituality: String { return L10n.tr("Localizable", "discover_browse_by_category_religion_and_spirituality") }
  /// Science
  internal static var discoverBrowseByCategoryScience: String { return L10n.tr("Localizable", "discover_browse_by_category_science") }
  /// Science & Medicine
  internal static var discoverBrowseByCategoryScienceAndMedicine: String { return L10n.tr("Localizable", "discover_browse_by_category_science_and_medicine") }
  /// Society
  internal static var discoverBrowseByCategorySociety: String { return L10n.tr("Localizable", "discover_browse_by_category_society") }
  /// Culture
  internal static var discoverBrowseByCategorySocietyAndCulture: String { return L10n.tr("Localizable", "discover_browse_by_category_society_and_culture") }
  /// Spirituality
  internal static var discoverBrowseByCategorySpirituality: String { return L10n.tr("Localizable", "discover_browse_by_category_spirituality") }
  /// Sports
  internal static var discoverBrowseByCategorySports: String { return L10n.tr("Localizable", "discover_browse_by_category_sports") }
  /// Sports & Recreation
  internal static var discoverBrowseByCategorySportsAndRecreation: String { return L10n.tr("Localizable", "discover_browse_by_category_sports_and_recreation") }
  /// Technology
  internal static var discoverBrowseByCategoryTechnology: String { return L10n.tr("Localizable", "discover_browse_by_category_technology") }
  /// True Crime
  internal static var discoverBrowseByCategoryTrueCrime: String { return L10n.tr("Localizable", "discover_browse_by_category_true_crime") }
  /// TV & Film
  internal static var discoverBrowseByCategoryTvAndFilm: String { return L10n.tr("Localizable", "discover_browse_by_category_tv_and_film") }
  /// Change Region, currently %1$@
  internal static func discoverChangeRegion(_ p1: Any) -> String {
    return L10n.tr("Localizable", "discover_change_region", String(describing: p1))
  }
  /// The episode couldn't be loaded
  internal static var discoverEpisodeFailToLoad: String { return L10n.tr("Localizable", "discover_episode_fail_to_load") }
  /// Featured
  internal static var discoverFeatured: String { return L10n.tr("Localizable", "discover_featured") }
  /// FEATURED EPISODE
  internal static var discoverFeaturedEpisode: String { return L10n.tr("Localizable", "discover_featured_episode") }
  /// Featured podcast or episode not found. Make sure you are connected to the internet and try again.
  internal static var discoverFeaturedEpisodeErrorNotFound: String { return L10n.tr("Localizable", "discover_featured_episode_error_not_found") }
  /// FRESH PICK
  internal static var discoverFreshPick: String { return L10n.tr("Localizable", "discover_fresh_pick") }
  /// No episodes found
  internal static var discoverNoEpisodesFound: String { return L10n.tr("Localizable", "discover_no_episodes_found") }
  /// No podcasts found
  internal static var discoverNoPodcastsFound: String { return L10n.tr("Localizable", "discover_no_podcasts_found") }
  /// Try more general or different keywords.
  internal static var discoverNoPodcastsFoundMsg: String { return L10n.tr("Localizable", "discover_no_podcasts_found_msg") }
  /// Play Episode
  internal static var discoverPlayEpisode: String { return L10n.tr("Localizable", "discover_play_episode") }
  /// Play Trailer
  internal static var discoverPlayTrailer: String { return L10n.tr("Localizable", "discover_play_trailer") }
  /// %1$@ Network
  internal static func discoverPodcastNetwork(_ p1: Any) -> String {
    return L10n.tr("Localizable", "discover_podcast_network", String(describing: p1))
  }
  /// Popular
  internal static var discoverPopular: String { return L10n.tr("Localizable", "discover_popular") }
  /// Popular in %1$@
  internal static func discoverPopularIn(_ p1: Any) -> String {
    return L10n.tr("Localizable", "discover_popular_in", String(describing: p1))
  }
  /// Australia
  internal static var discoverRegionAustralia: String { return L10n.tr("Localizable", "discover_region_australia") }
  /// Austria
  internal static var discoverRegionAustria: String { return L10n.tr("Localizable", "discover_region_austria") }
  /// Belgium
  internal static var discoverRegionBelgium: String { return L10n.tr("Localizable", "discover_region_belgium") }
  /// Brazil
  internal static var discoverRegionBrazil: String { return L10n.tr("Localizable", "discover_region_brazil") }
  /// Canada
  internal static var discoverRegionCanada: String { return L10n.tr("Localizable", "discover_region_canada") }
  /// China
  internal static var discoverRegionChina: String { return L10n.tr("Localizable", "discover_region_china") }
  /// Czechia
  internal static var discoverRegionCzechia: String { return L10n.tr("Localizable", "discover_region_czechia") }
  /// Denmark
  internal static var discoverRegionDenmark: String { return L10n.tr("Localizable", "discover_region_denmark") }
  /// Finland
  internal static var discoverRegionFinland: String { return L10n.tr("Localizable", "discover_region_finland") }
  /// France
  internal static var discoverRegionFrance: String { return L10n.tr("Localizable", "discover_region_france") }
  /// Germany
  internal static var discoverRegionGermany: String { return L10n.tr("Localizable", "discover_region_germany") }
  /// Hong Kong
  internal static var discoverRegionHongKong: String { return L10n.tr("Localizable", "discover_region_hong_kong") }
  /// India
  internal static var discoverRegionIndia: String { return L10n.tr("Localizable", "discover_region_india") }
  /// Ireland
  internal static var discoverRegionIreland: String { return L10n.tr("Localizable", "discover_region_ireland") }
  /// Israel
  internal static var discoverRegionIsrael: String { return L10n.tr("Localizable", "discover_region_israel") }
  /// Italy
  internal static var discoverRegionItaly: String { return L10n.tr("Localizable", "discover_region_italy") }
  /// Japan
  internal static var discoverRegionJapan: String { return L10n.tr("Localizable", "discover_region_japan") }
  /// Mexico
  internal static var discoverRegionMexico: String { return L10n.tr("Localizable", "discover_region_mexico") }
  /// Netherlands
  internal static var discoverRegionNetherlands: String { return L10n.tr("Localizable", "discover_region_netherlands") }
  /// New Zealand
  internal static var discoverRegionNewZealand: String { return L10n.tr("Localizable", "discover_region_new_zealand") }
  /// Norway
  internal static var discoverRegionNorway: String { return L10n.tr("Localizable", "discover_region_norway") }
  /// Philippines
  internal static var discoverRegionPhilippines: String { return L10n.tr("Localizable", "discover_region_philippines") }
  /// Poland
  internal static var discoverRegionPoland: String { return L10n.tr("Localizable", "discover_region_poland") }
  /// Portugal
  internal static var discoverRegionPortugal: String { return L10n.tr("Localizable", "discover_region_portugal") }
  /// Russia
  internal static var discoverRegionRussia: String { return L10n.tr("Localizable", "discover_region_russia") }
  /// Saudi Arabia
  internal static var discoverRegionSaudiArabia: String { return L10n.tr("Localizable", "discover_region_saudi_arabia") }
  /// Singapore
  internal static var discoverRegionSingapore: String { return L10n.tr("Localizable", "discover_region_singapore") }
  /// South Africa
  internal static var discoverRegionSouthAfrica: String { return L10n.tr("Localizable", "discover_region_south_africa") }
  /// South Korea
  internal static var discoverRegionSouthKorea: String { return L10n.tr("Localizable", "discover_region_south_korea") }
  /// Spain
  internal static var discoverRegionSpain: String { return L10n.tr("Localizable", "discover_region_spain") }
  /// Sweden
  internal static var discoverRegionSweden: String { return L10n.tr("Localizable", "discover_region_sweden") }
  /// Switzerland
  internal static var discoverRegionSwitzerland: String { return L10n.tr("Localizable", "discover_region_switzerland") }
  /// Taiwan
  internal static var discoverRegionTaiwan: String { return L10n.tr("Localizable", "discover_region_taiwan") }
  /// Turkey
  internal static var discoverRegionTurkey: String { return L10n.tr("Localizable", "discover_region_turkey") }
  /// Ukraine
  internal static var discoverRegionUkraine: String { return L10n.tr("Localizable", "discover_region_ukraine") }
  /// United Kingdom
  internal static var discoverRegionUnitedKingdom: String { return L10n.tr("Localizable", "discover_region_united_kingdom") }
  /// United States
  internal static var discoverRegionUnitedStates: String { return L10n.tr("Localizable", "discover_region_united_states") }
  /// Worldwide
  internal static var discoverRegionWorldwide: String { return L10n.tr("Localizable", "discover_region_worldwide") }
  /// Please enter at least 2 characters.
  internal static var discoverSearchErrorMsg: String { return L10n.tr("Localizable", "discover_search_error_msg") }
  /// Length Challenged
  internal static var discoverSearchErrorTitle: String { return L10n.tr("Localizable", "discover_search_error_title") }
  /// Search Failed
  internal static var discoverSearchFailed: String { return L10n.tr("Localizable", "discover_search_failed") }
  /// Check your Internet connection.
  internal static var discoverSearchFailedMsg: String { return L10n.tr("Localizable", "discover_search_failed_msg") }
  /// Select Content Region
  internal static var discoverSelectRegion: String { return L10n.tr("Localizable", "discover_select_region") }
  /// SHOW ALL
  internal static var discoverShowAll: String { return L10n.tr("Localizable", "discover_show_all") }
  /// SPONSORED
  internal static var discoverSponsored: String { return L10n.tr("Localizable", "discover_sponsored") }
  /// Trending
  internal static var discoverTrending: String { return L10n.tr("Localizable", "discover_trending") }
  /// Done
  internal static var done: String { return L10n.tr("Localizable", "done") }
  /// Download
  internal static var download: String { return L10n.tr("Localizable", "download") }
  /// Download All
  internal static var downloadAll: String { return L10n.tr("Localizable", "download_all") }
  /// Downloading will use data.
  internal static var downloadDataWarning: String { return L10n.tr("Localizable", "download_data_warning") }
  /// Download %1$@ Episodes
  internal static func downloadEpisodePluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "download_episode_plural_format", String(describing: p1))
  }
  /// Download 1 Episode
  internal static var downloadEpisodeSingular: String { return L10n.tr("Localizable", "download_episode_singular") }
  /// Episode not available due to an error in the podcast feed. Contact the podcast author.
  internal static var downloadErrorContactAuthor: String { return L10n.tr("Localizable", "download_error_contact_author") }
  /// This episode may have been moved or deleted. Contact the podcast author.
  internal static var downloadErrorContactAuthorVersion2: String { return L10n.tr("Localizable", "download_error_contact_author_version_2") }
  /// Unable to save episode, have you run out of space?
  internal static var downloadErrorNotEnoughSpace: String { return L10n.tr("Localizable", "download_error_not_enough_space") }
  /// File not uploaded, unable to play
  internal static var downloadErrorNotUploaded: String { return L10n.tr("Localizable", "download_error_not_uploaded") }
  /// Download failed, error code %1$@. Contact the podcast author.
  internal static func downloadErrorStatusCode(_ p1: Any) -> String {
    return L10n.tr("Localizable", "download_error_status_code", String(describing: p1))
  }
  /// Unable to download episode. Please try again later.
  internal static var downloadErrorTryAgain: String { return L10n.tr("Localizable", "download_error_try_again") }
  /// Download Failed
  internal static var downloadFailed: String { return L10n.tr("Localizable", "download_failed") }
  /// Downloaded Files
  internal static var downloadedFiles: String { return L10n.tr("Localizable", "downloaded_files") }
  /// Are you sure you want to delete these downloaded files?
  internal static var downloadedFilesCleanupConfirmation: String { return L10n.tr("Localizable", "downloaded_files_cleanup_confirmation") }
  /// Unsubscribing will delete all downloaded files in this Podcast, are you sure?
  internal static var downloadedFilesConfMessage: String { return L10n.tr("Localizable", "downloaded_files_conf_message") }
  /// %1$@ Downloaded Files
  internal static func downloadedFilesConfPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "downloaded_files_conf_plural_format", String(describing: p1))
  }
  /// 1 Downloaded File
  internal static var downloadedFilesConfSingular: String { return L10n.tr("Localizable", "downloaded_files_conf_singular") }
  /// Downloads
  internal static var downloads: String { return L10n.tr("Localizable", "downloads") }
  /// Auto Download Settings
  internal static var downloadsAutoDownload: String { return L10n.tr("Localizable", "downloads_auto_download") }
  /// Oh no! You’re fresh out of downloads. Download some more and they’ll show up here.
  internal static var downloadsNoDownloadsDesc: String { return L10n.tr("Localizable", "downloads_no_downloads_desc") }
  /// No Downloaded Episodes
  internal static var downloadsNoDownloadsTitle: String { return L10n.tr("Localizable", "downloads_no_downloads_title") }
  /// Retry Failed Downloads
  internal static var downloadsRetryFailedDownloads: String { return L10n.tr("Localizable", "downloads_retry_failed_downloads") }
  /// Stop All Downloads
  internal static var downloadsStopAllDownloads: String { return L10n.tr("Localizable", "downloads_stop_all_downloads") }
  /// Edit
  internal static var edit: String { return L10n.tr("Localizable", "edit") }
  /// Enable it now
  internal static var enableItNow: String { return L10n.tr("Localizable", "enable_it_now") }
  /// See your listening stats, top podcasts, and more.
  internal static var eoyCardDescription: String { return L10n.tr("Localizable", "eoy_card_description") }
  /// Save your podcasts in the cloud, get your end of year review and sync your progress with other devices.
  internal static var eoyCreateAccountToSee: String { return L10n.tr("Localizable", "eoy_create_account_to_see") }
  /// See your top podcasts, categories, listening stats, and more. Share with friends and shout out your favorite creators!
  internal static var eoyDescription: String { return L10n.tr("Localizable", "eoy_description") }
  /// Not Now
  internal static var eoyNotNow: String { return L10n.tr("Localizable", "eoy_not_now") }
  /// Share this story
  internal static var eoyShare: String { return L10n.tr("Localizable", "eoy_share") }
  /// Paste this image to your socials and give a shout out to your favorite shows and creators
  internal static var eoyShareThisStoryMessage: String { return L10n.tr("Localizable", "eoy_share_this_story_message") }
  /// Share this story?
  internal static var eoyShareThisStoryTitle: String { return L10n.tr("Localizable", "eoy_share_this_story_title") }
  /// Year in Podcasts
  internal static var eoySmallTitle: String { return L10n.tr("Localizable", "eoy_small_title") }
  /// Start your Free Trial
  internal static var eoyStartYourFreeTrial: String { return L10n.tr("Localizable", "eoy_start_your_free_trial") }
  /// Failed to load stories.
  internal static var eoyStoriesFailed: String { return L10n.tr("Localizable", "eoy_stories_failed") }
  /// Don't forget to share with your friends and give a shout out to your favorite podcast creators
  internal static var eoyStoryEpilogueSubtitle: String { return L10n.tr("Localizable", "eoy_story_epilogue_subtitle") }
  /// Thank you for listening with us this year.
  /// See you in 2024!
  internal static var eoyStoryEpilogueTitle: String { return L10n.tr("Localizable", "eoy_story_epilogue_title") }
  /// Let's celebrate your year of listening...
  internal static var eoyStoryIntroTitle: String { return L10n.tr("Localizable", "eoy_story_intro_title") }
  /// In 2022, you spent %1$@ listening to podcasts
  internal static func eoyStoryListenedTo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_listened_to", String(describing: p1))
  }
  /// You listened to %1$@ different categories this year
  internal static func eoyStoryListenedToCategories(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_listened_to_categories", String(describing: p1))
  }
  /// You listened to %1$@ this year
  internal static func eoyStoryListenedToCategoriesHighlighted(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_listened_to_categories_highlighted", String(describing: p1))
  }
  /// I listened to %1$@ different categories in 2023
  internal static func eoyStoryListenedToCategoriesShareText(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_listened_to_categories_share_text", String(describing: p1))
  }
  /// Let's take a look at some of your favorites...
  internal static var eoyStoryListenedToCategoriesSubtitle: String { return L10n.tr("Localizable", "eoy_story_listened_to_categories_subtitle") }
  /// %1$@ different categories
  internal static func eoyStoryListenedToCategoriesText(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_listened_to_categories_text", String(describing: p1))
  }
  /// %1$@ episodes
  internal static func eoyStoryListenedToEpisodesText(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_listened_to_episodes_text", String(describing: p1))
  }
  /// You listened to %1$@ different shows and %2$@ episodes in total
  internal static func eoyStoryListenedToNumbers(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_listened_to_numbers", String(describing: p1), String(describing: p2))
  }
  /// I listened to %1$@ different podcasts and %2$@ episodes this year
  internal static func eoyStoryListenedToNumbersShareText(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_listened_to_numbers_share_text", String(describing: p1), String(describing: p2))
  }
  /// But there was one you kept coming to...
  internal static var eoyStoryListenedToNumbersSubtitle: String { return L10n.tr("Localizable", "eoy_story_listened_to_numbers_subtitle") }
  /// You listened to %1$@ and %2$@
  internal static func eoyStoryListenedToNumbersUpdated(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_listened_to_numbers_updated", String(describing: p1), String(describing: p2))
  }
  /// %1$@ different podcasts
  internal static func eoyStoryListenedToPodcastText(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_listened_to_podcast_text", String(describing: p1))
  }
  /// I spent %1$@ listening to podcasts this year
  internal static func eoyStoryListenedToShareText(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_listened_to_share_text", String(describing: p1))
  }
  /// We hope you loved every minute of it!
  internal static var eoyStoryListenedToSubtitle: String { return L10n.tr("Localizable", "eoy_story_listened_to_subtitle") }
  /// This was your total time listening to podcasts
  internal static var eoyStoryListenedToTitle: String { return L10n.tr("Localizable", "eoy_story_listened_to_title") }
  /// This year, you spent %1$@ listening to podcasts
  internal static func eoyStoryListenedToUpdated(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_listened_to_updated", String(describing: p1))
  }
  /// The longest episode you listened to was %1$@
  internal static func eoyStoryLongestEpisode(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_longest_episode", String(describing: p1))
  }
  /// This episode was %1$@ long
  internal static func eoyStoryLongestEpisodeDuration(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_longest_episode_duration", String(describing: p1))
  }
  /// The longest episode I listened to this year %1$@
  internal static func eoyStoryLongestEpisodeShareText(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_longest_episode_share_text", String(describing: p1))
  }
  /// It was none other than “%1$@” from “%2$@”
  internal static func eoyStoryLongestEpisodeSubtitle(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_longest_episode_subtitle", String(describing: p1), String(describing: p2))
  }
  /// The longest episode
  /// you listened to was
  /// %1$@
  internal static func eoyStoryLongestEpisodeTime(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_longest_episode_time", String(describing: p1))
  }
  /// Play again
  internal static var eoyStoryReplay: String { return L10n.tr("Localizable", "eoy_story_replay") }
  /// Your Top Categories
  internal static var eoyStoryTopCategories: String { return L10n.tr("Localizable", "eoy_story_top_categories") }
  /// My most listened to podcast categories
  internal static var eoyStoryTopCategoriesShareText: String { return L10n.tr("Localizable", "eoy_story_top_categories_share_text") }
  /// You listened to %1$@ episodes for a total of %2$@
  internal static func eoyStoryTopCategoriesSubtitle(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_top_categories_subtitle", String(describing: p1), String(describing: p2))
  }
  /// Did you know that %1$@ was your favorite category?
  internal static func eoyStoryTopCategoriesTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_top_categories_title", String(describing: p1))
  }
  /// %1$@ was your most listened show in 2023
  internal static func eoyStoryTopPodcast(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_top_podcast", String(describing: p1))
  }
  /// My favorite podcast this year! %1$@
  internal static func eoyStoryTopPodcastShareText(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_top_podcast_share_text", String(describing: p1))
  }
  /// You listened to %1$@ episodes for a total of %2$@
  internal static func eoyStoryTopPodcastSubtitle(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_top_podcast_subtitle", String(describing: p1), String(describing: p2))
  }
  /// Your Top Podcasts
  internal static var eoyStoryTopPodcasts: String { return L10n.tr("Localizable", "eoy_story_top_podcasts") }
  /// My top podcasts of the year!
  internal static var eoyStoryTopPodcastsListTitle: String { return L10n.tr("Localizable", "eoy_story_top_podcasts_list_title") }
  /// My top podcasts of the year! %1$@
  internal static func eoyStoryTopPodcastsShareText(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_story_top_podcasts_share_text", String(describing: p1))
  }
  /// This is your top 5 most listened to in 2023
  internal static var eoyStoryTopPodcastsSubtitle: String { return L10n.tr("Localizable", "eoy_story_top_podcasts_subtitle") }
  /// And you were big on these shows too!
  internal static var eoyStoryTopPodcastsTitle: String { return L10n.tr("Localizable", "eoy_story_top_podcasts_title") }
  /// Subscribe to Plus and find out how your listening compares to 2022, other fun stats, and Premium features like bookmarks and folders.
  internal static var eoySubscribeToPlus: String { return L10n.tr("Localizable", "eoy_subscribe_to_plus") }
  /// There’s more!
  internal static var eoyTheresMore: String { return L10n.tr("Localizable", "eoy_theres_more") }
  /// Your Year in Podcasts
  internal static var eoyTitle: String { return L10n.tr("Localizable", "eoy_title") }
  /// View My 2023
  internal static var eoyViewYear: String { return L10n.tr("Localizable", "eoy_view_year") }
  /// completion rate
  internal static var eoyYearCompletionRate: String { return L10n.tr("Localizable", "eoy_year_completion_rate") }
  /// My 2023 completion rate
  internal static var eoyYearCompletionRateShareText: String { return L10n.tr("Localizable", "eoy_year_completion_rate_share_text") }
  /// From the %1$@ episodes you started you listened fully to a total of %2$@
  internal static func eoyYearCompletionRateSubtitle(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "eoy_year_completion_rate_subtitle", String(describing: p1), String(describing: p2))
  }
  /// Your completion rate this year was %1$@
  internal static func eoyYearCompletionRateTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_year_completion_rate_title", String(describing: p1))
  }
  /// My 2023 listening time compared to 2022
  internal static var eoyYearOverShareText: String { return L10n.tr("Localizable", "eoy_year_over_share_text") }
  /// And they say consistency is the key to success... or something like that!
  internal static var eoyYearOverYearSubtitleFlat: String { return L10n.tr("Localizable", "eoy_year_over_year_subtitle_flat") }
  /// Aaaah... there’s a life to be lived, right?
  internal static var eoyYearOverYearSubtitleWentDown: String { return L10n.tr("Localizable", "eoy_year_over_year_subtitle_went_down") }
  /// Ready to top it in 2024?
  internal static var eoyYearOverYearSubtitleWentUp: String { return L10n.tr("Localizable", "eoy_year_over_year_subtitle_went_up") }
  /// Compared to 2022, your listening time stayed pretty consistent
  internal static var eoyYearOverYearTitleFlat: String { return L10n.tr("Localizable", "eoy_year_over_year_title_flat") }
  /// Compared to 2022, your listening time skyrocketed!
  internal static var eoyYearOverYearTitleSkyrocketed: String { return L10n.tr("Localizable", "eoy_year_over_year_title_skyrocketed") }
  /// Compared to 2022, your listening time went down a little
  internal static var eoyYearOverYearTitleWentDown: String { return L10n.tr("Localizable", "eoy_year_over_year_title_went_down") }
  /// Compared to 2022, your listening time went up a whopping %1$@%
  internal static func eoyYearOverYearTitleWentUp(_ p1: Any) -> String {
    return L10n.tr("Localizable", "eoy_year_over_year_title_went_up", String(describing: p1))
  }
  /// Episode
  internal static var episode: String { return L10n.tr("Localizable", "episode") }
  /// %1$@ episodes
  internal static func episodeCountPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "episode_count_plural_format", String(describing: p1))
  }
  /// Details
  internal static var episodeDetailsTitle: String { return L10n.tr("Localizable", "episode_details_title") }
  /// Filter by duration
  internal static var episodeFilterByDurationLabel: String { return L10n.tr("Localizable", "episode_filter_by_duration_label") }
  /// Either it's time to celebrate completing this list, or edit your filter settings to get some more.
  internal static var episodeFilterNoEpisodesMsg: String { return L10n.tr("Localizable", "episode_filter_no_episodes_msg") }
  /// No Episodes
  internal static var episodeFilterNoEpisodesTitle: String { return L10n.tr("Localizable", "episode_filter_no_episodes_title") }
  /// Bonus
  internal static var episodeIndicatorBonus: String { return L10n.tr("Localizable", "episode_indicator_bonus") }
  /// Season %1$@ Trailer
  internal static func episodeIndicatorSeasonTrailer(_ p1: Any) -> String {
    return L10n.tr("Localizable", "episode_indicator_season_trailer", String(describing: p1))
  }
  /// Trailer
  internal static var episodeIndicatorTrailer: String { return L10n.tr("Localizable", "episode_indicator_trailer") }
  /// EPISODE %1$@
  internal static func episodeShorthandFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "episode_shorthand_format", String(describing: p1))
  }
  /// EP %1$@
  internal static func episodeShorthandFormatShort(_ p1: Any) -> String {
    return L10n.tr("Localizable", "episode_shorthand_format_short", String(describing: p1))
  }
  /// Episodes
  internal static var episodes: String { return L10n.tr("Localizable", "episodes") }
  /// Error
  internal static var error: String { return L10n.tr("Localizable", "error") }
  /// Unable to find podcast. Please contact the podcast author.
  internal static var errorGeneralPodcastNotFound: String { return L10n.tr("Localizable", "error_general_podcast_not_found") }
  /// Export Database
  internal static var exportDatabase: String { return L10n.tr("Localizable", "export_database") }
  /// Exports all your podcasts as an OPML file, which you can import into other podcast apps.
  internal static var exportPodcastsDescription: String { return L10n.tr("Localizable", "export_podcasts_description") }
  /// Export Podcasts
  internal static var exportPodcastsOption: String { return L10n.tr("Localizable", "export_podcasts_option") }
  /// EXPORT
  internal static var exportPodcastsTitle: String { return L10n.tr("Localizable", "export_podcasts_title") }
  /// Exporting Database...
  internal static var exportingDatabase: String { return L10n.tr("Localizable", "exporting_database") }
  /// End Tour
  internal static var featureTourEndTour: String { return L10n.tr("Localizable", "feature_tour_end_tour") }
  /// NEW
  internal static var featureTourNew: String { return L10n.tr("Localizable", "feature_tour_new") }
  /// %1$@ of %2$@
  internal static func featureTourStepFormat(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "feature_tour_step_format", String(describing: p1), String(describing: p2))
  }
  /// Open Default Mail App
  internal static var feedbackContinueWithMail: String { return L10n.tr("Localizable", "feedback_continue_with_mail") }
  /// To send a debug attachment, the Apple Mail app has to be configured on your phone. What would you like to do?
  internal static var feedbackMailNotConfiguredMsg: String { return L10n.tr("Localizable", "feedback_mail_not_configured_msg") }
  /// Mail Not Configured
  internal static var feedbackMailNotConfiguredTitle: String { return L10n.tr("Localizable", "feedback_mail_not_configured_title") }
  /// Add File
  internal static var fileUploadAddFile: String { return L10n.tr("Localizable", "file_upload_add_file") }
  /// Add Custom Image
  internal static var fileUploadAddImage: String { return L10n.tr("Localizable", "file_upload_add_image") }
  /// Choose Image
  internal static var fileUploadChooseImage: String { return L10n.tr("Localizable", "file_upload_choose_image") }
  /// Camera
  internal static var fileUploadChooseImageCamera: String { return L10n.tr("Localizable", "file_upload_choose_image_camera") }
  /// Photo Library
  internal static var fileUploadChooseImagePhotoLibrary: String { return L10n.tr("Localizable", "file_upload_choose_image_photo_Library") }
  /// Edit File
  internal static var fileUploadEditFile: String { return L10n.tr("Localizable", "file_upload_edit_file") }
  /// Not enough space to upload this file.
  internal static var fileUploadError: String { return L10n.tr("Localizable", "file_upload_error") }
  /// Remove some files and try again.
  internal static var fileUploadErrorSubtitle: String { return L10n.tr("Localizable", "file_upload_error_subtitle") }
  /// Name required
  internal static var fileUploadNameRequired: String { return L10n.tr("Localizable", "file_upload_name_required") }
  /// Want to listen to your own files?
  /// Share them with Pocket Casts, and they’ll appear here
  internal static var fileUploadNoFilesDescription: String { return L10n.tr("Localizable", "file_upload_no_files_description") }
  /// How do I do that?
  internal static var fileUploadNoFilesHelper: String { return L10n.tr("Localizable", "file_upload_no_files_helper") }
  /// No Files
  internal static var fileUploadNoFilesTitle: String { return L10n.tr("Localizable", "file_upload_no_files_title") }
  /// Remove Image
  internal static var fileUploadRemoveImage: String { return L10n.tr("Localizable", "file_upload_remove_image") }
  /// Save
  internal static var fileUploadSave: String { return L10n.tr("Localizable", "file_upload_save") }
  /// This file type is not supported
  internal static var fileUploadSupportError: String { return L10n.tr("Localizable", "file_upload_support_error") }
  /// Files
  internal static var files: String { return L10n.tr("Localizable", "files") }
  /// How to save a file
  internal static var filesHowToTitle: String { return L10n.tr("Localizable", "files_how_to_title") }
  /// Sort Files
  internal static var filesSort: String { return L10n.tr("Localizable", "files_sort") }
  /// New podcasts you subscribe to will be automatically added
  internal static var filterAutoAddSubtitle: String { return L10n.tr("Localizable", "filter_auto_add_subtitle") }
  /// All Your Podcasts
  internal static var filterChipsAllPodcasts: String { return L10n.tr("Localizable", "filter_chips_all_podcasts") }
  /// Duration
  internal static var filterChipsDuration: String { return L10n.tr("Localizable", "filter_chips_duration") }
  /// Choose Podcasts
  internal static var filterChoosePodcasts: String { return L10n.tr("Localizable", "filter_choose_podcasts") }
  /// Add more criteria to finish refining your filter.
  internal static var filterCreateAddMore: String { return L10n.tr("Localizable", "filter_create_add_more") }
  /// FILTER BY
  internal static var filterCreateFilterBy: String { return L10n.tr("Localizable", "filter_create_filter_by") }
  /// Select your filter criteria using these buttons to create an up to date smart playlist of episodes.
  internal static var filterCreateInstructions: String { return L10n.tr("Localizable", "filter_create_instructions") }
  /// No Matching Episodes
  internal static var filterCreateNoEpisodes: String { return L10n.tr("Localizable", "filter_create_no_episodes") }
  /// The criteria you selected doesn’t match any current episodes in your subscriptions
  internal static var filterCreateNoEpisodesDescriptionExplanation: String { return L10n.tr("Localizable", "filter_create_no_episodes_description_explanation") }
  /// Choose different criteria, or save this filter if you think it will match episodes in the future.
  internal static var filterCreateNoEpisodesDescriptionPrompt: String { return L10n.tr("Localizable", "filter_create_no_episodes_description_prompt") }
  /// All Podcasts
  internal static var filterCreatePodcastsAllPodcasts: String { return L10n.tr("Localizable", "filter_create_podcasts_all_podcasts") }
  /// PREVIEW
  internal static var filterCreatePreview: String { return L10n.tr("Localizable", "filter_create_preview") }
  /// Save Filter
  internal static var filterCreateSave: String { return L10n.tr("Localizable", "filter_create_save") }
  /// Filter Details
  internal static var filterDetails: String { return L10n.tr("Localizable", "filter_details") }
  /// COLOUR & ICON
  internal static var filterDetailsColorIcon: String { return L10n.tr("Localizable", "filter_details_color_icon") }
  /// Colour Selector
  internal static var filterDetailsColorSelection: String { return L10n.tr("Localizable", "filter_details_color_selection") }
  /// Icon Selector
  internal static var filterDetailsIconSelection: String { return L10n.tr("Localizable", "filter_details_icon_selection") }
  /// NAME
  internal static var filterDetailsName: String { return L10n.tr("Localizable", "filter_details_name") }
  /// Download Status
  internal static var filterDownloadStatus: String { return L10n.tr("Localizable", "filter_download_status") }
  /// Episode Status
  internal static var filterEpisodeStatus: String { return L10n.tr("Localizable", "filter_episode_status") }
  /// Longer than
  internal static var filterLongerThanLabel: String { return L10n.tr("Localizable", "filter_longer_than_label") }
  /// New podcasts you subscribe to will not be automatically added
  internal static var filterManualAddSubtitle: String { return L10n.tr("Localizable", "filter_manual_add_subtitle") }
  /// Media Type
  internal static var filterMediaType: String { return L10n.tr("Localizable", "filter_media_type") }
  /// Audio
  internal static var filterMediaTypeAudio: String { return L10n.tr("Localizable", "filter_media_type_audio") }
  /// Video
  internal static var filterMediaTypeVideo: String { return L10n.tr("Localizable", "filter_media_type_video") }
  /// Episode Duration
  internal static var filterOptionEpisodeDuration: String { return L10n.tr("Localizable", "filter_option_episode_duration") }
  /// Filtering for episodes longer than %1$@ but shorter than %2$@ would cause a rift in our space time continuum. Sorry.
  internal static func filterOptionEpisodeDurationErrorMsgFormat(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "filter_option_episode_duration_error_msg_format", String(describing: p1), String(describing: p2))
  }
  /// Yes, But No
  internal static var filterOptionEpisodeDurationErrorTitle: String { return L10n.tr("Localizable", "filter_option_episode_duration_error_title") }
  /// Filter Options
  internal static var filterOptions: String { return L10n.tr("Localizable", "filter_options") }
  /// Release Date
  internal static var filterReleaseDate: String { return L10n.tr("Localizable", "filter_release_date") }
  /// Any time
  internal static var filterReleaseDateAnytime: String { return L10n.tr("Localizable", "filter_release_date_anytime") }
  /// Last 24 hours
  internal static var filterReleaseDateLast24Hours: String { return L10n.tr("Localizable", "filter_release_date_last_24_hours") }
  /// Last 2 weeks
  internal static var filterReleaseDateLast2Weeks: String { return L10n.tr("Localizable", "filter_release_date_last_2_weeks") }
  /// Last 3 days
  internal static var filterReleaseDateLast3Days: String { return L10n.tr("Localizable", "filter_release_date_last_3_days") }
  /// Last month
  internal static var filterReleaseDateLastMonth: String { return L10n.tr("Localizable", "filter_release_date_last_month") }
  /// Last week
  internal static var filterReleaseDateLastWeek: String { return L10n.tr("Localizable", "filter_release_date_last_week") }
  /// Shorter than
  internal static var filterShorterThanLabel: String { return L10n.tr("Localizable", "filter_shorter_than_label") }
  /// Update Filter
  internal static var filterUpdate: String { return L10n.tr("Localizable", "filter_update") }
  /// All
  internal static var filterValueAll: String { return L10n.tr("Localizable", "filter_value_all") }
  /// Filters
  internal static var filters: String { return L10n.tr("Localizable", "filters") }
  /// New Filter
  internal static var filtersDefaultNewFilter: String { return L10n.tr("Localizable", "filters_default_new_filter") }
  /// New Releases
  internal static var filtersDefaultNewReleases: String { return L10n.tr("Localizable", "filters_default_new_releases") }
  /// + New Filter
  internal static var filtersNewFilterButton: String { return L10n.tr("Localizable", "filters_new_filter_button") }
  /// Folder
  internal static var folder: String { return L10n.tr("Localizable", "folder") }
  /// Add %1$@ Podcasts
  internal static func folderAddPodcastsPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "folder_add_podcasts_plural_format", String(describing: p1))
  }
  /// Add 1 Podcast
  internal static var folderAddPodcastsSingular: String { return L10n.tr("Localizable", "folder_add_podcasts_singular") }
  /// Add or Remove Podcasts
  internal static var folderAddRemovePodcasts: String { return L10n.tr("Localizable", "folder_add_remove_podcasts") }
  /// Change folder
  internal static var folderChange: String { return L10n.tr("Localizable", "folder_change") }
  /// Choose a color
  internal static var folderChooseColor: String { return L10n.tr("Localizable", "folder_choose_color") }
  /// Choose Podcasts
  internal static var folderChoosePodcasts: String { return L10n.tr("Localizable", "folder_choose_podcasts") }
  /// Makes it easier to find folders
  internal static var folderColorDetail: String { return L10n.tr("Localizable", "folder_color_detail") }
  /// Create Folder
  internal static var folderCreate: String { return L10n.tr("Localizable", "folder_create") }
  /// Create New Folder
  internal static var folderCreateNew: String { return L10n.tr("Localizable", "folder_create_new") }
  /// Delete Folder
  internal static var folderDelete: String { return L10n.tr("Localizable", "folder_delete") }
  /// This folder will be deleted, and its contents will be moved back to the Podcasts screen.
  internal static var folderDeletePromptMsg: String { return L10n.tr("Localizable", "folder_delete_prompt_msg") }
  /// Are You Sure?
  internal static var folderDeletePromptTitle: String { return L10n.tr("Localizable", "folder_delete_prompt_title") }
  /// Edit Folder
  internal static var folderEdit: String { return L10n.tr("Localizable", "folder_edit") }
  /// Add podcasts to your folder and they’ll appear here.
  internal static var folderEmptyDescription: String { return L10n.tr("Localizable", "folder_empty_description") }
  /// Your folder is empty
  internal static var folderEmptyTitle: String { return L10n.tr("Localizable", "folder_empty_title") }
  /// Go to folder
  internal static var folderGoTo: String { return L10n.tr("Localizable", "folder_go_to") }
  /// Folder name
  internal static var folderName: String { return L10n.tr("Localizable", "folder_name") }
  /// Name your folder
  internal static var folderNameTitle: String { return L10n.tr("Localizable", "folder_name_title") }
  /// New Folder
  internal static var folderNew: String { return L10n.tr("Localizable", "folder_new") }
  /// No Folder
  internal static var folderNoFolder: String { return L10n.tr("Localizable", "folder_no_folder") }
  /// Choose Folder
  internal static var folderPodcastChooseFolder: String { return L10n.tr("Localizable", "folder_podcast_choose_folder") }
  /// Remove from folder
  internal static var folderRemoveFrom: String { return L10n.tr("Localizable", "folder_remove_from") }
  /// Save Folder
  internal static var folderSaveFolder: String { return L10n.tr("Localizable", "folder_save_folder") }
  /// Unnamed Folder
  internal static var folderUnnamed: String { return L10n.tr("Localizable", "folder_unnamed") }
  /// Folders
  internal static var folders: String { return L10n.tr("Localizable", "folders") }
  /// No Payment Now – Cancel Anytime
  internal static var freeTrialDetailLabel: String { return L10n.tr("Localizable", "free_trial_detail_label") }
  /// %1$@ FREE
  internal static func freeTrialDurationFree(_ p1: Any) -> String {
    return L10n.tr("Localizable", "free_trial_duration_free", String(describing: p1))
  }
  /// %1$@ FREE TRIAL
  internal static func freeTrialDurationFreeTrial(_ p1: Any) -> String {
    return L10n.tr("Localizable", "free_trial_duration_free_trial", String(describing: p1))
  }
  /// %1$@ free then %2$@
  internal static func freeTrialPricingTerms(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "free_trial_pricing_terms", String(describing: p1), String(describing: p2))
  }
  /// Start Free Trial & Subscribe
  internal static var freeTrialStartAndSubscribeButton: String { return L10n.tr("Localizable", "free_trial_start_and_subscribe_button") }
  /// Start Free Trial
  internal static var freeTrialStartButton: String { return L10n.tr("Localizable", "free_trial_start_button") }
  /// Try Plus with %1$@ free
  internal static func freeTrialTitleLabel(_ p1: Any) -> String {
    return L10n.tr("Localizable", "free_trial_title_label", String(describing: p1))
  }
  /// It really matches your eyes ✨
  internal static var funnyConfMsg: String { return L10n.tr("Localizable", "funny_conf_msg") }
  /// You really don't listen much, do you?
  internal static var funnyTimeNotEnough: String { return L10n.tr("Localizable", "funny_time_not_enough") }
  /// During which time %1$@ planes took off. Please fasten your seatbelt. 🛫
  internal static func funnyTimeUnitAirplaneTakeoffs(_ p1: Any) -> String {
    return L10n.tr("Localizable", "funny_time_unit_airplane_takeoffs", String(describing: p1))
  }
  /// During which time an astronaut sneezed %1$@ times. Achoo! 😤
  internal static func funnyTimeUnitAstronautSneezes(_ p1: Any) -> String {
    return L10n.tr("Localizable", "funny_time_unit_astronaut_sneezes", String(describing: p1))
  }
  /// During which time you could have gone around the world %1$@ times in an air balloon. 🌏
  internal static func funnyTimeUnitBalloonTravel(_ p1: Any) -> String {
    return L10n.tr("Localizable", "funny_time_unit_balloon_travel", String(describing: p1))
  }
  /// During which time %1$@ babies were born. Wahhh! 🍼
  internal static func funnyTimeUnitBirths(_ p1: Any) -> String {
    return L10n.tr("Localizable", "funny_time_unit_births", String(describing: p1))
  }
  /// During which time you blinked %1$@ times. Heyooo! 👀
  internal static func funnyTimeUnitBlinks(_ p1: Any) -> String {
    return L10n.tr("Localizable", "funny_time_unit_blinks", String(describing: p1))
  }
  /// During which time %1$@ emails were sent. 💌
  internal static func funnyTimeUnitEmails(_ p1: Any) -> String {
    return L10n.tr("Localizable", "funny_time_unit_emails", String(describing: p1))
  }
  /// During which time you released %1$@ oz of air biscuits. Gross! 💨
  internal static func funnyTimeUnitFarts(_ p1: Any) -> String {
    return L10n.tr("Localizable", "funny_time_unit_farts", String(describing: p1))
  }
  /// During which time %1$@ Google searches were performed. Bazinga. 🔎
  internal static func funnyTimeUnitGoogle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "funny_time_unit_google", String(describing: p1))
  }
  /// During which time lightning struck %1$@ times. Boom. ⚡️
  internal static func funnyTimeUnitLightning(_ p1: Any) -> String {
    return L10n.tr("Localizable", "funny_time_unit_lightning", String(describing: p1))
  }
  /// During which time a certain fruit vendor made $%1$@ 🍏
  internal static func funnyTimeUnitPhoneProduction(_ p1: Any) -> String {
    return L10n.tr("Localizable", "funny_time_unit_phone_production", String(describing: p1))
  }
  /// During which time you shed %1$@ skin cells. Ew? 😅
  internal static func funnyTimeUnitShedSkin(_ p1: Any) -> String {
    return L10n.tr("Localizable", "funny_time_unit_shed_skin", String(describing: p1))
  }
  /// During which time you could have tied %1$@ shoe laces. Maybe. 👟
  internal static func funnyTimeUnitTiedShoes(_ p1: Any) -> String {
    return L10n.tr("Localizable", "funny_time_unit_tied_shoes", String(describing: p1))
  }
  /// During which time %1$@ tweets were tooted. Toot! Toot! 🐣
  internal static func funnyTimeUnitTweets(_ p1: Any) -> String {
    return L10n.tr("Localizable", "funny_time_unit_tweets", String(describing: p1))
  }
  /// Go to Podcast
  internal static var goToPodcast: String { return L10n.tr("Localizable", "go_to_podcast") }
  /// Group Episodes
  internal static var groupEpisodes: String { return L10n.tr("Localizable", "group_episodes") }
  /// Clear All
  internal static var historyClearAll: String { return L10n.tr("Localizable", "history_clear_all") }
  /// Clear Listening History
  internal static var historyClearAllDetails: String { return L10n.tr("Localizable", "history_clear_all_details") }
  /// This action cannot be undone.
  internal static var historyClearAllDetailsMsg: String { return L10n.tr("Localizable", "history_clear_all_details_msg") }
  /// Hour listened
  internal static var hourListened: String { return L10n.tr("Localizable", "hour_listened") }
  /// Hour saved
  internal static var hourSaved: String { return L10n.tr("Localizable", "hour_saved") }
  /// Hours listened
  internal static var hoursListened: String { return L10n.tr("Localizable", "hours_listened") }
  /// %1$@ hours
  internal static func hoursPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "hours_plural_format", String(describing: p1))
  }
  /// Hours saved
  internal static var hoursSaved: String { return L10n.tr("Localizable", "hours_saved") }
  /// First, open an app that has the audio files you'd like to save
  internal static var howToUploadExplanation: String { return L10n.tr("Localizable", "how_to_upload_explanation") }
  /// Choose to share that file
  internal static var howToUploadFirstInstruction: String { return L10n.tr("Localizable", "how_to_upload_first_instruction") }
  /// In the menu tap "Copy to Pocket Casts"
  internal static var howToUploadSecondInstruction: String { return L10n.tr("Localizable", "how_to_upload_second_instruction") }
  /// That's it, you're done. Change any details you want, hit save and play!
  internal static var howToUploadSummary: String { return L10n.tr("Localizable", "how_to_upload_summary") }
  /// Import
  internal static var `import`: String { return L10n.tr("Localizable", "import") }
  /// We can import your podcasts from Apple Podcasts by using the built-in Shortcuts app.
  /// Note: If you previously deleted the shortcuts app you will be prompted to reinstall it.
  /// 
  /// 1. Tap the Install Shortcut button below.
  /// 2. When prompted tap the Add Shortcut button.
  /// 3. Tap on the Shortcuts tab.
  /// 4. Locate the "Apple Podcasts to Pocket Casts" shortcut in the list.
  /// 5. Tap it to start the import process.
  /// 6. Once the shortcut is done running Pocket Casts will reopen and finish the import process.
  internal static var importInstructionsApplePodcastsSteps: String { return L10n.tr("Localizable", "import_instructions_apple_podcasts_steps") }
  /// 1. Tap the Open Breaker button below
  /// 2. Tap on Settings in the bottom tab bar
  /// 3. Tap on Connection
  /// 4. Tap on Export subscriptions
  /// 5. When the dialog opens locate the Pocket Casts icon, and tap on it
  internal static var importInstructionsBreaker: String { return L10n.tr("Localizable", "import_instructions_breaker") }
  /// 1. Tap the Open Castbox button below
  /// 2. Tap the Personal tab
  /// 3. Swipe down until you see the Settings option, then tap on it
  /// 4. Swipe down until you see the OPML Export option, then tap on it
  /// 5. If prompted, tap "Open in Pocket Casts"
  /// 6. If the file opens in Safari, tap the Download button
  /// 7. Once the download is complete, tap the download icon in the URL bar
  /// 8. Tap the Downloads item
  /// 9. Tap the castbox_opml file 
  /// 10. If needed, tap the Share icon, then open the file using Pocket Casts
  /// 11. When the share dialog opens, locate the Pocket Casts icon, then tap on it
  internal static var importInstructionsCastbox: String { return L10n.tr("Localizable", "import_instructions_castbox") }
  /// 1. Tap the Open Castro button below
  /// 2. Tap the Cog icon in the top corner of the app
  /// 3. Swipe down until you see the User Data option, then tap on it
  /// 4. Tap the Export Subscriptions item
  /// 5. When the share dialog opens, locate the Pocket Casts icon, then tap on it
  internal static var importInstructionsCastro: String { return L10n.tr("Localizable", "import_instructions_castro") }
  /// Import from %1$@
  internal static func importInstructionsImportFrom(_ p1: Any) -> String {
    return L10n.tr("Localizable", "import_instructions_import_from", String(describing: p1))
  }
  /// Install Shortcut
  internal static var importInstructionsInstallShortcut: String { return L10n.tr("Localizable", "import_instructions_install_shortcut") }
  /// Open %1$@
  internal static func importInstructionsOpenIn(_ p1: Any) -> String {
    return L10n.tr("Localizable", "import_instructions_open_in", String(describing: p1))
  }
  /// other apps
  internal static var importInstructionsOtherAppsTitle: String { return L10n.tr("Localizable", "import_instructions_other_apps_title") }
  /// 1. Tap the button below to open Overcast
  /// 2. Tap the Cog icon in the top corner of the app
  /// 3. Swipe down until you see Export OPML, then tap on it
  /// 4. When the dialog opens locate the Pocket Casts icon, and tap on it
  internal static var importInstructionsOvercast: String { return L10n.tr("Localizable", "import_instructions_overcast") }
  /// Import your podcasts from an OPML file using a URL
  internal static var importOpmlFromUrl: String { return L10n.tr("Localizable", "import_opml_from_url") }
  /// You can import your podcasts subscriptions to Pocket Casts using the widely supported OPML format. Export the file from another app and choose open in Pocket Casts.
  /// 
  /// Note: You may need to email the OPML file to yourself, long press on the attachment and select Pocket Casts.
  internal static var importPodcastsDescription: String { return L10n.tr("Localizable", "import_podcasts_description") }
  /// IMPORT TO POCKET CASTS
  internal static var importPodcastsTitle: String { return L10n.tr("Localizable", "import_podcasts_title") }
  /// Coming from another app? Import your podcasts and get listening. You can always do this later in settings.
  internal static var importSubtitle: String { return L10n.tr("Localizable", "import_subtitle") }
  /// Bring your
  /// podcasts with you
  internal static var importTitle: String { return L10n.tr("Localizable", "import_title") }
  /// In Progress
  internal static var inProgress: String { return L10n.tr("Localizable", "in_progress") }
  /// Close Player
  internal static var keycommandClosePlayer: String { return L10n.tr("Localizable", "keycommand_close_player") }
  /// Decrease Speed
  internal static var keycommandDecreaseSpeed: String { return L10n.tr("Localizable", "keycommand_decrease_speed") }
  /// Increase Speed
  internal static var keycommandIncreaseSpeed: String { return L10n.tr("Localizable", "keycommand_increase_speed") }
  /// Open Player
  internal static var keycommandOpenPlayer: String { return L10n.tr("Localizable", "keycommand_open_player") }
  /// Play/Pause
  internal static var keycommandPlayPause: String { return L10n.tr("Localizable", "keycommand_play_pause") }
  /// Learn More
  internal static var learnMore: String { return L10n.tr("Localizable", "learn_more") }
  /// Listening History
  internal static var listeningHistory: String { return L10n.tr("Localizable", "listening_history") }
  /// Loading...
  internal static var loading: String { return L10n.tr("Localizable", "loading") }
  /// Create an account to sync your listening experience across all your devices.
  internal static var loginSubtitle: String { return L10n.tr("Localizable", "login_subtitle") }
  /// Discover your next favorite podcast
  internal static var loginTitle: String { return L10n.tr("Localizable", "login_title") }
  /// Mark as Played
  internal static var markPlayed: String { return L10n.tr("Localizable", "mark_played") }
  /// Mark Played
  internal static var markPlayedShort: String { return L10n.tr("Localizable", "mark_played_short") }
  /// Mark Unplayed
  internal static var markUnplayedShort: String { return L10n.tr("Localizable", "mark_unplayed_short") }
  /// Maybe later
  internal static var maybeLater: String { return L10n.tr("Localizable", "maybe_later") }
  /// Close And Clear Up Next
  internal static var miniPlayerClose: String { return L10n.tr("Localizable", "mini_player_close") }
  /// Minute listened
  internal static var minuteListened: String { return L10n.tr("Localizable", "minute_listened") }
  /// Minute saved
  internal static var minuteSaved: String { return L10n.tr("Localizable", "minute_saved") }
  /// Minutes listened
  internal static var minutesListened: String { return L10n.tr("Localizable", "minutes_listened") }
  /// Minutes saved
  internal static var minutesSaved: String { return L10n.tr("Localizable", "minutes_saved") }
  /// month
  internal static var month: String { return L10n.tr("Localizable", "month") }
  /// Monthly
  internal static var monthly: String { return L10n.tr("Localizable", "monthly") }
  /// Move to Bottom
  internal static var moveToBottom: String { return L10n.tr("Localizable", "move_to_bottom") }
  /// Move to Top
  internal static var moveToTop: String { return L10n.tr("Localizable", "move_to_top") }
  /// Adding max %1$@ episodes.
  internal static func multiSelectAddEpisodesMaxFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "multi_select_add_episodes_max_format", String(describing: p1))
  }
  /// Adding %1$@ episodes.
  internal static func multiSelectAddingEpisodesPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "multi_select_adding_episodes_plural_format", String(describing: p1))
  }
  /// Adding 1 episode.
  internal static var multiSelectAddingEpisodesSingular: String { return L10n.tr("Localizable", "multi_select_adding_episodes_singular") }
  /// Archiving %1$@ episodes
  internal static func multiSelectArchivingEpisodesPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "multi_select_archiving_episodes_plural_format", String(describing: p1))
  }
  /// Archiving 1 episode
  internal static var multiSelectArchivingEpisodesSingular: String { return L10n.tr("Localizable", "multi_select_archiving_episodes_singular") }
  /// Are you sure you want to delete %1$@ files?
  internal static func multiSelectDeleteFileMessagePlural(_ p1: Any) -> String {
    return L10n.tr("Localizable", "multi_select_delete_file_message_plural", String(describing: p1))
  }
  /// Are you sure you want to delete 1 file?
  internal static var multiSelectDeleteFileMessageSingular: String { return L10n.tr("Localizable", "multi_select_delete_file_message_singular") }
  /// Downloading %1$@
  internal static func multiSelectDownloadingEpisodesFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "multi_select_downloading_episodes_format", String(describing: p1))
  }
  /// Marking %1$@ episodes as played.
  internal static func multiSelectMarkEpisodesPlayedPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "multi_select_mark_episodes_played_plural_format", String(describing: p1))
  }
  /// Marking 1 episode as played.
  internal static var multiSelectMarkEpisodesPlayedSingular: String { return L10n.tr("Localizable", "multi_select_mark_episodes_played_singular") }
  /// Marking %1$@ episodes as unplayed.
  internal static func multiSelectMarkEpisodesUnplayedPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "multi_select_mark_episodes_unplayed_plural_format", String(describing: p1))
  }
  /// Marking 1 episode as unplayed.
  internal static var multiSelectMarkEpisodesUnplayedSingular: String { return L10n.tr("Localizable", "multi_select_mark_episodes_unplayed_singular") }
  /// Queuing %1$@
  internal static func multiSelectQueuingEpisodesFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "multi_select_queuing_episodes_format", String(describing: p1))
  }
  /// Removing 1 download.
  internal static var multiSelectRemoveDownloadSingular: String { return L10n.tr("Localizable", "multi_select_remove_download_singular") }
  /// Removing %1$@ downloads.
  internal static func multiSelectRemoveDownloadsPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "multi_select_remove_downloads_plural_format", String(describing: p1))
  }
  /// Mark as Unplayed
  internal static var multiSelectRemoveMarkUnplayed: String { return L10n.tr("Localizable", "multi_select_remove_mark_unplayed") }
  /// %1$@ SELECTED EPISODES
  internal static func multiSelectSelectedCountPlural(_ p1: Any) -> String {
    return L10n.tr("Localizable", "multi_select_selected_count_plural", String(describing: p1))
  }
  /// 1 SELECTED EPISODE
  internal static var multiSelectSelectedCountSingular: String { return L10n.tr("Localizable", "multi_select_selected_count_singular") }
  /// SHORTCUT IN ACTION BAR
  internal static var multiSelectShortcutInActionBar: String { return L10n.tr("Localizable", "multi_select_shortcut_in_action_bar") }
  /// Star Episodes
  internal static var multiSelectStar: String { return L10n.tr("Localizable", "multi_select_star") }
  /// Starring %1$@ episodes.
  internal static func multiSelectStarringEpisodesPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "multi_select_starring_episodes_plural_format", String(describing: p1))
  }
  /// Starring 1 episode.
  internal static var multiSelectStarringEpisodesSingular: String { return L10n.tr("Localizable", "multi_select_starring_episodes_singular") }
  /// Unarchiving %1$@ episodes.
  internal static func multiSelectUnarchivingEpisodesPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "multi_select_unarchiving_episodes_plural_format", String(describing: p1))
  }
  /// Unarchiving 1 episode
  internal static var multiSelectUnarchivingEpisodesSingular: String { return L10n.tr("Localizable", "multi_select_unarchiving_episodes_singular") }
  /// Unstar Episodes
  internal static var multiSelectUnstar: String { return L10n.tr("Localizable", "multi_select_unstar") }
  /// Unstarring %1$@ episodes.
  internal static func multiSelectUnstarringEpisodesPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "multi_select_unstarring_episodes_plural_format", String(describing: p1))
  }
  /// Unstarring 1 episode
  internal static var multiSelectUnstarringEpisodesSingular: String { return L10n.tr("Localizable", "multi_select_unstarring_episodes_singular") }
  /// Name
  internal static var name: String { return L10n.tr("Localizable", "name") }
  /// New Email Address
  internal static var newEmailAddressPrompt: String { return L10n.tr("Localizable", "new_email_address_prompt") }
  /// New episodes
  internal static var newEpisodes: String { return L10n.tr("Localizable", "new_episodes") }
  /// New Password
  internal static var newPasswordPrompt: String { return L10n.tr("Localizable", "new_password_prompt") }
  /// Next
  internal static var next: String { return L10n.tr("Localizable", "next") }
  /// Next Episode
  internal static var nextEpisode: String { return L10n.tr("Localizable", "next_episode") }
  /// Next payment: %1$@
  internal static func nextPaymentFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "next_payment_format", String(describing: p1))
  }
  /// Headphone settings
  internal static var noBookmarksButtonTitle: String { return L10n.tr("Localizable", "no_bookmarks_button_title") }
  /// You can save timestamps of episodes from the actions menu in the player or by configuring an action with your headphones.
  internal static var noBookmarksMessage: String { return L10n.tr("Localizable", "no_bookmarks_message") }
  /// No bookmarks yet
  internal static var noBookmarksTitle: String { return L10n.tr("Localizable", "no_bookmarks_title") }
  /// None
  internal static var `none`: String { return L10n.tr("Localizable", "none") }
  /// You're not on WiFi
  internal static var notOnWifi: String { return L10n.tr("Localizable", "not_on_wifi") }
  /// Play Now
  internal static var notificationsPlayNow: String { return L10n.tr("Localizable", "notifications_play_now") }
  /// Now Playing
  internal static var nowPlaying: String { return L10n.tr("Localizable", "now_playing") }
  /// Now Playing %1$@
  internal static func nowPlayingItem(_ p1: Any) -> String {
    return L10n.tr("Localizable", "now_playing_item", String(describing: p1))
  }
  /// Playing
  internal static var nowPlayingShortTitle: String { return L10n.tr("Localizable", "now_playing_short_title") }
  /// %1$@ chapters
  internal static func numberOfChapters(_ p1: Any) -> String {
    return L10n.tr("Localizable", "number_of_chapters", String(describing: p1))
  }
  /// %1$@ hidden
  internal static func numberOfHiddenChapters(_ p1: Any) -> String {
    return L10n.tr("Localizable", "number_of_hidden_chapters", String(describing: p1))
  }
  /// Off
  internal static var off: String { return L10n.tr("Localizable", "off") }
  /// OK
  internal static var ok: String { return L10n.tr("Localizable", "ok") }
  /// Only On WiFi
  internal static var onlyOnWifi: String { return L10n.tr("Localizable", "only_on_wifi") }
  /// Unable to import podcasts from the OPML file you specified. Please check that it's valid
  internal static var opmlImportFailedMessage: String { return L10n.tr("Localizable", "opml_import_failed_message") }
  /// OPML Import Failed
  internal static var opmlImportFailedTitle: String { return L10n.tr("Localizable", "opml_import_failed_title") }
  /// Importing %1$@ of %2$@
  internal static func opmlImportProgressFormat(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "opml_import_progress_format", String(describing: p1), String(describing: p2))
  }
  /// OPML Import Succeeded
  internal static var opmlImportSucceededTitle: String { return L10n.tr("Localizable", "opml_import_succeeded_title") }
  /// Importing Podcasts...
  internal static var opmlImporting: String { return L10n.tr("Localizable", "opml_importing") }
  /// Page %1$@ of %2$@
  internal static func pageControlPageProgressFormat(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "page_control_page_progress_format", String(describing: p1), String(describing: p2))
  }
  /// %1$@ / %2$@ SUBSCRIBED
  internal static func paidPodcastBundledSubscriptions(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "paid_podcast_bundled_subscriptions", String(describing: p1), String(describing: p2))
  }
  /// Cancel Contribution
  internal static var paidPodcastCancel: String { return L10n.tr("Localizable", "paid_podcast_cancel") }
  /// Supporter status will remain active until %1$@. After that you won't be able to play these podcast anymore.
  internal static func paidPodcastCancelMsgPlural(_ p1: Any) -> String {
    return L10n.tr("Localizable", "paid_podcast_cancel_msg_plural", String(describing: p1))
  }
  /// Supporter status will remain active until %1$@. You will only be able to listen to episodes released before this date.
  internal static func paidPodcastCancelMsgRetainAccess(_ p1: Any) -> String {
    return L10n.tr("Localizable", "paid_podcast_cancel_msg_retain_access", String(describing: p1))
  }
  /// Supporter status will remain active until %1$@. After that you won't be able to play this podcast anymore.
  internal static func paidPodcastCancelMsgSingular(_ p1: Any) -> String {
    return L10n.tr("Localizable", "paid_podcast_cancel_msg_singular", String(describing: p1))
  }
  /// Unable to load info
  internal static var paidPodcastGenericError: String { return L10n.tr("Localizable", "paid_podcast_generic_error") }
  /// Manage
  internal static var paidPodcastManage: String { return L10n.tr("Localizable", "paid_podcast_manage") }
  /// Next episode %1$@
  internal static func paidPodcastNextEpisodeFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "paid_podcast_next_episode_format", String(describing: p1))
  }
  /// Released %1$@
  internal static func paidPodcastReleaseFrequencyFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "paid_podcast_release_frequency_format", String(describing: p1))
  }
  /// SIGN IN FOR
  /// UPDATES
  internal static var paidPodcastSigninPromptMsg: String { return L10n.tr("Localizable", "paid_podcast_signin_prompt_msg") }
  /// Sign in for new episodes
  internal static var paidPodcastSigninPromptTitle: String { return L10n.tr("Localizable", "paid_podcast_signin_prompt_title") }
  /// ENDED: %1$@
  internal static func paidPodcastSubscriptionEnded(_ p1: Any) -> String {
    return L10n.tr("Localizable", "paid_podcast_subscription_ended", String(describing: p1))
  }
  /// ENDS: %1$@
  internal static func paidPodcastSubscriptionEnds(_ p1: Any) -> String {
    return L10n.tr("Localizable", "paid_podcast_subscription_ends", String(describing: p1))
  }
  /// Supporter-only feed
  internal static var paidPodcastSupporterOnlyMsg: String { return L10n.tr("Localizable", "paid_podcast_supporter_only_msg") }
  /// Thanks for signing up as a %1$@ supporter. To access your special content, you’ll need to sign in.
  internal static func paidPodcastSupporterSigninPrompt(_ p1: Any) -> String {
    return L10n.tr("Localizable", "paid_podcast_supporter_signin_prompt", String(describing: p1))
  }
  /// Unsubscribing from all these podcasts will delete any downloaded files they have, are you sure?
  internal static var paidPodcastUnsubscribeMsg: String { return L10n.tr("Localizable", "paid_podcast_unsubscribe_msg") }
  /// Patron
  internal static var patron: String { return L10n.tr("Localizable", "patron") }
  /// Believe in what we’re doing and want to show your support?
  internal static var patronCallout: String { return L10n.tr("Localizable", "patron_callout") }
  /// Become a Pocket Casts Patron and help us continue to deliver the best podcasting experience available.
  internal static var patronDescription: String { return L10n.tr("Localizable", "patron_description") }
  /// Early access to features
  internal static var patronFeatureEarlyAccess: String { return L10n.tr("Localizable", "patron_feature_early_access") }
  /// Everything in Plus
  internal static var patronFeatureEverythingInPlus: String { return L10n.tr("Localizable", "patron_feature_everything_in_plus") }
  /// Supporters profile badge
  internal static var patronFeatureProfileBadge: String { return L10n.tr("Localizable", "patron_feature_profile_badge") }
  /// Special Pocket Casts app icons
  internal static var patronFeatureProfileIcons: String { return L10n.tr("Localizable", "patron_feature_profile_icons") }
  /// Become a Patron member and unlock all Pocket Casts features
  internal static var patronPurchasePromoTitle: String { return L10n.tr("Localizable", "patron_purchase_promo_title") }
  /// Subscribe to Patron
  internal static var patronSubscribeTo: String { return L10n.tr("Localizable", "patron_subscribe_to") }
  /// Thank you for your support!
  internal static var patronThankYou: String { return L10n.tr("Localizable", "patron_thank_you") }
  /// Hold the unlock button below to receive some tokens of our appreciation.
  internal static var patronUnlockInstructions: String { return L10n.tr("Localizable", "patron_unlock_instructions") }
  /// Release to Unlock
  internal static var patronUnlockRelease: String { return L10n.tr("Localizable", "patron_unlock_release") }
  /// unlock
  internal static var patronUnlockWord: String { return L10n.tr("Localizable", "patron_unlock_word") }
  /// Unlocking
  internal static var patronUnlocking: String { return L10n.tr("Localizable", "patron_unlocking") }
  /// Pause
  internal static var pause: String { return L10n.tr("Localizable", "pause") }
  /// Phone
  internal static var phone: String { return L10n.tr("Localizable", "phone") }
  /// Play
  internal static var play: String { return L10n.tr("Localizable", "play") }
  /// Play All
  internal static var playAll: String { return L10n.tr("Localizable", "play_all") }
  /// Play Last
  internal static var playLast: String { return L10n.tr("Localizable", "play_last") }
  /// Play Next
  internal static var playNext: String { return L10n.tr("Localizable", "play_next") }
  /// Mad Max
  internal static var playbackEffectTrimSilenceMax: String { return L10n.tr("Localizable", "playback_effect_trim_silence_max") }
  /// Medium
  internal static var playbackEffectTrimSilenceMedium: String { return L10n.tr("Localizable", "playback_effect_trim_silence_medium") }
  /// Mild
  internal static var playbackEffectTrimSilenceMild: String { return L10n.tr("Localizable", "playback_effect_trim_silence_mild") }
  /// Playback effects
  internal static var playbackEffects: String { return L10n.tr("Localizable", "playback_effects") }
  /// Playback Failed
  internal static var playbackFailed: String { return L10n.tr("Localizable", "playback_failed") }
  /// %1$@x
  internal static func playbackSpeed(_ p1: Any) -> String {
    return L10n.tr("Localizable", "playback_speed", String(describing: p1))
  }
  /// Sleep timer on
  internal static var playerAccessibilitySleepTimerOn: String { return L10n.tr("Localizable", "player_accessibility_sleep_timer_on") }
  /// Shown as Delete for custom episodes
  internal static var playerActionSubtitleDelete: String { return L10n.tr("Localizable", "player_action_subtitle_delete") }
  /// Hidden for custom episodes
  internal static var playerActionSubtitleHidden: String { return L10n.tr("Localizable", "player_action_subtitle_hidden") }
  /// Playback Effects
  internal static var playerActionTitleEffects: String { return L10n.tr("Localizable", "player_action_title_effects") }
  /// Go to Files
  internal static var playerActionTitleGoToFile: String { return L10n.tr("Localizable", "player_action_title_go_to_file") }
  /// Output Device
  internal static var playerActionTitleOutputOptions: String { return L10n.tr("Localizable", "player_action_title_output_options") }
  /// Sleep Timer
  internal static var playerActionTitleSleepTimer: String { return L10n.tr("Localizable", "player_action_title_sleep_timer") }
  /// Unstar Episode
  internal static var playerActionTitleUnstarEpisode: String { return L10n.tr("Localizable", "player_action_title_unstar_episode") }
  /// Rearrange Actions
  internal static var playerActionsRearrangeTitle: String { return L10n.tr("Localizable", "player_actions_rearrange_title") }
  /// Archive this episode?
  internal static var playerArchivedConfirmation: String { return L10n.tr("Localizable", "player_archived_confirmation") }
  /// %1$@ Artwork
  internal static func playerArtwork(_ p1: Any) -> String {
    return L10n.tr("Localizable", "player_artwork", String(describing: p1))
  }
  /// %1$@ of %2$@
  internal static func playerChapterCount(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "player_chapter_count", String(describing: p1), String(describing: p2))
  }
  /// Decrement time
  internal static var playerDecrementTime: String { return L10n.tr("Localizable", "player_decrement_time") }
  /// Reduces the length of an episode by trimming silence in conversations.
  internal static var playerEffectsTrimSilenceDetails: String { return L10n.tr("Localizable", "player_effects_trim_silence_details") }
  /// In total you've saved %1$@ using this feature.
  internal static func playerEffectsTrimSilenceProgress(_ p1: Any) -> String {
    return L10n.tr("Localizable", "player_effects_trim_silence_progress", String(describing: p1))
  }
  /// The episode might be corrupted, but you can try to play it again.
  internal static var playerErrorCorruptedFile: String { return L10n.tr("Localizable", "player_error_corrupted_file") }
  /// Check your Internet connection and try again.
  internal static var playerErrorInternetConnection: String { return L10n.tr("Localizable", "player_error_internet_connection") }
  /// Increment time
  internal static var playerIncrementTime: String { return L10n.tr("Localizable", "player_increment_time") }
  /// Mark this episode as played?
  internal static var playerMarkAsPlayedConfirmation: String { return L10n.tr("Localizable", "player_mark_as_played_confirmation") }
  /// This will clear your current Up Next queue.
  internal static var playerOptionsPlayAllMessage: String { return L10n.tr("Localizable", "player_options_play_all_message") }
  /// Play 1 Episode
  internal static var playerOptionsPlayEpisodeSingular: String { return L10n.tr("Localizable", "player_options_play_episode_singular") }
  /// Play %1$@ Episodes
  internal static func playerOptionsPlayEpisodesPlural(_ p1: Any) -> String {
    return L10n.tr("Localizable", "player_options_play_episodes_plural", String(describing: p1))
  }
  /// SHORTCUT ON PLAYER
  internal static var playerOptionsShortcutOnPlayer: String { return L10n.tr("Localizable", "player_options_shortcut_on_player") }
  /// Route Selector
  internal static var playerRouteSelection: String { return L10n.tr("Localizable", "player_route_selection") }
  /// SHARE LINK TO
  internal static var playerShareHeader: String { return L10n.tr("Localizable", "player_share_header") }
  /// Details
  internal static var playerShowNotesTitle: String { return L10n.tr("Localizable", "player_show_notes_title") }
  /// Download Error
  internal static var playerUserEpisodeDownloadError: String { return L10n.tr("Localizable", "player_user_episode_download_error") }
  /// Playback Error
  internal static var playerUserEpisodePlaybackError: String { return L10n.tr("Localizable", "player_user_episode_playback_error") }
  /// Upload Error
  internal static var playerUserEpisodeUploadError: String { return L10n.tr("Localizable", "player_user_episode_upload_error") }
  /// Please try again
  internal static var pleaseTryAgain: String { return L10n.tr("Localizable", "please_try_again") }
  /// Please try again later.
  internal static var pleaseTryAgainLater: String { return L10n.tr("Localizable", "please_try_again_later") }
  /// A Pocket Casts account is required for Pocket Casts Plus. This ensures seamless listening across all your devices.
  internal static var plusAccountRequiredPrompt: String { return L10n.tr("Localizable", "plus_account_required_prompt") }
  /// Create an account or sign in to redeem your access to Pocket Casts Plus.
  internal static var plusAccountRequiredPromptDetails: String { return L10n.tr("Localizable", "plus_account_required_prompt_details") }
  /// When your trial is over you’ll still have all the great benefits of your regular account. Happy podcasting!
  internal static var plusAccountTrialDetails: String { return L10n.tr("Localizable", "plus_account_trial_details") }
  /// Unlock All Features
  internal static var plusButtonTitleUnlockAll: String { return L10n.tr("Localizable", "plus_button_title_unlock_all") }
  /// Can be canceled at any time
  internal static var plusCancelTerms: String { return L10n.tr("Localizable", "plus_cancel_terms") }
  /// %1$@ GB Cloud Storage
  internal static func plusCloudStorageLimitFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "plus_cloud_storage_limit_format", String(describing: p1))
  }
  /// 50%% off your first year
  internal static var plusDiscountYearlyMembership: String { return L10n.tr("Localizable", "plus_discount_yearly_membership") }
  /// You already have a Pocket Casts Plus account
  internal static var plusErrorAlreadyRegistered: String { return L10n.tr("Localizable", "plus_error_already_registered") }
  /// Thanks for your support, but unfortunately this means you can’t take part in this promotion.
  internal static var plusErrorAlreadyRegisteredDetails: String { return L10n.tr("Localizable", "plus_error_already_registered_details") }
  /// Expires %1$@
  internal static func plusExpirationFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "plus_expiration_format", String(describing: p1))
  }
  /// The undying gratitude of everyone here at Pocket Casts
  internal static var plusFeatureGratitude: String { return L10n.tr("Localizable", "plus_feature_gratitude") }
  /// Extra Themes & App Icons
  internal static var plusFeatureThemesIcons: String { return L10n.tr("Localizable", "plus_feature_themes_icons") }
  /// PLUS FEATURES
  internal static var plusFeatures: String { return L10n.tr("Localizable", "plus_features") }
  /// %1$@ Free Trial
  internal static func plusFreeMembershipFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "plus_free_membership_format", String(describing: p1))
  }
  /// Lifetime Member
  internal static var plusLifetimeMembership: String { return L10n.tr("Localizable", "plus_lifetime_membership") }
  /// Desktop & web apps
  internal static var plusMarketingDesktopAppsTitle: String { return L10n.tr("Localizable", "plus_marketing_desktop_apps_title") }
  /// Folders & Bookmarks
  internal static var plusMarketingFoldersAndBookmarksTitle: String { return L10n.tr("Localizable", "plus_marketing_folders_and_bookmarks_title") }
  /// Create folders to organise your podcast collection.
  internal static var plusMarketingFoldersDescription: String { return L10n.tr("Localizable", "plus_marketing_folders_description") }
  /// Ad-free experience which gives you more of what you love and less of what you don't
  internal static var plusMarketingHideAdsDescription: String { return L10n.tr("Localizable", "plus_marketing_hide_ads_description") }
  /// Hide Ads
  internal static var plusMarketingHideAdsTitle: String { return L10n.tr("Localizable", "plus_marketing_hide_ads_title") }
  /// Learn more about Pocket Casts Plus
  internal static var plusMarketingLearnMoreButton: String { return L10n.tr("Localizable", "plus_marketing_learn_more_button") }
  /// Get personal, and get distributed, all at once. Upload your personal audio files to our cloud servers, access your account via our web player, and make the app yours.
  internal static var plusMarketingMainDescription: String { return L10n.tr("Localizable", "plus_marketing_main_description") }
  /// Get access to exclusive features and customisation options
  internal static var plusMarketingSubtitle: String { return L10n.tr("Localizable", "plus_marketing_subtitle") }
  /// Themes & Icons
  internal static var plusMarketingThemesIconsTitle: String { return L10n.tr("Localizable", "plus_marketing_themes_icons_title") }
  /// Everything you love about Pocket Casts, plus more
  internal static var plusMarketingTitle: String { return L10n.tr("Localizable", "plus_marketing_title") }
  /// Upload your files to cloud storage and have it available everywhere
  internal static var plusMarketingUpdatedCloudStorageDescription: String { return L10n.tr("Localizable", "plus_marketing_updated_cloud_storage_description") }
  /// Listen in more places with our Windows, macOS and Web apps
  internal static var plusMarketingUpdatedDesktopAppsDescription: String { return L10n.tr("Localizable", "plus_marketing_updated_desktop_apps_description") }
  /// Organise your podcasts in folders, and keep them in sync across all your devices.
  internal static var plusMarketingUpdatedFoldersDescription: String { return L10n.tr("Localizable", "plus_marketing_updated_folders_description") }
  /// Apple Watch & Wear OS apps
  internal static var plusMarketingWatchPlaybackTitle: String { return L10n.tr("Localizable", "plus_marketing_watch_playback_title") }
  /// %1$@ per month
  internal static func plusMonthlyFrequencyPricingFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "plus_monthly_frequency_pricing_format", String(describing: p1))
  }
  /// Payment Cancelled
  internal static var plusPaymentCanceled: String { return L10n.tr("Localizable", "plus_payment_canceled") }
  /// Best Value
  internal static var plusPaymentFrequencyBestValue: String { return L10n.tr("Localizable", "plus_payment_frequency_best_value") }
  /// per month
  internal static var plusPerMonth: String { return L10n.tr("Localizable", "plus_per_month") }
  /// %1$@ / monthly
  internal static func plusPricePerMonth(_ p1: Any) -> String {
    return L10n.tr("Localizable", "plus_price_per_month", String(describing: p1))
  }
  /// Get Pocket Casts Plus to unlock this feature, plus lots more!
  internal static var plusPromoParagraph: String { return L10n.tr("Localizable", "plus_promo_paragraph") }
  /// Promotion Expired or Invalid
  internal static var plusPromotionExpired: String { return L10n.tr("Localizable", "plus_promotion_expired") }
  /// You’re welcome to sign up for Pocket Casts Plus anyway, create a regular account, or just dive right in.
  internal static var plusPromotionExpiredNudge: String { return L10n.tr("Localizable", "plus_promotion_expired_nudge") }
  /// Code already used
  internal static var plusPromotionUsed: String { return L10n.tr("Localizable", "plus_promotion_used") }
  /// It looks like there was a problem processing your payment. Please try again.
  internal static var plusPurchaseFailed: String { return L10n.tr("Localizable", "plus_purchase_failed") }
  /// Become a Plus member and unlock all Pocket Casts features
  internal static var plusPurchasePromoTitle: String { return L10n.tr("Localizable", "plus_purchase_promo_title") }
  /// This feature requires Pocket Casts Plus
  internal static var plusRequiredFeature: String { return L10n.tr("Localizable", "plus_required_feature") }
  /// Select Payment Frequency
  internal static var plusSelectPaymentFrequency: String { return L10n.tr("Localizable", "plus_select_payment_frequency") }
  /// Skip
  internal static var plusSkip: String { return L10n.tr("Localizable", "plus_skip") }
  /// Start my free trial
  internal static var plusStartMyFreeTrial: String { return L10n.tr("Localizable", "plus_start_my_free_trial") }
  /// Try %1$@, then %2$@
  internal static func plusStartTrialDurationPrice(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "plus_start_trial_duration_price", String(describing: p1), String(describing: p2))
  }
  /// Subscribe to Plus
  internal static var plusSubscribeTo: String { return L10n.tr("Localizable", "plus_subscribe_to") }
  /// Your subscription is managed by the Apple App Store
  internal static var plusSubscriptionApple: String { return L10n.tr("Localizable", "plus_subscription_apple") }
  /// To cancel your subscription, you’ll need to cancel via Settings.
  internal static var plusSubscriptionAppleDetails: String { return L10n.tr("Localizable", "plus_subscription_apple_details") }
  /// PLUS EXPIRES IN %1$@
  internal static func plusSubscriptionExpiration(_ p1: Any) -> String {
    return L10n.tr("Localizable", "plus_subscription_expiration", String(describing: p1))
  }
  /// It looks like you subscribed to Pocket Casts Plus from an Android device
  internal static var plusSubscriptionGoogle: String { return L10n.tr("Localizable", "plus_subscription_google") }
  /// To cancel your subscription, you’ll need to cancel via Settings.
  internal static var plusSubscriptionGoogleDetails: String { return L10n.tr("Localizable", "plus_subscription_google_details") }
  /// It looks like you subscribed to Pocket Casts Plus from the web
  internal static var plusSubscriptionWeb: String { return L10n.tr("Localizable", "plus_subscription_web") }
  /// To cancel your subscription, you’ll need to cancel via Pocketcasts.com.
  internal static var plusSubscriptionWebDetails: String { return L10n.tr("Localizable", "plus_subscription_web_details") }
  /// Please check your internet connection and try again.
  internal static var plusUpgradeNoInternetMessage: String { return L10n.tr("Localizable", "plus_upgrade_no_internet_message") }
  /// Unable to Load
  internal static var plusUpgradeNoInternetTitle: String { return L10n.tr("Localizable", "plus_upgrade_no_internet_title") }
  /// %1$@ per year
  internal static func plusYearlyFrequencyPricingFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "plus_yearly_frequency_pricing_format", String(describing: p1))
  }
  /// Pocket Casts Newsletter
  internal static var pocketCastsNewsletter: String { return L10n.tr("Localizable", "pocket_casts_newsletter") }
  /// Receive news, app updates, themed playlists, interviews, and more.
  internal static var pocketCastsNewsletterDescription: String { return L10n.tr("Localizable", "pocket_casts_newsletter_description") }
  /// Pocket Casts Plus
  internal static var pocketCastsPlus: String { return L10n.tr("Localizable", "pocket_casts_plus") }
  /// Plus
  internal static var pocketCastsPlusShort: String { return L10n.tr("Localizable", "pocket_casts_plus_short") }
  /// Get the Newsletter
  internal static var pocketCastsWelcomeNewsletterTitle: String { return L10n.tr("Localizable", "pocket_casts_welcome_newsletter_title") }
  /// Access ended: %1$@
  internal static func podcastAccessEnded(_ p1: Any) -> String {
    return L10n.tr("Localizable", "podcast_access_ended", String(describing: p1))
  }
  /// Access ends: %1$@
  internal static func podcastAccessEnds(_ p1: Any) -> String {
    return L10n.tr("Localizable", "podcast_access_ends", String(describing: p1))
  }
  /// Archive All
  internal static var podcastArchiveAll: String { return L10n.tr("Localizable", "podcast_archive_all") }
  /// Archive All Played
  internal static var podcastArchiveAllPlayed: String { return L10n.tr("Localizable", "podcast_archive_all_played") }
  /// Archive 1 Episode
  internal static var podcastArchiveEpisodeCountSingular: String { return L10n.tr("Localizable", "podcast_archive_episode_count_singular") }
  /// Archive %1$@ Episodes
  internal static func podcastArchiveEpisodesCountPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "podcast_archive_episodes_count_plural_format", String(describing: p1))
  }
  /// You should only do this if you don't want to see them anymore.
  internal static var podcastArchivePromptMsg: String { return L10n.tr("Localizable", "podcast_archive_prompt_msg") }
  /// Archived
  internal static var podcastArchived: String { return L10n.tr("Localizable", "podcast_archived") }
  /// %1$@ archived
  internal static func podcastArchivedCountFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "podcast_archived_count_format", String(describing: p1))
  }
  /// All %1$@ episodes of this podcast have been archived
  internal static func podcastArchivedMsg(_ p1: Any) -> String {
    return L10n.tr("Localizable", "podcast_archived_msg", String(describing: p1))
  }
  /// %1$@ podcasts
  internal static func podcastCountPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "podcast_count_plural_format", String(describing: p1))
  }
  /// 1 podcast
  internal static var podcastCountSingular: String { return L10n.tr("Localizable", "podcast_count_singular") }
  /// Episode download failed
  internal static var podcastDetailsDownloadError: String { return L10n.tr("Localizable", "podcast_details_download_error") }
  /// This episode will automatically download when you're next on WiFi
  internal static var podcastDetailsDownloadWifiQueue: String { return L10n.tr("Localizable", "podcast_details_download_wifi_queue") }
  /// It won't be auto archived by your new episode limit of %1$@
  internal static func podcastDetailsManualUnarchiveMsg(_ p1: Any) -> String {
    return L10n.tr("Localizable", "podcast_details_manual_unarchive_msg", String(describing: p1))
  }
  /// Episode Manually Unarchived
  internal static var podcastDetailsManualUnarchiveTitle: String { return L10n.tr("Localizable", "podcast_details_manual_unarchive_title") }
  /// Unable to play episode
  internal static var podcastDetailsPlaybackError: String { return L10n.tr("Localizable", "podcast_details_playback_error") }
  /// Queued
  internal static var podcastDetailsQueued: String { return L10n.tr("Localizable", "podcast_details_queued") }
  /// REMOVE DOWNLOADED FILE?
  internal static var podcastDetailsRemoveDownload: String { return L10n.tr("Localizable", "podcast_details_remove_download") }
  /// Download Now
  internal static var podcastDownloadNow: String { return L10n.tr("Localizable", "podcast_download_now") }
  /// Downloading... %1$@
  internal static func podcastDownloading(_ p1: Any) -> String {
    return L10n.tr("Localizable", "podcast_downloading", String(describing: p1))
  }
  /// %1$@ episodes
  internal static func podcastEpisodeCountPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "podcast_episode_count_plural_format", String(describing: p1))
  }
  /// 1 episode
  internal static var podcastEpisodeCountSingular: String { return L10n.tr("Localizable", "podcast_episode_count_singular") }
  /// Limited to %1$@
  internal static func podcastEpisodeLimitCountFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "podcast_episode_limit_count_format", String(describing: p1))
  }
  /// Unable to load podcast details :(
  internal static var podcastErrorMessage: String { return L10n.tr("Localizable", "podcast_error_message") }
  /// Literally Can't Even
  internal static var podcastErrorTitle: String { return L10n.tr("Localizable", "podcast_error_title") }
  /// Episode download failed.
  internal static var podcastFailedDownload: String { return L10n.tr("Localizable", "podcast_failed_download") }
  /// Failed to upload
  internal static var podcastFailedUpload: String { return L10n.tr("Localizable", "podcast_failed_upload") }
  /// Discover Podcasts
  internal static var podcastGridDiscoverPodcasts: String { return L10n.tr("Localizable", "podcast_grid_discover_podcasts") }
  /// Coming from another app? Import your podcasts via Profile > Settings > Import & Export.
  /// 
  /// 
  /// If you're looking for inspiration try the Discover tab.
  internal static var podcastGridNoPodcastsMsg: String { return L10n.tr("Localizable", "podcast_grid_no_podcasts_msg") }
  /// Time to add some Podcasts!
  internal static var podcastGridNoPodcastsTitle: String { return L10n.tr("Localizable", "podcast_grid_no_podcasts_title") }
  /// GROUP BY
  internal static var podcastGroupOptionsTitle: String { return L10n.tr("Localizable", "podcast_group_options_title") }
  /// Hide Archived
  internal static var podcastHideArchived: String { return L10n.tr("Localizable", "podcast_hide_archived") }
  /// Limited to %1$@ most recent episodes
  internal static func podcastLimitPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "podcast_limit_plural_format", String(describing: p1))
  }
  /// Limited to 1 most recent episode
  internal static var podcastLimitSingular: String { return L10n.tr("Localizable", "podcast_limit_singular") }
  /// Loading Podcast...
  internal static var podcastLoading: String { return L10n.tr("Localizable", "podcast_loading") }
  /// Date Not Set
  internal static var podcastNoDate: String { return L10n.tr("Localizable", "podcast_no_date") }
  /// No Season
  internal static var podcastNoSeason: String { return L10n.tr("Localizable", "podcast_no_season") }
  /// Pause download
  internal static var podcastPauseDownload: String { return L10n.tr("Localizable", "podcast_pause_download") }
  /// Pause playback
  internal static var podcastPausePlayback: String { return L10n.tr("Localizable", "podcast_pause_playback") }
  /// Queued
  internal static var podcastQueued: String { return L10n.tr("Localizable", "podcast_queued") }
  /// Queued...
  internal static var podcastQueuing: String { return L10n.tr("Localizable", "podcast_queuing") }
  /// Refresh Artwork
  internal static var podcastRefreshArtwork: String { return L10n.tr("Localizable", "podcast_refresh_artwork") }
  /// Season %1$@
  internal static func podcastSeasonFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "podcast_season_format", String(describing: p1))
  }
  /// Share Link to Episode
  internal static var podcastShareEpisode: String { return L10n.tr("Localizable", "podcast_share_episode") }
  /// You don't have any apps installed that will accept this file
  internal static var podcastShareEpisodeErrorMsg: String { return L10n.tr("Localizable", "podcast_share_episode_error_msg") }
  /// The podcast author may have removed it since this link was shared.
  internal static var podcastShareErrorMsg: String { return L10n.tr("Localizable", "podcast_share_error_msg") }
  /// Unable To Find Episode
  internal static var podcastShareErrorTitle: String { return L10n.tr("Localizable", "podcast_share_error_title") }
  /// Creating list...
  internal static var podcastShareListCreating: String { return L10n.tr("Localizable", "podcast_share_list_creating") }
  /// Description (optional)
  internal static var podcastShareListDescription: String { return L10n.tr("Localizable", "podcast_share_list_description") }
  /// List Name
  internal static var podcastShareListName: String { return L10n.tr("Localizable", "podcast_share_list_name") }
  /// Open File in...
  internal static var podcastShareOpenFile: String { return L10n.tr("Localizable", "podcast_share_open_file") }
  /// Show Archived
  internal static var podcastShowArchived: String { return L10n.tr("Localizable", "podcast_show_archived") }
  /// Podcast
  internal static var podcastSingular: String { return L10n.tr("Localizable", "podcast_singular") }
  /// Any day now
  internal static var podcastSoon: String { return L10n.tr("Localizable", "podcast_soon") }
  /// SORT ORDER
  internal static var podcastSortOrderTitle: String { return L10n.tr("Localizable", "podcast_sort_order_title") }
  /// Stream Anyway
  internal static var podcastStreamConfirmation: String { return L10n.tr("Localizable", "podcast_stream_confirmation") }
  /// Streaming this episode will use data
  internal static var podcastStreamDataWarning: String { return L10n.tr("Localizable", "podcast_stream_data_warning") }
  /// This Month
  internal static var podcastThisMonth: String { return L10n.tr("Localizable", "podcast_this_month") }
  /// %1$@ left
  internal static func podcastTimeLeft(_ p1: Any) -> String {
    return L10n.tr("Localizable", "podcast_time_left", String(describing: p1))
  }
  /// Tomorrow
  internal static var podcastTomorrow: String { return L10n.tr("Localizable", "podcast_tomorrow") }
  /// Unarchive All
  internal static var podcastUnarchiveAll: String { return L10n.tr("Localizable", "podcast_unarchive_all") }
  /// Updates ended: %1$@
  internal static func podcastUpdatesEnded(_ p1: Any) -> String {
    return L10n.tr("Localizable", "podcast_updates_ended", String(describing: p1))
  }
  /// Updates ends: %1$@
  internal static func podcastUpdatesEnds(_ p1: Any) -> String {
    return L10n.tr("Localizable", "podcast_updates_ends", String(describing: p1))
  }
  /// Upload Now
  internal static var podcastUploadConfirmation: String { return L10n.tr("Localizable", "podcast_upload_confirmation") }
  /// Uploading... %1$@
  internal static func podcastUploading(_ p1: Any) -> String {
    return L10n.tr("Localizable", "podcast_uploading", String(describing: p1))
  }
  /// Waiting to upload
  internal static var podcastWaitingUpload: String { return L10n.tr("Localizable", "podcast_waiting_upload") }
  /// Yesterday
  internal static var podcastYesterday: String { return L10n.tr("Localizable", "podcast_yesterday") }
  /// Unfinished Episodes
  internal static var podcastsBadgeAllUnplayed: String { return L10n.tr("Localizable", "podcasts_badge_all_unplayed") }
  /// Only Latest Episode
  internal static var podcastsBadgeLatestEpisode: String { return L10n.tr("Localizable", "podcasts_badge_latest_episode") }
  /// Badges
  internal static var podcastsBadges: String { return L10n.tr("Localizable", "podcasts_badges") }
  /// Longest to Shortest
  internal static var podcastsEpisodeSortLongestToShortest: String { return L10n.tr("Localizable", "podcasts_episode_sort_longest_to_shortest") }
  /// Newest to oldest
  internal static var podcastsEpisodeSortNewestToOldest: String { return L10n.tr("Localizable", "podcasts_episode_sort_newest_to_oldest") }
  /// Oldest to newest
  internal static var podcastsEpisodeSortOldestToNewest: String { return L10n.tr("Localizable", "podcasts_episode_sort_oldest_to_newest") }
  /// Shortest to Longest
  internal static var podcastsEpisodeSortShortestToLongest: String { return L10n.tr("Localizable", "podcasts_episode_sort_shortest_to_longest") }
  /// Large Grid
  internal static var podcastsLargeGrid: String { return L10n.tr("Localizable", "podcasts_large_grid") }
  /// Layout
  internal static var podcastsLayout: String { return L10n.tr("Localizable", "podcasts_layout") }
  /// Drag and Drop
  internal static var podcastsLibrarySortCustom: String { return L10n.tr("Localizable", "podcasts_library_sort_custom") }
  /// Date Added
  internal static var podcastsLibrarySortDateAdded: String { return L10n.tr("Localizable", "podcasts_library_sort_date_added") }
  /// Episode Release Date
  internal static var podcastsLibrarySortEpisodeReleaseDate: String { return L10n.tr("Localizable", "podcasts_library_sort_episode_release_date") }
  /// Name
  internal static var podcastsLibrarySortTitle: String { return L10n.tr("Localizable", "podcasts_library_sort_title") }
  /// List
  internal static var podcastsList: String { return L10n.tr("Localizable", "podcasts_list") }
  /// Podcasts
  internal static var podcastsPlural: String { return L10n.tr("Localizable", "podcasts_plural") }
  /// Share Podcasts
  internal static var podcastsShare: String { return L10n.tr("Localizable", "podcasts_share") }
  /// Small Grid
  internal static var podcastsSmallGrid: String { return L10n.tr("Localizable", "podcasts_small_grid") }
  /// Sort Podcasts
  internal static var podcastsSort: String { return L10n.tr("Localizable", "podcasts_sort") }
  /// Preview
  internal static var preview: String { return L10n.tr("Localizable", "preview") }
  /// then %1$@
  internal static func pricingTermsAfterTrial(_ p1: Any) -> String {
    return L10n.tr("Localizable", "pricing_terms_after_trial", String(describing: p1))
  }
  /// Recurring payments will begin after your
  /// %1$@ free trial
  internal static func pricingTermsAfterTrialLong(_ p1: Any) -> String {
    return L10n.tr("Localizable", "pricing_terms_after_trial_long", String(describing: p1))
  }
  /// Profile
  internal static var profile: String { return L10n.tr("Localizable", "profile") }
  /// Help support Pocket Casts by upgrading your account
  internal static var profileHelpSupport: String { return L10n.tr("Localizable", "profile_help_support") }
  /// App last refreshed %1$@
  internal static func profileLastAppRefresh(_ p1: Any) -> String {
    return L10n.tr("Localizable", "profile_last_app_refresh", String(describing: p1))
  }
  /// %1$@ Files
  internal static func profileNumberOfFiles(_ p1: Any) -> String {
    return L10n.tr("Localizable", "profile_number_of_files", String(describing: p1))
  }
  /// %1$@ Full
  internal static func profilePercentFull(_ p1: Any) -> String {
    return L10n.tr("Localizable", "profile_percent_full", String(describing: p1))
  }
  /// Reset Password
  internal static var profileResetPassword: String { return L10n.tr("Localizable", "profile_reset_password") }
  /// Sending Reset Email
  internal static var profileSendingResetEmail: String { return L10n.tr("Localizable", "profile_sending_reset_email") }
  /// Check your email :)
  internal static var profileSendingResetEmailConfMsg: String { return L10n.tr("Localizable", "profile_sending_reset_email_conf_msg") }
  /// Password Reset Link Sent
  internal static var profileSendingResetEmailConfTitle: String { return L10n.tr("Localizable", "profile_sending_reset_email_conf_title") }
  /// Failed to send reset email, please try again later.
  internal static var profileSendingResetEmailFailed: String { return L10n.tr("Localizable", "profile_sending_reset_email_failed") }
  /// 1 File
  internal static var profileSingleFile: String { return L10n.tr("Localizable", "profile_single_file") }
  /// You haven't starred any episodes yet.
  internal static var profileStarredNoEpisodesDesc: String { return L10n.tr("Localizable", "profile_starred_no_episodes_desc") }
  /// Nothing Starred
  internal static var profileStarredNoEpisodesTitle: String { return L10n.tr("Localizable", "profile_starred_no_episodes_title") }
  /// By continuing, you agree to %1$@Privacy Policy%2$@ and %3$@Terms and Conditions%4$@
  internal static func purchaseTerms(_ p1: Any, _ p2: Any, _ p3: Any, _ p4: Any) -> String {
    return L10n.tr("Localizable", "purchase_terms", String(describing: p1), String(describing: p2), String(describing: p3), String(describing: p4))
  }
  /// Clear %1$@ Episodes
  internal static func queueClearEpisodeQueuePlural(_ p1: Any) -> String {
    return L10n.tr("Localizable", "queue_clear_episode_queue_plural", String(describing: p1))
  }
  /// CLEAR QUEUE
  internal static var queueClearQueue: String { return L10n.tr("Localizable", "queue_clear_queue") }
  /// Queue For Later
  internal static var queueForLater: String { return L10n.tr("Localizable", "queue_for_later") }
  /// Now Playing. %1$@
  internal static func queueNowPlayingAccessibility(_ p1: Any) -> String {
    return L10n.tr("Localizable", "queue_now_playing_accessibility", String(describing: p1))
  }
  /// %1$@ remaining
  internal static func queueTimeRemaining(_ p1: Any) -> String {
    return L10n.tr("Localizable", "queue_time_remaining", String(describing: p1))
  }
  /// %1$@ total time remaining
  internal static func queueTotalTimeRemaining(_ p1: Any) -> String {
    return L10n.tr("Localizable", "queue_total_time_remaining", String(describing: p1))
  }
  /// Rate
  internal static var rate: String { return L10n.tr("Localizable", "rate") }
  /// Ops! There was an error.
  internal static var ratingError: String { return L10n.tr("Localizable", "rating_error") }
  /// Only listeners of this podcast can give it a rating. Have a listen to a few episodes and then come back to give your rating. We look forward to hearing what you think!
  internal static var ratingListenToThisPodcastMessage: String { return L10n.tr("Localizable", "rating_listen_to_this_podcast_message") }
  /// Please listen to this podcast first
  internal static var ratingListenToThisPodcastTitle: String { return L10n.tr("Localizable", "rating_listen_to_this_podcast_title") }
  /// Your rating was submitted!
  internal static var ratingSubmitted: String { return L10n.tr("Localizable", "rating_submitted") }
  /// Rate %1$@
  internal static func ratingTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "rating_title", String(describing: p1))
  }
  /// FINDING NEW PODCAST EPISODES
  internal static var refreshControlFetchingEpisodes: String { return L10n.tr("Localizable", "refresh_control_fetching_episodes") }
  /// PULL TO REFRESH
  internal static var refreshControlPullToRefresh: String { return L10n.tr("Localizable", "refresh_control_pull_to_refresh") }
  /// REFRESH COMPLETE
  internal static var refreshControlRefreshComplete: String { return L10n.tr("Localizable", "refresh_control_refresh_complete") }
  /// REFRESH FAILED :(
  internal static var refreshControlRefreshFailed: String { return L10n.tr("Localizable", "refresh_control_refresh_failed") }
  /// REFRESHING FILES
  internal static var refreshControlRefreshingFiles: String { return L10n.tr("Localizable", "refresh_control_refreshing_files") }
  /// RELEASE TO REFRESH
  internal static var refreshControlReleaseToRefresh: String { return L10n.tr("Localizable", "refresh_control_release_to_refresh") }
  /// SYNC FAILED :(
  internal static var refreshControlSyncFailed: String { return L10n.tr("Localizable", "refresh_control_sync_failed") }
  /// SYNCING PODCASTS AND PROGRESS
  internal static var refreshControlSyncingPodcasts: String { return L10n.tr("Localizable", "refresh_control_syncing_podcasts") }
  /// Refresh failed
  internal static var refreshFailed: String { return L10n.tr("Localizable", "refresh_failed") }
  /// Refresh Now
  internal static var refreshNow: String { return L10n.tr("Localizable", "refresh_now") }
  /// Last refresh: %1$@
  internal static func refreshPreviousRun(_ p1: Any) -> String {
    return L10n.tr("Localizable", "refresh_previous_run", String(describing: p1))
  }
  /// Refreshing...
  internal static var refreshing: String { return L10n.tr("Localizable", "refreshing") }
  /// Daily
  internal static var releaseFrequencyDaily: String { return L10n.tr("Localizable", "release_frequency_daily") }
  /// Fortnightly
  internal static var releaseFrequencyFortnightly: String { return L10n.tr("Localizable", "release_frequency_fortnightly") }
  /// Hourly
  internal static var releaseFrequencyHourly: String { return L10n.tr("Localizable", "release_frequency_hourly") }
  /// Monthly
  internal static var releaseFrequencyMonthly: String { return L10n.tr("Localizable", "release_frequency_monthly") }
  /// Weekly
  internal static var releaseFrequencyWeekly: String { return L10n.tr("Localizable", "release_frequency_weekly") }
  /// Remove
  internal static var remove: String { return L10n.tr("Localizable", "remove") }
  /// Remove All
  internal static var removeAll: String { return L10n.tr("Localizable", "remove_all") }
  /// Remove Download
  internal static var removeDownload: String { return L10n.tr("Localizable", "remove_download") }
  /// Remove From Up Next
  internal static var removeFromUpNext: String { return L10n.tr("Localizable", "remove_from_up_next") }
  /// Remove Up Next
  internal static var removeUpNext: String { return L10n.tr("Localizable", "remove_up_next") }
  /// Renew your Subscription
  internal static var renewSubscription: String { return L10n.tr("Localizable", "renew_subscription") }
  /// Retry
  internal static var retry: String { return L10n.tr("Localizable", "retry") }
  /// Save Bookmark
  internal static var saveBookmark: String { return L10n.tr("Localizable", "save_bookmark") }
  /// Search
  internal static var search: String { return L10n.tr("Localizable", "search") }
  /// Search podcasts or add RSS URL
  internal static var searchLabel: String { return L10n.tr("Localizable", "search_label") }
  /// Search Podcasts
  internal static var searchPodcasts: String { return L10n.tr("Localizable", "search_podcasts") }
  /// Recent searches
  internal static var searchRecent: String { return L10n.tr("Localizable", "search_recent") }
  /// Season
  internal static var season: String { return L10n.tr("Localizable", "season") }
  /// S%1$@ E%2$@
  internal static func seasonEpisodeShorthandFormat(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "season_episode_shorthand_format", String(describing: p1), String(describing: p2))
  }
  /// S%1$@
  internal static func seasonOnlyShorthandFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "season_only_shorthand_format", String(describing: p1))
  }
  /// Seconds listened
  internal static var secondsListened: String { return L10n.tr("Localizable", "seconds_listened") }
  /// Seconds saved
  internal static var secondsSaved: String { return L10n.tr("Localizable", "seconds_saved") }
  /// Select
  internal static var select: String { return L10n.tr("Localizable", "select") }
  /// Select All
  internal static var selectAll: String { return L10n.tr("Localizable", "select_all") }
  /// Select all above
  internal static var selectAllAbove: String { return L10n.tr("Localizable", "select_all_above") }
  /// Select all below
  internal static var selectAllBelow: String { return L10n.tr("Localizable", "select_all_below") }
  /// Select Bookmarks
  internal static var selectBookmarks: String { return L10n.tr("Localizable", "select_bookmarks") }
  /// Select Episodes
  internal static var selectEpisodes: String { return L10n.tr("Localizable", "select_episodes") }
  /// %1$@ selected
  internal static func selectedCountFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "selected_count_format", String(describing: p1))
  }
  /// This file is too big too upload.
  internal static var serverErrorFilesFileTooLarge: String { return L10n.tr("Localizable", "server_error_files_file_too_large") }
  /// Unable to upload, as we're unable to determine the content type of this file.
  internal static var serverErrorFilesInvalidContentType: String { return L10n.tr("Localizable", "server_error_files_invalid_content_type") }
  /// User is not logged in.
  internal static var serverErrorFilesInvalidUser: String { return L10n.tr("Localizable", "server_error_files_invalid_user") }
  /// You have exceeded the storage limit for your account.
  internal static var serverErrorFilesStorageLimitExceeded: String { return L10n.tr("Localizable", "server_error_files_storage_limit_exceeded") }
  /// Title is required.
  internal static var serverErrorFilesTitleRequired: String { return L10n.tr("Localizable", "server_error_files_title_required") }
  /// Unable to upload file, please try again later.
  internal static var serverErrorFilesUploadFailedGeneric: String { return L10n.tr("Localizable", "server_error_files_upload_failed_generic") }
  /// File uuid is required.
  internal static var serverErrorFilesUuidRequired: String { return L10n.tr("Localizable", "server_error_files_uuid_required") }
  /// Your account has been locked due too many login attempts, please try again later.
  internal static var serverErrorLoginAccountLocked: String { return L10n.tr("Localizable", "server_error_login_account_locked") }
  /// Enter an email address.
  internal static var serverErrorLoginEmailBlank: String { return L10n.tr("Localizable", "server_error_login_email_blank") }
  /// Invalid email
  internal static var serverErrorLoginEmailInvalid: String { return L10n.tr("Localizable", "server_error_login_email_invalid") }
  /// Email not found
  internal static var serverErrorLoginEmailNotFound: String { return L10n.tr("Localizable", "server_error_login_email_not_found") }
  /// Email taken
  internal static var serverErrorLoginEmailTaken: String { return L10n.tr("Localizable", "server_error_login_email_taken") }
  /// Enter a password.
  internal static var serverErrorLoginPasswordBlank: String { return L10n.tr("Localizable", "server_error_login_password_blank") }
  /// Incorrect password
  internal static var serverErrorLoginPasswordIncorrect: String { return L10n.tr("Localizable", "server_error_login_password_incorrect") }
  /// Invalid password
  internal static var serverErrorLoginPasswordInvalid: String { return L10n.tr("Localizable", "server_error_login_password_invalid") }
  /// Permission denied
  internal static var serverErrorLoginPermissionDeniedNotAdmin: String { return L10n.tr("Localizable", "server_error_login_permission_denied_not_admin") }
  /// We couldn't set up that account, sorry.
  internal static var serverErrorLoginUnableToCreateAccount: String { return L10n.tr("Localizable", "server_error_login_unable_to_create_account") }
  /// Unable to create account, please try again later
  internal static var serverErrorLoginUserRegisterFailed: String { return L10n.tr("Localizable", "server_error_login_user_register_failed") }
  /// You are already a Pocket Casts Plus subscriber, there's no need to redeem any codes.
  internal static var serverErrorPromoAlreadyPlus: String { return L10n.tr("Localizable", "server_error_promo_already_plus") }
  /// You have already claimed this promo code. It was worth a shot though!
  internal static var serverErrorPromoAlreadyRedeemed: String { return L10n.tr("Localizable", "server_error_promo_already_redeemed") }
  /// This promo code has expired or is invalid.
  internal static var serverErrorPromoCodeExpiredOrInvalid: String { return L10n.tr("Localizable", "server_error_promo_code_expired_or_invalid") }
  /// Something went wrong
  internal static var serverErrorUnknown: String { return L10n.tr("Localizable", "server_error_unknown") }
  /// Thanks for signing up!
  internal static var serverMessageLoginThanksSigningUp: String { return L10n.tr("Localizable", "server_message_login_thanks_signing_up") }
  /// Settings
  internal static var settings: String { return L10n.tr("Localizable", "settings") }
  /// About
  internal static var settingsAbout: String { return L10n.tr("Localizable", "settings_about") }
  /// Appearance
  internal static var settingsAppearance: String { return L10n.tr("Localizable", "settings_appearance") }
  /// Inactive Episodes
  internal static var settingsArchiveInactiveEpisodes: String { return L10n.tr("Localizable", "settings_archive_inactive_episodes") }
  /// Archive Inactive
  internal static var settingsArchiveInactiveTitle: String { return L10n.tr("Localizable", "settings_archive_inactive_title") }
  /// Played Episodes
  internal static var settingsArchivePlayedEpisodes: String { return L10n.tr("Localizable", "settings_archive_played_episodes") }
  /// Archive Played
  internal static var settingsArchivePlayedTitle: String { return L10n.tr("Localizable", "settings_archive_played_title") }
  /// Auto Add to Up Next
  internal static var settingsAutoAdd: String { return L10n.tr("Localizable", "settings_auto_add") }
  /// Auto Add Limit
  internal static var settingsAutoAddLimit: String { return L10n.tr("Localizable", "settings_auto_add_limit") }
  /// If Limit Reached
  internal static var settingsAutoAddLimitReached: String { return L10n.tr("Localizable", "settings_auto_add_limit_reached") }
  /// New episodes will stop being added when Up Next reaches %1$@ episodes.
  internal static func settingsAutoAddLimitSubtitleStop(_ p1: Any) -> String {
    return L10n.tr("Localizable", "settings_auto_add_limit_subtitle_stop", String(describing: p1))
  }
  /// When Up Next reaches %1$@, new episodes auto-added to the top will remove the last episode in the queue. No new episodes will be added to the bottom.
  internal static func settingsAutoAddLimitSubtitleTop(_ p1: Any) -> String {
    return L10n.tr("Localizable", "settings_auto_add_limit_subtitle_top", String(describing: p1))
  }
  /// Auto-Add Podcasts
  internal static var settingsAutoAddPodcasts: String { return L10n.tr("Localizable", "settings_auto_add_podcasts") }
  /// Auto Archive
  internal static var settingsAutoArchive: String { return L10n.tr("Localizable", "settings_auto_archive") }
  /// After 1 Week
  internal static var settingsAutoArchive1Week: String { return L10n.tr("Localizable", "settings_auto_archive_1_week") }
  /// After 24 Hours
  internal static var settingsAutoArchive24Hours: String { return L10n.tr("Localizable", "settings_auto_archive_24_hours") }
  /// After 2 Days
  internal static var settingsAutoArchive2Days: String { return L10n.tr("Localizable", "settings_auto_archive_2_days") }
  /// After 2 Weeks
  internal static var settingsAutoArchive2Weeks: String { return L10n.tr("Localizable", "settings_auto_archive_2_weeks") }
  /// After 30 Days
  internal static var settingsAutoArchive30Days: String { return L10n.tr("Localizable", "settings_auto_archive_30_days") }
  /// After 3 Months
  internal static var settingsAutoArchive3Months: String { return L10n.tr("Localizable", "settings_auto_archive_3_months") }
  /// Include Starred Episodes
  internal static var settingsAutoArchiveIncludeStarred: String { return L10n.tr("Localizable", "settings_auto_archive_include_starred") }
  /// Starred episodes won't be auto archived
  internal static var settingsAutoArchiveIncludeStarredOffSubtitle: String { return L10n.tr("Localizable", "settings_auto_archive_include_starred_off_subtitle") }
  /// Starred episodes will be auto archived
  internal static var settingsAutoArchiveIncludeStarredOnSubtitle: String { return L10n.tr("Localizable", "settings_auto_archive_include_starred_on_subtitle") }
  /// Archive episodes after set time limits. Downloads are removed when the episode is archived.
  internal static var settingsAutoArchiveSubtitle: String { return L10n.tr("Localizable", "settings_auto_archive_subtitle") }
  /// Auto Download
  internal static var settingsAutoDownload: String { return L10n.tr("Localizable", "settings_auto_download") }
  /// %1$@ filters selected
  internal static func settingsAutoDownloadsFiltersSelectedFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "settings_auto_downloads_filters_selected_format", String(describing: p1))
  }
  /// 1 filter selected
  internal static var settingsAutoDownloadsFiltersSelectedSingular: String { return L10n.tr("Localizable", "settings_auto_downloads_filters_selected_singular") }
  /// No Filters Selected
  internal static var settingsAutoDownloadsNoFiltersSelected: String { return L10n.tr("Localizable", "settings_auto_downloads_no_filters_selected") }
  /// No Podcasts Selected
  internal static var settingsAutoDownloadsNoPodcastsSelected: String { return L10n.tr("Localizable", "settings_auto_downloads_no_podcasts_selected") }
  /// %1$@ podcasts selected
  internal static func settingsAutoDownloadsPodcastsSelectedFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "settings_auto_downloads_podcasts_selected_format", String(describing: p1))
  }
  /// 1 podcast selected
  internal static var settingsAutoDownloadsPodcastsSelectedSingular: String { return L10n.tr("Localizable", "settings_auto_downloads_podcasts_selected_singular") }
  /// Download the top episodes in a filter.
  internal static var settingsAutoDownloadsSubtitleFilters: String { return L10n.tr("Localizable", "settings_auto_downloads_subtitle_filters") }
  /// Download new episodes when they are released.
  internal static var settingsAutoDownloadsSubtitleNewEpisodes: String { return L10n.tr("Localizable", "settings_auto_downloads_subtitle_new_episodes") }
  /// Download episodes added to Up Next.
  internal static var settingsAutoDownloadsSubtitleUpNext: String { return L10n.tr("Localizable", "settings_auto_downloads_subtitle_up_next") }
  /// EPISODE FILTER COUNT
  internal static var settingsBadgeFilterHeader: String { return L10n.tr("Localizable", "settings_badge_filter_header") }
  /// New Since App Opened
  internal static var settingsBadgeNewSinceOpened: String { return L10n.tr("Localizable", "settings_badge_new_since_opened") }
  /// Total Unplayed
  internal static var settingsBadgeTotalUnplayed: String { return L10n.tr("Localizable", "settings_badge_total_unplayed") }
  /// Bookmark Confirmation Sound
  internal static var settingsBookmarkConfirmationSound: String { return L10n.tr("Localizable", "settings_bookmark_confirmation_sound") }
  /// Play a confirmation sound after creating a bookmark with your headphones.
  internal static var settingsBookmarkSoundFooter: String { return L10n.tr("Localizable", "settings_bookmark_sound_footer") }
  /// Collect information
  internal static var settingsCollectInformation: String { return L10n.tr("Localizable", "settings_collect_information") }
  /// Allowing us to collect analytics helps us build a better app. We understand if you would prefer not to share this information.
  internal static var settingsCollectInformationAdditionalInformation: String { return L10n.tr("Localizable", "settings_collect_information_additional_information") }
  /// Connection Status
  internal static var settingsConnectionStatus: String { return L10n.tr("Localizable", "settings_connection_status") }
  /// Create Siri Shortcut
  internal static var settingsCreateSiriShortcut: String { return L10n.tr("Localizable", "settings_create_siri_shortcut") }
  /// Create a Siri Shortcut to play the newest episode of %1$@
  internal static func settingsCreateSiriShortcutMsg(_ p1: Any) -> String {
    return L10n.tr("Localizable", "settings_create_siri_shortcut_msg", String(describing: p1))
  }
  /// Custom For This Podcast
  internal static var settingsCustom: String { return L10n.tr("Localizable", "settings_custom") }
  /// Need more fine grained control? Enable auto-archive settings for this podcast
  internal static var settingsCustomAutoArchiveMsg: String { return L10n.tr("Localizable", "settings_custom_auto_archive_msg") }
  /// Pocket Casts will remember your last playback effects and use them on all podcasts. You can enable this if you want to create custom ones for just this podcast.
  internal static var settingsCustomMsg: String { return L10n.tr("Localizable", "settings_custom_msg") }
  /// Episode Limit
  internal static var settingsEpisodeLimit: String { return L10n.tr("Localizable", "settings_episode_limit") }
  /// %1$@ Episode Limit
  internal static func settingsEpisodeLimitFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "settings_episode_limit_format", String(describing: p1))
  }
  /// %1$@ most recent
  internal static func settingsEpisodeLimitLimitFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "settings_episode_limit_limit_format", String(describing: p1))
  }
  /// For shows that release hourly or daily episodes, setting an episode limit can help keep only the most recent ones, while archiving any that are older.
  internal static var settingsEpisodeLimitMsg: String { return L10n.tr("Localizable", "settings_episode_limit_msg") }
  /// No Limit
  internal static var settingsEpisodeLimitNoLimit: String { return L10n.tr("Localizable", "settings_episode_limit_no_limit") }
  /// Export Error
  internal static var settingsExportError: String { return L10n.tr("Localizable", "settings_export_error") }
  /// Unable to export OPML, please try again later.
  internal static var settingsExportErrorMsg: String { return L10n.tr("Localizable", "settings_export_error_msg") }
  /// Exporting OPML
  internal static var settingsExportOpml: String { return L10n.tr("Localizable", "settings_export_opml") }
  /// Feed Error
  internal static var settingsFeedError: String { return L10n.tr("Localizable", "settings_feed_error") }
  /// The feed for this podcast stopped updating because it had too many errors. Tap above to fix this.
  internal static var settingsFeedErrorMsg: String { return L10n.tr("Localizable", "settings_feed_error_msg") }
  /// Try To Update It
  internal static var settingsFeedFixRefresh: String { return L10n.tr("Localizable", "settings_feed_fix_refresh") }
  /// Unable to update this feed, please try again later.
  internal static var settingsFeedFixRefreshFailedMsg: String { return L10n.tr("Localizable", "settings_feed_fix_refresh_failed_msg") }
  /// Update Failed
  internal static var settingsFeedFixRefreshFailedTitle: String { return L10n.tr("Localizable", "settings_feed_fix_refresh_failed_title") }
  /// We've queued an update for this podcast. Our server will re-check it and if it works you should have new episodes soon. Please check back in about an hour.
  internal static var settingsFeedFixRefreshSuccessMsg: String { return L10n.tr("Localizable", "settings_feed_fix_refresh_success_msg") }
  /// Update Queued
  internal static var settingsFeedFixRefreshSuccessTitle: String { return L10n.tr("Localizable", "settings_feed_fix_refresh_success_title") }
  /// Feed Issue
  internal static var settingsFeedIssue: String { return L10n.tr("Localizable", "settings_feed_issue") }
  /// The feed for this podcast stopped updating because it had too many errors.
  internal static var settingsFeedIssueMsg: String { return L10n.tr("Localizable", "settings_feed_issue_msg") }
  /// Files Settings
  internal static var settingsFiles: String { return L10n.tr("Localizable", "settings_files") }
  /// Add new files to Up Next automatically
  internal static var settingsFilesAddUpNextSubtitle: String { return L10n.tr("Localizable", "Settings_files_add_up_next_subtitle") }
  /// Auto Download from Cloud
  internal static var settingsFilesAutoDownload: String { return L10n.tr("Localizable", "settings_files_auto_download") }
  /// Files added to the cloud from other devices will not be automatically downloaded.
  internal static var settingsFilesAutoDownloadSubtitleOff: String { return L10n.tr("Localizable", "settings_files_auto_download_subtitle_off") }
  /// Files added to the cloud from other devices will be automatically downloaded.
  internal static var settingsFilesAutoDownloadSubtitleOn: String { return L10n.tr("Localizable", "settings_files_auto_download_subtitle_on") }
  /// Auto Upload to Cloud
  internal static var settingsFilesAutoUpload: String { return L10n.tr("Localizable", "settings_files_auto_upload") }
  /// Files added to this device will not be automatically uploaded to the Cloud.
  internal static var settingsFilesAutoUploadSubtitleOff: String { return L10n.tr("Localizable", "settings_files_auto_upload_subtitle_off") }
  /// Files added to this device will be automatically uploaded to the Cloud.
  internal static var settingsFilesAutoUploadSubtitleOn: String { return L10n.tr("Localizable", "settings_files_auto_upload_subtitle_on") }
  /// Delete Cloud File
  internal static var settingsFilesDeleteCloudFile: String { return L10n.tr("Localizable", "settings_files_delete_cloud_file") }
  /// Delete Local File
  internal static var settingsFilesDeleteLocalFile: String { return L10n.tr("Localizable", "settings_files_delete_local_file") }
  /// General
  internal static var settingsGeneral: String { return L10n.tr("Localizable", "settings_general") }
  /// Apply to existing
  internal static var settingsGeneralApplyAllConf: String { return L10n.tr("Localizable", "settings_general_apply_all_conf") }
  /// Apply to existing podcasts?
  internal static var settingsGeneralApplyAllTitle: String { return L10n.tr("Localizable", "settings_general_apply_all_title") }
  /// Archived Episodes
  internal static var settingsGeneralArchivedEpisodes: String { return L10n.tr("Localizable", "settings_general_archived_episodes") }
  /// Would you like to change all your existing podcasts to %1$@ archived episodes?
  internal static func settingsGeneralArchivedEpisodesPromptFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "settings_general_archived_episodes_prompt_format", String(describing: p1))
  }
  /// Open Player Automatically
  internal static var settingsGeneralAutoOpenPlayer: String { return L10n.tr("Localizable", "settings_general_auto_open_player") }
  /// Autoplay
  internal static var settingsGeneralAutoplay: String { return L10n.tr("Localizable", "settings_general_autoplay") }
  /// If your Up Next queue is empty, we'll play episodes from the same podcast or list you're currently listening to.
  internal static var settingsGeneralAutoplaySubtitle: String { return L10n.tr("Localizable", "settings_general_autoplay_subtitle") }
  /// DEFAULTS
  internal static var settingsGeneralDefaultsHeader: String { return L10n.tr("Localizable", "settings_general_defaults_header") }
  /// Podcast Episode Grouping
  internal static var settingsGeneralEpisodeGroups: String { return L10n.tr("Localizable", "settings_general_episode_groups") }
  /// Hide
  internal static var settingsGeneralHide: String { return L10n.tr("Localizable", "settings_general_hide") }
  /// Keep Screen Awake
  internal static var settingsGeneralKeepScreenAwake: String { return L10n.tr("Localizable", "settings_general_keep_screen_awake") }
  /// Legacy Bluetooth Support
  internal static var settingsGeneralLegacyBluetooth: String { return L10n.tr("Localizable", "settings_general_legacy_bluetooth") }
  /// If you have a Bluetooth Device or Car Stereo that seems to be pausing Pocket Casts while it's playing, or resetting the playback position to 0, try turning this setting on to fix it.
  internal static var settingsGeneralLegacyBluetoothSubtitle: String { return L10n.tr("Localizable", "settings_general_legacy_bluetooth_subtitle") }
  /// Multi-select Gesture
  internal static var settingsGeneralMultiSelectGesture: String { return L10n.tr("Localizable", "settings_general_multi_select_gesture") }
  /// Multi-select by dragging 2 fingers down on any episode list. Turn this off if you find yourself triggering this accidentally or it interferes with the accessibility features you use.
  internal static var settingsGeneralMultiSelectGestureSubtitle: String { return L10n.tr("Localizable", "settings_general_multi_select_gesture_subtitle") }
  /// No thanks
  internal static var settingsGeneralNoThanks: String { return L10n.tr("Localizable", "settings_general_no_thanks") }
  /// Open Links In Browser
  internal static var settingsGeneralOpenInBrowser: String { return L10n.tr("Localizable", "settings_general_open_in_browser") }
  /// Extra Playback Actions
  internal static var settingsGeneralPlayBackActions: String { return L10n.tr("Localizable", "settings_general_play_back_actions") }
  /// Adds a mark played and star option to your phone lock screen and CarPlay. Note: on the lock screen this will replace the skip back button.
  internal static var settingsGeneralPlayBackActionsSubtitle: String { return L10n.tr("Localizable", "settings_general_play_back_actions_subtitle") }
  /// PLAYER
  internal static var settingsGeneralPlayerHeader: String { return L10n.tr("Localizable", "settings_general_player_header") }
  /// Publish Chapter Titles
  internal static var settingsGeneralPublishChapterTitles: String { return L10n.tr("Localizable", "settings_general_publish_chapter_titles") }
  /// If on, this will send chapter titles over Bluetooth and other connected devices instead of the episode title.
  internal static var settingsGeneralPublishChapterTitlesSubtitle: String { return L10n.tr("Localizable", "settings_general_publish_chapter_titles_subtitle") }
  /// Remote Skips Chapters
  internal static var settingsGeneralRemoteSkipsChapters: String { return L10n.tr("Localizable", "settings_general_remote_skips_chapters") }
  /// When enabled and an episode has chapters, pressing the skip button in your car or headphones will skip to the next chapter.
  internal static var settingsGeneralRemoteSkipsChaptersSubtitle: String { return L10n.tr("Localizable", "settings_general_remote_skips_chapters_subtitle") }
  /// Would you like to change all your existing podcasts to be not be grouped as well?
  internal static var settingsGeneralRemoveGroupsApplyAll: String { return L10n.tr("Localizable", "settings_general_remove_groups_apply_all") }
  /// Row Action
  internal static var settingsGeneralRowAction: String { return L10n.tr("Localizable", "settings_general_row_action") }
  /// Would you like to change all your existing podcasts to be grouped by %1$@?
  internal static func settingsGeneralSelectedGroupApplyAll(_ p1: Any) -> String {
    return L10n.tr("Localizable", "settings_general_selected_group_apply_all", String(describing: p1))
  }
  /// Show
  internal static var settingsGeneralShow: String { return L10n.tr("Localizable", "settings_general_show") }
  /// Intelligent Playback Resumption
  internal static var settingsGeneralSmartPlayback: String { return L10n.tr("Localizable", "settings_general_smart_playback") }
  /// If on, Pocket Casts will go back a little in episodes you resume so you can catch up more comfortably.
  internal static var settingsGeneralSmartPlaybackSubtitle: String { return L10n.tr("Localizable", "settings_general_smart_playback_subtitle") }
  /// Up Next Swipe
  internal static var settingsGeneralUpNextSwipe: String { return L10n.tr("Localizable", "settings_general_up_next_swipe") }
  /// Play Up Next On Tap
  internal static var settingsGeneralUpNextTap: String { return L10n.tr("Localizable", "settings_general_up_next_tap") }
  /// Tapping an episode in Up Next shows the actions page. Long press plays the episode. Turn on to switch these around.
  internal static var settingsGeneralUpNextTapOffSubtitle: String { return L10n.tr("Localizable", "settings_general_up_next_tap_off_subtitle") }
  /// Tapping an episode in Up Next will play it. Long press shows episode options. Turn off to switch these around.
  internal static var settingsGeneralUpNextTapOnSubtitle: String { return L10n.tr("Localizable", "settings_general_up_next_tap_on_subtitle") }
  /// Global Settings
  internal static var settingsGlobalSettings: String { return L10n.tr("Localizable", "settings_global_settings") }
  /// Headphone Controls
  internal static var settingsHeadphoneControls: String { return L10n.tr("Localizable", "settings_headphone_controls") }
  /// Customise the actions done by the most common headphone controls.
  internal static var settingsHeadphoneControlsFooter: String { return L10n.tr("Localizable", "settings_headphone_controls_footer") }
  /// Help & Feedback
  internal static var settingsHelp: String { return L10n.tr("Localizable", "settings_help") }
  /// Import / Export
  internal static var settingsImportExport: String { return L10n.tr("Localizable", "settings_import_export") }
  /// Included In %1$@ Filters
  internal static func settingsInFiltersPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "settings_in_filters_plural_format", String(describing: p1))
  }
  /// Included In 1 Filter
  internal static var settingsInFiltersSingular: String { return L10n.tr("Localizable", "settings_in_filters_singular") }
  /// IN MENU
  internal static var settingsInMenu: String { return L10n.tr("Localizable", "settings_in_menu") }
  /// Inactive episodes are episodes you haven't played or downloaded in the time you specify above. Downloads are removed when the episode is archived.
  internal static var settingsInactiveEpisodesMsg: String { return L10n.tr("Localizable", "settings_inactive_episodes_msg") }
  /// Next Action
  internal static var settingsNextAction: String { return L10n.tr("Localizable", "settings_next_action") }
  /// Not Included In Any Filters
  internal static var settingsNotInFilters: String { return L10n.tr("Localizable", "settings_not_in_filters") }
  /// Notifications
  internal static var settingsNotifications: String { return L10n.tr("Localizable", "settings_notifications") }
  /// Filter count
  internal static var settingsNotificationsFilterCount: String { return L10n.tr("Localizable", "settings_notifications_filter_count") }
  /// Notifies you when a new episode is available. Also useful for improving the reliability of auto downloads.
  internal static var settingsNotificationsSubtitle: String { return L10n.tr("Localizable", "settings_notifications_subtitle") }
  /// Import/Export OPML
  internal static var settingsOpml: String { return L10n.tr("Localizable", "settings_opml") }
  /// Play Speed
  internal static var settingsPlaySpeed: String { return L10n.tr("Localizable", "settings_play_speed") }
  /// %1$@ per month / %2$@ per year
  internal static func settingsPlusPricingFormat(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "settings_plus_pricing_format", String(describing: p1), String(describing: p2))
  }
  /// Previous Action
  internal static var settingsPreviousAction: String { return L10n.tr("Localizable", "settings_previous_action") }
  /// Privacy
  internal static var settingsPrivacy: String { return L10n.tr("Localizable", "settings_privacy") }
  /// Position in Queue
  internal static var settingsQueuePosition: String { return L10n.tr("Localizable", "settings_queue_position") }
  /// Read privacy policy
  internal static var settingsReadPrivacyPolicy: String { return L10n.tr("Localizable", "settings_read_privacy_policy") }
  /// Select Filter
  internal static var settingsSelectFilterSingular: String { return L10n.tr("Localizable", "settings_select_filter_singular") }
  /// Select Filters
  internal static var settingsSelectFiltersPlural: String { return L10n.tr("Localizable", "settings_select_filters_plural") }
  /// Open Filter
  internal static var settingsShortcutsFilterOpenFilter: String { return L10n.tr("Localizable", "settings_shortcuts_filter_open_filter") }
  /// Play all episodes
  internal static var settingsShortcutsFilterPlayAllEpisodes: String { return L10n.tr("Localizable", "settings_shortcuts_filter_play_all_episodes") }
  /// Play the top episode
  internal static var settingsShortcutsFilterPlayTopEpisode: String { return L10n.tr("Localizable", "settings_shortcuts_filter_play_top_episode") }
  /// Siri Shortcut
  internal static var settingsSiriShortcut: String { return L10n.tr("Localizable", "settings_siri_shortcut") }
  /// A Siri Shortcut to play the top episode in %1$@
  internal static func settingsSiriShortcutMsg(_ p1: Any) -> String {
    return L10n.tr("Localizable", "settings_siri_shortcut_msg", String(describing: p1))
  }
  /// Siri Shortcuts
  internal static var settingsSiriShortcuts: String { return L10n.tr("Localizable", "settings_siri_shortcuts") }
  /// Available shortcuts
  internal static var settingsSiriShortcutsAvailable: String { return L10n.tr("Localizable", "settings_siri_shortcuts_available") }
  /// Enabled shortcuts
  internal static var settingsSiriShortcutsEnabled: String { return L10n.tr("Localizable", "settings_siri_shortcuts_enabled") }
  /// Shortcut to a specific filter
  internal static var settingsSiriShortcutsSpecificFilter: String { return L10n.tr("Localizable", "settings_siri_shortcuts_specific_filter") }
  /// Shortcut to a specific podcast
  internal static var settingsSiriShortcutsSpecificPodcast: String { return L10n.tr("Localizable", "settings_siri_shortcuts_specific_podcast") }
  /// Skip First
  internal static var settingsSkipFirst: String { return L10n.tr("Localizable", "settings_skip_first") }
  /// Skip Last
  internal static var settingsSkipLast: String { return L10n.tr("Localizable", "settings_skip_last") }
  /// Skip intro and outro music like the power user you were born to be.
  internal static var settingsSkipMsg: String { return L10n.tr("Localizable", "settings_skip_msg") }
  /// Stats
  internal static var settingsStats: String { return L10n.tr("Localizable", "settings_stats") }
  /// Account Service
  internal static var settingsStatusAccountService: String { return L10n.tr("Localizable", "settings_status_account_service") }
  /// The service used to store episode progress, subscriptions, filters, etc.
  internal static var settingsStatusAccountServiceDescription: String { return L10n.tr("Localizable", "settings_status_account_service_description") }
  /// Check your connection with important services. This helps diagnose issues with your network, proxies, VPN, ad-blocking and security apps.
  internal static var settingsStatusDescription: String { return L10n.tr("Localizable", "settings_status_description") }
  /// Discover & Search
  internal static var settingsStatusDiscover: String { return L10n.tr("Localizable", "settings_status_discover") }
  /// The discover section of the app, including podcast search.
  internal static var settingsStatusDiscoverDescription: String { return L10n.tr("Localizable", "settings_status_discover_description") }
  /// Common Podcast Hosts
  internal static var settingsStatusHost: String { return L10n.tr("Localizable", "settings_status_host") }
  /// Podcast authors host episode files in various hosting providers not managed by Pocket Casts.
  internal static var settingsStatusHostDescription: String { return L10n.tr("Localizable", "settings_status_host_description") }
  /// The most common cause is that you have an ad-blocker configured on your phone or network. You’ll need to unblock this domain to download podcasts. Please note Pocket Casts doesn’t host or choose where podcasts are hosted, that’s up to the author of the show and is out of our control.
  internal static var settingsStatusHostFailureMessage: String { return L10n.tr("Localizable", "settings_status_host_failure_message") }
  /// Internet
  internal static var settingsStatusInternet: String { return L10n.tr("Localizable", "settings_status_internet") }
  /// Check the status of your network.
  internal static var settingsStatusInternetDescription: String { return L10n.tr("Localizable", "settings_status_internet_description") }
  /// Unable to connect to the internet. Try connecting on a different network (e.g. mobile data).
  internal static var settingsStatusInternetFailureMessage: String { return L10n.tr("Localizable", "settings_status_internet_failure_message") }
  /// Refresh Service
  internal static var settingsStatusRefreshService: String { return L10n.tr("Localizable", "settings_status_refresh_service") }
  /// The service used to find new episodes.
  internal static var settingsStatusRefreshServiceDescription: String { return L10n.tr("Localizable", "settings_status_refresh_service_description") }
  /// Run now
  internal static var settingsStatusRun: String { return L10n.tr("Localizable", "settings_status_run") }
  /// The most common cause is that you have an ad-blocker configured on your phone or network. You’ll need to unblock the domain %1$@
  internal static func settingsStatusServiceAdBlockerHelpSingular(_ p1: Any) -> String {
    return L10n.tr("Localizable", "settings_status_service_ad_blocker_help_singular", String(describing: p1))
  }
  /// Storage & Data Use
  internal static var settingsStorage: String { return L10n.tr("Localizable", "settings_storage") }
  /// Warn Before Using Data
  internal static var settingsStorageDataWarning: String { return L10n.tr("Localizable", "settings_storage_data_warning") }
  /// Include Starred
  internal static var settingsStorageDownloadsStarred: String { return L10n.tr("Localizable", "settings_storage_downloads_starred") }
  /// MOBILE DATA
  internal static var settingsStorageMobileData: String { return L10n.tr("Localizable", "settings_storage_mobile_data") }
  /// USAGE
  internal static var settingsStorageUsage: String { return L10n.tr("Localizable", "settings_storage_usage") }
  /// Podcast Settings
  internal static var settingsTitle: String { return L10n.tr("Localizable", "settings_title") }
  /// Trim Level
  internal static var settingsTrimLevel: String { return L10n.tr("Localizable", "settings_trim_level") }
  /// Trim Silence
  internal static var settingsTrimSilence: String { return L10n.tr("Localizable", "settings_trim_silence") }
  /// When enabled the Up Next will always use the dark theme, or will match the current theme when disabled.
  internal static var settingsUpNextDarkModeFooter: String { return L10n.tr("Localizable", "settings_up_next_dark_mode_footer") }
  /// Use Dark Up Next Theme
  internal static var settingsUpNextDarkModeTitle: String { return L10n.tr("Localizable", "settings_up_next_dark_mode_title") }
  /// Automatically add new episodes to Up Next. New episodes will stop being added when Up Next reaches %1$@.
  internal static func settingsUpNextLimit(_ p1: Any) -> String {
    return L10n.tr("Localizable", "settings_up_next_limit", String(describing: p1))
  }
  /// Automatically add new episodes to Up Next. When Up Next reaches %1$@, new episodes auto-added to the top will remove the last episode in the queue.
  internal static func settingsUpNextLimitAddToTop(_ p1: Any) -> String {
    return L10n.tr("Localizable", "settings_up_next_limit_add_to_top", String(describing: p1))
  }
  /// Volume Boost
  internal static var settingsVolumeBoost: String { return L10n.tr("Localizable", "settings_volume_boost") }
  /// Auto Download Up Next
  internal static var settingsWatchAutoDownload: String { return L10n.tr("Localizable", "settings_watch_auto_download") }
  /// Set the number of episodes from your Up Next queue Pocket Casts will download to your watch for offline playback.
  internal static var settingsWatchAutoDownloadOffSubtitle: String { return L10n.tr("Localizable", "settings_watch_auto_download_off_subtitle") }
  /// Delete Downloads Outside Limit
  internal static var settingsWatchDeleteDownloads: String { return L10n.tr("Localizable", "settings_watch_delete_downloads") }
  /// To conserve watch storage, a maximum of 25 episodes in your Up Next queue will be auto-downloaded. Older download files outside this limit will be automatically deleted.
  internal static var settingsWatchDeleteDownloadsOffSubtitle: String { return L10n.tr("Localizable", "settings_watch_delete_downloads_off_subtitle") }
  /// All download files in your Up Next queue that are outside this limit will be automatically deleted. Manual downloads aren't managed by these settings.
  internal static var settingsWatchDeleteDownloadsOnSubtitle: String { return L10n.tr("Localizable", "settings_watch_delete_downloads_on_subtitle") }
  /// Number of Episodes
  internal static var settingsWatchEpisodeLimit: String { return L10n.tr("Localizable", "settings_watch_episode_limit") }
  /// Pocket Casts will download the top %1$@ episodes of your Up Next queue to your watch for offline playback.
  internal static func settingsWatchEpisodeLimitSubtitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "settings_watch_episode_limit_subtitle", String(describing: p1))
  }
  /// Top %1$@
  internal static func settingsWatchEpisodeNumberOptionFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "settings_watch_episode_number_option_format", String(describing: p1))
  }
  /// Set Up Account
  internal static var setupAccount: String { return L10n.tr("Localizable", "setup_account") }
  /// Share
  internal static var share: String { return L10n.tr("Localizable", "share") }
  /// Current Position
  internal static var shareCurrentPosition: String { return L10n.tr("Localizable", "share_current_position") }
  /// Subscribing...
  internal static var shareListSubscribing: String { return L10n.tr("Localizable", "share_list_subscribing") }
  /// ALL SELECTED
  internal static var sharePodcastsAllSelected: String { return L10n.tr("Localizable", "share_podcasts_all_selected") }
  /// Create List
  internal static var sharePodcastsCreateList: String { return L10n.tr("Localizable", "share_podcasts_create_list") }
  /// Sharing...
  internal static var sharePodcastsSharing: String { return L10n.tr("Localizable", "share_podcasts_sharing") }
  /// Something went wrong creating your share page
  internal static var sharePodcastsSharingFailedMsg: String { return L10n.tr("Localizable", "share_podcasts_sharing_failed_msg") }
  /// Sharing Failed
  internal static var sharePodcastsSharingFailedTitle: String { return L10n.tr("Localizable", "share_podcasts_sharing_failed_title") }
  /// Select Podcasts
  internal static var shareSelectPodcasts: String { return L10n.tr("Localizable", "share_select_podcasts") }
  /// Loading Shared Item...
  internal static var sharedItemLoading: String { return L10n.tr("Localizable", "shared_item_loading") }
  /// Shared List
  internal static var sharedList: String { return L10n.tr("Localizable", "shared_list") }
  /// Heck Yes!
  internal static var sharedListSubscribeConfAction: String { return L10n.tr("Localizable", "shared_list_subscribe_conf_action") }
  /// Are you sure you want to subscribe to %1$@ podcasts?
  internal static func sharedListSubscribeConfMsg(_ p1: Any) -> String {
    return L10n.tr("Localizable", "shared_list_subscribe_conf_msg", String(describing: p1))
  }
  /// That's a lot of podcasts!
  internal static var sharedListSubscribeConfTitle: String { return L10n.tr("Localizable", "shared_list_subscribe_conf_title") }
  /// Notes
  internal static var showNotes: String { return L10n.tr("Localizable", "show_notes") }
  /// Sign In
  internal static var signIn: String { return L10n.tr("Localizable", "sign_in") }
  /// Email Address
  internal static var signInEmailAddressPrompt: String { return L10n.tr("Localizable", "sign_in_email_address_prompt") }
  /// I forgot my password
  internal static var signInForgotPassword: String { return L10n.tr("Localizable", "sign_in_forgot_password") }
  /// Save your podcast subscriptions in the cloud and sync your progress with other devices.
  internal static var signInMessage: String { return L10n.tr("Localizable", "sign_in_message") }
  /// Password
  internal static var signInPasswordPrompt: String { return L10n.tr("Localizable", "sign_in_password_prompt") }
  /// Sign in or create account
  internal static var signInPrompt: String { return L10n.tr("Localizable", "sign_in_prompt") }
  /// SIGNED IN AS
  internal static var signedInAs: String { return L10n.tr("Localizable", "signed_in_as") }
  /// Not Signed In
  internal static var signedOut: String { return L10n.tr("Localizable", "signed_out") }
  /// 1 chapter
  internal static var singleChapter: String { return L10n.tr("Localizable", "single_chapter") }
  /// Set sleep timer to %1$@
  internal static func siriShortcutExtendSleepTimer(_ p1: Any) -> String {
    return L10n.tr("Localizable", "siri_shortcut_extend_sleep_timer", String(describing: p1))
  }
  /// Extend sleep timer by 5 minutes
  internal static var siriShortcutExtendSleepTimerFiveMin: String { return L10n.tr("Localizable", "siri_shortcut_extend_sleep_timer_five_min") }
  /// Next chapter
  internal static var siriShortcutNextChapter: String { return L10n.tr("Localizable", "siri_shortcut_next_chapter") }
  /// Open %1$@
  internal static func siriShortcutOpenFilterPhrase(_ p1: Any) -> String {
    return L10n.tr("Localizable", "siri_shortcut_open_filter_phrase", String(describing: p1))
  }
  /// Pause
  internal static var siriShortcutPausePhrase: String { return L10n.tr("Localizable", "siri_shortcut_pause_phrase") }
  /// Pause Current Episode
  internal static var siriShortcutPauseTitle: String { return L10n.tr("Localizable", "siri_shortcut_pause_title") }
  /// Play all %1$@
  internal static func siriShortcutPlayAllPhrase(_ p1: Any) -> String {
    return L10n.tr("Localizable", "siri_shortcut_play_all_phrase", String(describing: p1))
  }
  /// Playing all episodes
  internal static var siriShortcutPlayAllTitle: String { return L10n.tr("Localizable", "siri_shortcut_play_all_title") }
  /// Playing the top episode
  internal static var siriShortcutPlayEpisodeTitle: String { return L10n.tr("Localizable", "siri_shortcut_play_episode_title") }
  /// Play top %1$@
  internal static func siriShortcutPlayFilterPhrase(_ p1: Any) -> String {
    return L10n.tr("Localizable", "siri_shortcut_play_filter_phrase", String(describing: p1))
  }
  /// Play %1$@
  internal static func siriShortcutPlayPodcastPhrase(_ p1: Any) -> String {
    return L10n.tr("Localizable", "siri_shortcut_play_podcast_phrase", String(describing: p1))
  }
  /// Play a suggested episode
  internal static var siriShortcutPlaySuggestedPodcastPhrase: String { return L10n.tr("Localizable", "siri_shortcut_play_suggested_podcast_phrase") }
  /// Surprise Me!
  internal static var siriShortcutPlaySuggestedPodcastSuggestedTitle: String { return L10n.tr("Localizable", "siri_shortcut_play_suggested_podcast_suggested_title") }
  /// Playing a suggested episode
  internal static var siriShortcutPlaySuggestedPodcastTitle: String { return L10n.tr("Localizable", "siri_shortcut_play_suggested_podcast_title") }
  /// Up Next
  internal static var siriShortcutPlayUpNextPhrase: String { return L10n.tr("Localizable", "siri_shortcut_play_up_next_phrase") }
  /// Playing next episode
  internal static var siriShortcutPlayUpNextTitle: String { return L10n.tr("Localizable", "siri_shortcut_play_up_next_title") }
  /// Previous chapter
  internal static var siriShortcutPreviousChapter: String { return L10n.tr("Localizable", "siri_shortcut_previous_chapter") }
  /// Resume
  internal static var siriShortcutResumePhrase: String { return L10n.tr("Localizable", "siri_shortcut_resume_phrase") }
  /// Resuming Current Episode
  internal static var siriShortcutResumeTitle: String { return L10n.tr("Localizable", "siri_shortcut_resume_title") }
  /// Create Shortcut to Podcast
  internal static var siriShortcutToPodcast: String { return L10n.tr("Localizable", "siri_shortcut_to_podcast") }
  /// Skip Back
  internal static var skipBack: String { return L10n.tr("Localizable", "skip_back") }
  /// Skip chapters
  internal static var skipChapters: String { return L10n.tr("Localizable", "skip_chapters") }
  /// Skip Forward
  internal static var skipForward: String { return L10n.tr("Localizable", "skip_forward") }
  /// Sleep Timer
  internal static var sleepTimer: String { return L10n.tr("Localizable", "sleep_timer") }
  /// + 5 Minutes
  internal static var sleepTimerAdd5Mins: String { return L10n.tr("Localizable", "sleep_timer_add_5_mins") }
  /// Cancel Timer
  internal static var sleepTimerCancel: String { return L10n.tr("Localizable", "sleep_timer_cancel") }
  /// End Of Episode
  internal static var sleepTimerEndOfEpisode: String { return L10n.tr("Localizable", "sleep_timer_end_of_episode") }
  /// Sleep Timer on, %1$@ remaining
  internal static func sleepTimerTimeRemaining(_ p1: Any) -> String {
    return L10n.tr("Localizable", "sleep_timer_time_remaining", String(describing: p1))
  }
  /// Continue with Apple
  internal static var socialSignInContinueWithApple: String { return L10n.tr("Localizable", "social_sign_in_continue_with_apple") }
  /// Continue with Google
  internal static var socialSignInContinueWithGoogle: String { return L10n.tr("Localizable", "social_sign_in_continue_with_google") }
  /// CONNECT
  internal static var sonosConnectAction: String { return L10n.tr("Localizable", "sonos_connect_action") }
  /// Connect To Sonos
  internal static var sonosConnectPrompt: String { return L10n.tr("Localizable", "sonos_connect_prompt") }
  /// CONNECTING...
  internal static var sonosConnecting: String { return L10n.tr("Localizable", "sonos_connecting") }
  /// Unable to link Pocket Casts account at this time. Please try again later.
  internal static var sonosConnectionFailedAccountLink: String { return L10n.tr("Localizable", "sonos_connection_failed_account_link") }
  /// Unable to open Sonos app to complete linking process.
  internal static var sonosConnectionFailedAppMissing: String { return L10n.tr("Localizable", "sonos_connection_failed_app_missing") }
  /// Linking Failed
  internal static var sonosConnectionFailedTitle: String { return L10n.tr("Localizable", "sonos_connection_failed_title") }
  /// Connecting to Sonos will allow the Sonos app to access your episode information.
  /// 
  /// Your email address, password and other sensitive items are never shared.
  internal static var sonosConnectionPrivacyNotice: String { return L10n.tr("Localizable", "sonos_connection_privacy_notice") }
  /// You need to have a Pocket Casts account before you can connect with Sonos.
  internal static var sonosConnectionSignInPrompt: String { return L10n.tr("Localizable", "sonos_connection_sign_in_prompt") }
  /// Sort By
  internal static var sortBy: String { return L10n.tr("Localizable", "sort_by") }
  /// Sort Episodes
  internal static var sortEpisodes: String { return L10n.tr("Localizable", "sort_episodes") }
  /// Timestamp
  internal static var sortOptionTimestamp: String { return L10n.tr("Localizable", "sort_option_timestamp") }
  /// Speed
  internal static var speed: String { return L10n.tr("Localizable", "speed") }
  /// Star Episode
  internal static var starEpisode: String { return L10n.tr("Localizable", "star_episode") }
  /// Star
  internal static var starEpisodeShort: String { return L10n.tr("Localizable", "star_episode_short") }
  /// Start Free Trial
  internal static var startFreeTrial: String { return L10n.tr("Localizable", "start_free_trial") }
  /// You've listened for %1$@. %2$@
  internal static func statsAccessibilityListenHistoryFormat(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "stats_accessibility_listen_history_format", String(describing: p1), String(describing: p2))
  }
  /// Auto Skipping
  internal static var statsAutoSkip: String { return L10n.tr("Localizable", "stats_auto_skip") }
  /// Unable to load stats, check your Internet connection
  internal static var statsError: String { return L10n.tr("Localizable", "stats_error") }
  /// Since %1$@ you’ve listened for
  internal static func statsListenHistoryFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "stats_listen_history_format", String(describing: p1))
  }
  /// You’ve listened for
  internal static var statsListenHistoryLoading: String { return L10n.tr("Localizable", "stats_listen_history_loading") }
  /// You’ve listened for
  internal static var statsListenHistoryNoDate: String { return L10n.tr("Localizable", "stats_listen_history_no_date") }
  /// Skipping
  internal static var statsSkipping: String { return L10n.tr("Localizable", "stats_skipping") }
  /// TIME SAVED BY
  internal static var statsTimeSaved: String { return L10n.tr("Localizable", "stats_time_saved") }
  /// 0 seconds
  internal static var statsTimeZeroSeconds: String { return L10n.tr("Localizable", "stats_time_zero_seconds") }
  /// Total
  internal static var statsTotal: String { return L10n.tr("Localizable", "stats_total") }
  /// Variable Speed
  internal static var statsVariableSpeed: String { return L10n.tr("Localizable", "stats_variable_speed") }
  /// Downloaded
  internal static var statusDownloaded: String { return L10n.tr("Localizable", "status_downloaded") }
  /// Downloading
  internal static var statusDownloading: String { return L10n.tr("Localizable", "status_downloading") }
  /// Not Downloaded
  internal static var statusNotDownloaded: String { return L10n.tr("Localizable", "status_not_downloaded") }
  /// Not Selected
  internal static var statusNotSelected: String { return L10n.tr("Localizable", "status_not_selected") }
  /// Not Starred
  internal static var statusNotStarred: String { return L10n.tr("Localizable", "status_not_starred") }
  /// Played
  internal static var statusPlayed: String { return L10n.tr("Localizable", "status_played") }
  /// Selected
  internal static var statusSelected: String { return L10n.tr("Localizable", "status_selected") }
  /// Starred
  internal static var statusStarred: String { return L10n.tr("Localizable", "status_starred") }
  /// Unplayed
  internal static var statusUnplayed: String { return L10n.tr("Localizable", "status_unplayed") }
  /// Uploaded
  internal static var statusUploaded: String { return L10n.tr("Localizable", "status_uploaded") }
  /// Stop Download
  internal static var stopDownload: String { return L10n.tr("Localizable", "stop_download") }
  /// Subscribe
  internal static var subscribe: String { return L10n.tr("Localizable", "subscribe") }
  /// Subscribe All
  internal static var subscribeAll: String { return L10n.tr("Localizable", "subscribe_all") }
  /// Subscribed
  internal static var subscribed: String { return L10n.tr("Localizable", "subscribed") }
  /// Subscription Cancelled
  internal static var subscriptionCancelled: String { return L10n.tr("Localizable", "subscription_cancelled") }
  /// Subscription Cancelled %1$@ 
  internal static func subscriptionCancelledMsg(_ p1: Any) -> String {
    return L10n.tr("Localizable", "subscription_cancelled_msg", String(describing: p1))
  }
  /// Expires in %1$@
  internal static func subscriptionExpiresIn(_ p1: Any) -> String {
    return L10n.tr("Localizable", "subscription_expires_in", String(describing: p1))
  }
  /// Thanks for your support!
  internal static var subscriptionsThankYou: String { return L10n.tr("Localizable", "subscriptions_thank_you") }
  /// If you're having issues with the Pocket Casts Watch app we can send your wearable logs to better assist you. In order to do so, please open Pocket Casts on your Watch.
  internal static var supportWatchHelpMessage: String { return L10n.tr("Localizable", "support_watch_help_message") }
  /// I've opened the Watch app
  internal static var supportWatchHelpOpenedApp: String { return L10n.tr("Localizable", "support_watch_help_opened_app") }
  /// Send without Watch logs
  internal static var supportWatchHelpSendWithoutLog: String { return L10n.tr("Localizable", "support_watch_help_send_without_log") }
  /// Looking for Watch app help?
  internal static var supportWatchHelpTitle: String { return L10n.tr("Localizable", "support_watch_help_title") }
  /// Supporter
  internal static var supporter: String { return L10n.tr("Localizable", "supporter") }
  /// Supporter Contributions
  internal static var supporterContributions: String { return L10n.tr("Localizable", "supporter_contributions") }
  /// Check contributions for details
  internal static var supporterContributionsSubtitle: String { return L10n.tr("Localizable", "supporter_contributions_subtitle") }
  /// Supporter: Cancelled
  internal static var supporterPaymentCanceled: String { return L10n.tr("Localizable", "supporter_payment_canceled") }
  /// Check your username and password.
  internal static var syncAccountError: String { return L10n.tr("Localizable", "sync_account_error") }
  /// Logged in...
  internal static var syncAccountLogin: String { return L10n.tr("Localizable", "sync_account_login") }
  /// Sync failed
  internal static var syncFailed: String { return L10n.tr("Localizable", "sync_failed") }
  /// Syncing Up Next and History
  internal static var syncInProgress: String { return L10n.tr("Localizable", "sync_in_progress") }
  /// Podcast %1$@ of %2$@
  internal static func syncProgress(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "sync_progress", String(describing: p1), String(describing: p2))
  }
  /// Synced %1$@ podcasts
  internal static func syncProgressUnknownCountPluralFormat(_ p1: Any) -> String {
    return L10n.tr("Localizable", "sync_progress_unknown_count_plural_format", String(describing: p1))
  }
  /// Synced 1 podcast
  internal static var syncProgressUnknownCountSingular: String { return L10n.tr("Localizable", "sync_progress_unknown_count_singular") }
  /// Syncing...
  internal static var syncing: String { return L10n.tr("Localizable", "syncing") }
  /// Terms of Use
  internal static var termsOfUse: String { return L10n.tr("Localizable", "terms_of_use") }
  /// Classic
  internal static var themeClassic: String { return L10n.tr("Localizable", "theme_classic") }
  /// Default Dark
  internal static var themeDark: String { return L10n.tr("Localizable", "theme_dark") }
  /// Dark Contrast
  internal static var themeDarkContrast: String { return L10n.tr("Localizable", "theme_dark_contrast") }
  /// Electricity
  internal static var themeElectricity: String { return L10n.tr("Localizable", "theme_electricity") }
  /// Extra Dark
  internal static var themeExtraDark: String { return L10n.tr("Localizable", "theme_extra_dark") }
  /// Indigo
  internal static var themeIndigo: String { return L10n.tr("Localizable", "theme_indigo") }
  /// Default Light
  internal static var themeLight: String { return L10n.tr("Localizable", "theme_light") }
  /// Light Contrast
  internal static var themeLightContrast: String { return L10n.tr("Localizable", "theme_light_contrast") }
  /// Radioactivity
  internal static var themeRadioactivity: String { return L10n.tr("Localizable", "theme_radioactivity") }
  /// Rosé
  internal static var themeRose: String { return L10n.tr("Localizable", "theme_rose") }
  /// never
  internal static var timeFormatNever: String { return L10n.tr("Localizable", "time_format_never") }
  /// 0 sec
  internal static var timePlaceholder: String { return L10n.tr("Localizable", "time_placeholder") }
  /// Today
  internal static var today: String { return L10n.tr("Localizable", "today") }
  /// Top
  internal static var top: String { return L10n.tr("Localizable", "top") }
  /// Trial Finished
  internal static var trialFinished: String { return L10n.tr("Localizable", "trial_finished") }
  /// Trim Silence
  internal static var trimSilence: String { return L10n.tr("Localizable", "trim_silence") }
  /// Try Again
  internal static var tryAgain: String { return L10n.tr("Localizable", "try_again") }
  /// Try It Now
  internal static var tryItNow: String { return L10n.tr("Localizable", "try_it_now") }
  /// Unarchive
  internal static var unarchive: String { return L10n.tr("Localizable", "unarchive") }
  /// ? m
  internal static var unknownDuration: String { return L10n.tr("Localizable", "unknown_duration") }
  /// Unstar
  internal static var unstar: String { return L10n.tr("Localizable", "unstar") }
  /// Unsubscribe
  internal static var unsubscribe: String { return L10n.tr("Localizable", "unsubscribe") }
  /// Unsubscribe All
  internal static var unsubscribeAll: String { return L10n.tr("Localizable", "unsubscribe_all") }
  /// Up Next
  internal static var upNext: String { return L10n.tr("Localizable", "up_next") }
  /// You can queue episodes to play next by swiping right on episode rows, or tapping the icon on an episode card.
  internal static var upNextEmptyDescription: String { return L10n.tr("Localizable", "up_next_empty_description") }
  /// Nothing in Up Next
  internal static var upNextEmptyTitle: String { return L10n.tr("Localizable", "up_next_empty_title") }
  /// Upgrade Account
  internal static var upgradeAccount: String { return L10n.tr("Localizable", "upgrade_account") }
  /// Upgrade to %1$@
  internal static func upgradeToPlan(_ p1: Any) -> String {
    return L10n.tr("Localizable", "upgrade_to_plan", String(describing: p1))
  }
  /// Title (A-Z)
  internal static var uploadSortAlpha: String { return L10n.tr("Localizable", "upload_sort_alpha") }
  /// Volume Boost
  internal static var volumeBoost: String { return L10n.tr("Localizable", "volume_boost") }
  /// Voices sound louder
  internal static var volumeBoostDescription: String { return L10n.tr("Localizable", "volume_boost_description") }
  /// Waiting for WiFi
  internal static var waitForWifi: String { return L10n.tr("Localizable", "wait_for_wifi") }
  /// Watch
  internal static var watch: String { return L10n.tr("Localizable", "watch") }
  /// Buffering ...
  internal static var watchBuffering: String { return L10n.tr("Localizable", "watch_buffering") }
  /// Next Chapter
  internal static var watchChapterNext: String { return L10n.tr("Localizable", "watch_chapter_next") }
  /// Prev Chapter
  internal static var watchChapterPrev: String { return L10n.tr("Localizable", "watch_chapter_prev") }
  /// Effects
  internal static var watchEffects: String { return L10n.tr("Localizable", "watch_effects") }
  /// Episode Details
  internal static var watchEpisodeDetails: String { return L10n.tr("Localizable", "watch_episode_details") }
  /// Main Menu
  internal static var watchMainMenu: String { return L10n.tr("Localizable", "watch_main_menu") }
  /// No Episodes
  internal static var watchNoEpisodes: String { return L10n.tr("Localizable", "watch_no_episodes") }
  /// No Filters
  internal static var watchNoFilters: String { return L10n.tr("Localizable", "watch_no_filters") }
  /// No Podcasts
  internal static var watchNoPodcasts: String { return L10n.tr("Localizable", "watch_no_podcasts") }
  /// Enjoy the silence, or find something new to play.
  /// 
  /// Honestly both are solid choices. 🙂
  internal static var watchNothingPlayingSubtitle: String { return L10n.tr("Localizable", "watch_nothing_playing_subtitle") }
  /// Nothing Playing
  internal static var watchNothingPlayingTitle: String { return L10n.tr("Localizable", "watch_nothing_playing_title") }
  /// Podcasts will play from the speaker that the chosen device is connected to
  internal static var watchSourceMsg: String { return L10n.tr("Localizable", "watch_source_msg") }
  /// Download direct to your watch and listen without your phone. Check out Pocket Casts Plus on your phone app, or on the web.
  internal static var watchSourcePlusInfo: String { return L10n.tr("Localizable", "watch_source_plus_info") }
  /// Refresh Account
  internal static var watchSourceRefreshAccount: String { return L10n.tr("Localizable", "watch_source_refresh_account") }
  /// If you have a Pocket Casts Plus account, refresh account to attempt to enable it
  internal static var watchSourceRefreshAccountInfo: String { return L10n.tr("Localizable", "watch_source_refresh_account_info") }
  /// Refresh Data
  internal static var watchSourceRefreshData: String { return L10n.tr("Localizable", "watch_source_refresh_data") }
  /// Sign in or create an account on your phone
  internal static var watchSourceSignInInfo: String { return L10n.tr("Localizable", "watch_source_sign_in_info") }
  /// Tap to open
  internal static var watchTapToOpen: String { return L10n.tr("Localizable", "watch_tap_to_open") }
  /// You can queue episodes to play next from the episode details screen, or adding them on your phone.
  internal static var watchUpNextNoItemsSubtitle: String { return L10n.tr("Localizable", "watch_up_next_no_items_subtitle") }
  /// Nothing in Up Next
  internal static var watchUpNextNoItemsTitle: String { return L10n.tr("Localizable", "watch_up_next_no_items_title") }
  /// Find My Next Podcast
  internal static var welcomeDiscoverButton: String { return L10n.tr("Localizable", "welcome_discover_button") }
  /// Find under-the-radar and trending podcasts in our hand-curated Discover page.
  internal static var welcomeDiscoverDescription: String { return L10n.tr("Localizable", "welcome_discover_description") }
  /// Discover something new
  internal static var welcomeDiscoverTitle: String { return L10n.tr("Localizable", "welcome_discover_title") }
  /// Import Podcasts
  internal static var welcomeImportButton: String { return L10n.tr("Localizable", "welcome_import_button") }
  /// Coming from another app? Bring your podcasts with you.
  internal static var welcomeImportDescription: String { return L10n.tr("Localizable", "welcome_import_description") }
  /// Import your podcasts
  internal static var welcomeImportTitle: String { return L10n.tr("Localizable", "welcome_import_title") }
  /// Welcome, now let's get you listening!
  internal static var welcomeNewAccountTitle: String { return L10n.tr("Localizable", "welcome_new_account_title") }
  /// Thank you, now let's get you listening!
  internal static var welcomePlusTitle: String { return L10n.tr("Localizable", "welcome_plus_title") }
  /// What's New
  internal static var whatsNew: String { return L10n.tr("Localizable", "whats_new") }
  /// Read more about this update on our blog
  internal static var whatsNewBlogMoreLinkText: String { return L10n.tr("Localizable", "whats_new_blog_more_link_text") }
  /// What's New In %1$@
  internal static func whatsNewInVersion(_ p1: Any) -> String {
    return L10n.tr("Localizable", "whats_new_in_version", String(describing: p1))
  }
  /// If you love podcasts half as much as we do, you probably have a lot of them. If you're a Pocket Casts Plus subscriber, you can now sort these into folders and file them into neat groups.
  /// 
  /// Thanks to your support, your Home Screen has never looked better!
  internal static var whatsNewPageOne720: String { return L10n.tr("Localizable", "whats_new_page_one_7_20") }
  /// Folders
  internal static var whatsNewPageOneTitle720: String { return L10n.tr("Localizable", "whats_new_page_one_title_7_20") }
  /// We now sync your Home Screen (including your sort options) across devices! And you can drag and drop in the Web Player now as well.
  /// 
  /// This means you can rest easier, knowing the hard work you put in to arranging your podcasts page is being synced to your account.
  internal static var whatsNewPageTwo720: String { return L10n.tr("Localizable", "whats_new_page_two_7_20") }
  /// Home Grid Syncing
  internal static var whatsNewPageTwoTitle720: String { return L10n.tr("Localizable", "whats_new_page_two_title_7_20") }
  /// Quickly Launch Pocket Casts
  internal static var widgetsAppIconDescription: String { return L10n.tr("Localizable", "widgets_app_icon_description") }
  /// Icon
  internal static var widgetsAppIconName: String { return L10n.tr("Localizable", "widgets_app_icon_name") }
  /// Check out the Discover Tab
  internal static var widgetsDiscoverPromptMsg: String { return L10n.tr("Localizable", "widgets_discover_prompt_msg") }
  /// Ears hungry for more?
  internal static var widgetsDiscoverPromptTitle: String { return L10n.tr("Localizable", "widgets_discover_prompt_title") }
  /// Nothing Playing
  internal static var widgetsNothingPlaying: String { return L10n.tr("Localizable", "widgets_nothing_playing") }
  /// Quickly access the currently playing episode.
  internal static var widgetsNowPlayingDesc: String { return L10n.tr("Localizable", "widgets_now_playing_desc") }
  /// Tap to Discover
  internal static var widgetsNowPlayingTapDiscover: String { return L10n.tr("Localizable", "widgets_now_playing_tap_discover") }
  /// See the number of items in your Up Next queue or details about the next episode.
  internal static var widgetsUpNextDescription: String { return L10n.tr("Localizable", "widgets_up_next_description") }
  /// year
  internal static var year: String { return L10n.tr("Localizable", "year") }
  /// Yearly
  internal static var yearly: String { return L10n.tr("Localizable", "yearly") }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = localizedFormat(key, table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}
