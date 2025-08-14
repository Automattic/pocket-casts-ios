import UIKit
import SwiftUI

class AppTheme {
    private static let tintColor = UIColor(hex: "#F44336")

    class func appTintColor() -> UIColor {
        AppTheme.tintColor
    }

    class func placeholderTextColor() -> UIColor {
        Theme.isDarkTheme() ? UIColor(hex: "#808892") : UIColor(hex: "#C7C7CD")
    }

    class func pcPlusRed() -> UIColor {
        ThemeColor.support05()
    }

    class func pcPlusGoldGradientDark() -> UIColor {
        UIColor(hex: "#feb525")
    }

    class func pcPlusGoldGradientLight() -> UIColor {
        UIColor(hex: "#fed745")
    }

    class func successGreen() -> UIColor {
        UIColor(hex: "#78D549")
    }

    class func episodeCellPlayedIndicatorColor() -> UIColor {
        Theme.isDarkTheme() ? UIColor.white : UIColor.black
    }

    // MARK: - Mini Player

    class func miniPlayerButtonColor() -> UIColor {
        Theme.isDarkTheme() ? UIColor.white : UIColor(hex: "#9097A3")
    }

    class func waitingForWifiColor() -> UIColor {
        Theme.isDarkTheme() ? UIColor(hex: "#525466") : UIColor(hex: "#B8C3C9")
    }

    // MARK: - Sync Buttons

    class func disabledButtonColor() -> UIColor {
        Theme.isDarkTheme() ? UIColor(hex: "#929292") : UIColor(hex: "#D9D9D9")
    }

    // MARK: - Discover

    class func imagePlaceHolderColor() -> UIColor {
        Theme.isDarkTheme() ? UIColor(hex: "#4F4F4F") : UIColor(hex: "#E0E6EA")
    }

    // MARK: - Podcast Page

    class func extraContentBorderColor() -> UIColor {
        Theme.isDarkTheme() ? UIColor(hex: "#3A3A3B") : UIColor(hex: "#E0E6EA")
    }

    // MARK: - Episode Card Message

    class func episodeMessageBorderColor(for theme: Theme.ThemeType? = nil) -> UIColor {
        (theme?.isDark ?? Theme.isDarkTheme()) ? UIColor(hex: "#979797") : UIColor(hex: "#DCE1E4")
    }

    class func episodeMessageBackgroundColor(for theme: Theme.ThemeType? = nil) -> UIColor {
        (theme?.isDark ?? Theme.isDarkTheme()) ? UIColor(hex: "#3A3A3B") : UIColor(hex: "#FBFBFB")
    }

    class func switchDarkThemeDefaultColor() -> UIColor {
        UIColor(hex: "#CCCCCC")
    }

    class func appearanceShadowColor() -> UIColor {
        UIColor(red: 0, green: 0, blue: 0, alpha: 0.15)
    }

    class func uploadProgressBackgroundColor() -> UIColor {
        Theme.isDarkTheme() ? viewBackgroundColor() : UIColor(hex: "#F9FAF9")
    }

    class func userEpisodeNoArtworkColor() -> UIColor {
        UIColor(hex: "#8F97A4")
    }

    class func embeddedArtworkColor() -> UIColor {
        UIColor.black
    }

    class func defaultPodcastBackgroundColor() -> UIColor {
        UIColor(hex: "#1E1F1E")
    }

    class func podcastSearchBarStyle() -> UIBarStyle {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark, .electric, .radioactive, .contrastDark:
            return UIBarStyle.black
        case .light, .classic, .indigo, .rosé, .contrastLight:
            return UIBarStyle.default
        }
    }

    // MARK: - Paid podcast colours

    class func podcastHeartDarkGradientColor() -> UIColor {
        UIColor(hex: "#A6A6A6")
    }

    class func podcastHeartLightGradientColor() -> UIColor {
        UIColor(hex: "#D5D5D5")
    }

    class func podcastHeartDarkRedGradientColor() -> UIColor {
        UIColor(hex: "#FF1100")
    }

    class func podcastHeartLightRedGradientColor() -> UIColor {
        UIColor(hex: "#AD0000")
    }

    class func supporterPodcastBackgroundColor() -> UIColor {
        UIColor(hex: "#616874")
    }

    // MARK: - Illustrations

    class func noFilesImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .light, .classic:
            return "no-files-light"
        case .dark, .extraDark:
            return "no-files-dark"
        case .electric:
            return "no-files-electric"
        case .indigo:
            return "no-files-indigo"
        case .radioactive:
            return "no-files-radioactive"
        case .rosé:
            return "no-files-rose"
        case .contrastLight:
            return "no-files-contrastLight"
        case .contrastDark:
            return "no-files-contrastDark"
        }
    }

    class func noConnectionImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return "no-connection-dark"
        case .light, .classic, .indigo:
            return "no-connection"
        case .electric:
            return "no-connection-electricity"
        case .radioactive:
            return "no-connection-radioactive"
        case .rosé:
            return "no-connection-rose"
        case .contrastLight:
            return "no-connection-contrastLight"
        case .contrastDark:
            return "no-connection-contrastDark"
        }
    }

    class func setupNewAccountImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return "setup-new-account-dark"
        case .light, .classic:
            return "setup-new-account"
        case .electric:
            return "setup-new-account-electricity"
        case .indigo:
            return "setup-new-account-indigo"
        case .radioactive:
            return "setup-new-account-radioactive"
        case .rosé:
            return "setup-new-account-rose"
        case .contrastLight:
            return "setup-new-account-contrastLight"
        case .contrastDark:
            return "setup-new-account-contrastDark"
        }
    }

    class func setupNewAccountGoldImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return "setup-new-account-gold-dark"
        case .electric:
            return "setup-new-account-gold-electricity"
        case .light, .classic:
            return "setup-new-account-gold"
        case .indigo:
            return "setup-new-account-gold-indigo"
        case .radioactive:
            return "setup-new-account-radioactive"
        case .rosé:
            return "setup-new-account-gold-rose"
        case .contrastLight:
            return "setup-new-account-gold-contrastLight"
        case .contrastDark:
            return "setup-new-account-gold-contrastDark"
        }
    }

    class func paymentFailedImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return "payment-failed-dark"
        case .light, .classic:
            return "payment-failed"
        case .electric:
            return "payment-failed-electricity"
        case .indigo:
            return "payment-failed-indigo"
        case .radioactive:
            return "payment-failed-radioactive"
        case .rosé:
            return "payment-failed-rose"
        case .contrastLight:
            return "payment-failed-contrastLight"
        case .contrastDark:
            return "payment-failed-contrastDark"
        }
    }

    class func passwordChangedImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return "key-stars-dark"
        case .light, .classic:
            return "key-stars"
        case .electric:
            return "key-stars-electricity"
        case .indigo:
            return "key-stars-indigo"
        case .radioactive:
            return "key-stars-radioactive"
        case .rosé:
            return "key-stars-rose"
        case .contrastLight:
            return "key-stars-contrastLight"
        case .contrastDark:
            return "key-stars-contrastDark"
        }
    }

    class func paymentDeferredImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return "payment-pending-dark"
        case .light, .classic:
            return "payment-pending"
        case .electric:
            return "payment-pending-electricity"
        case .indigo:
            return "payment-pending-indigo"
        case .radioactive:
            return "payment-pending-radioactive"
        case .rosé:
            return "payment-pending-rose"
        case .contrastLight:
            return "payment-pending-contrastLight"
        case .contrastDark:
            return "payment-pending-contrastDark"
        }
    }

    class func accountUpgradedImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return "avatar-plus-gold-dark"
        case .light, .classic:
            return "avatar-plus-gold"
        case .electric:
            return "avatar-plus-gold-electricity"
        case .indigo:
            return "avatar-plus-gold-indigo"
        case .radioactive:
            return "avatar-plus-gold-radioactive"
        case .rosé:
            return "avatar-plus-gold-rose"
        case .contrastLight:
            return "avatar-plus-gold-contrastLight"
        case .contrastDark:
            return "avatar-plus-gold-contrastDark"
        }
    }

    class func plusCreatedImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return "avatar-tick-gold-dark"
        case .light, .classic:
            return "avatar-tick-gold"
        case .electric:
            return "avatar-tick-gold-electricity"
        case .indigo:
            return "avatar-tick-gold-indigo"
        case .radioactive:
            return "avatar-tick-gold-radioactive"
        case .rosé:
            return "avatar-tick-gold-rose"
        case .contrastLight:
            return "avatar-tick-gold-contrastLight"
        case .contrastDark:
            return "avatar-tick-gold-contrastDark"
        }
    }

    class func accountCreatedImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return "avatar-tick-dark"
        case .light, .classic:
            return "avatar-tick"
        case .electric:
            return "avatar-tick-electricity"
        case .indigo:
            return "avatar-tick-indigo"
        case .radioactive:
            return "avatar-tick-radioactive"
        case .rosé:
            return "avatar-tick-rose"
        case .contrastLight:
            return "avatar-tick-contrastLight"
        case .contrastDark:
            return "avatar-tick-contrastDark"
        }
    }

    class func plusCancelledImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return "avatar-cancelled-dark"
        case .light, .classic:
            return "avatar-cancelled"
        case .electric:
            return "avatar-cancelled-electricity"
        case .indigo:
            return "avatar-cancelled-indigo"
        case .radioactive:
            return "avatar-cancelled-radioactive"
        case .rosé:
            return "avatar-cancelled-rose"
        case .contrastLight:
            return "avatar-cancelled-contrastLight"
        case .contrastDark:
            return "avatar-cancelled-contrastDark"
        }
    }

    class func plusCancelledGoldImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return "avatar-cancelled-gold-dark"
        case .light, .classic:
            return "avatar-cancelled-gold"
        case .electric:
            return "avatar-cancelled-gold-electricity"
        case .indigo:
            return "avatar-cancelled-gold-indigo"
        case .radioactive:
            return "avatar-cancelled-radioactive"
        case .rosé:
            return "avatar-cancelled-gold-rose"
        case .contrastLight:
            return "avatar-cancelled-gold-contrastLight"
        case .contrastDark:
            return "avatar-cancelled-gold-contrastDark"
        }
    }

    class func changedEmailImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return "email-stars-dark"
        case .light, .classic:
            return "email-stars"
        case .electric:
            return "email-stars-electricity"
        case .indigo:
            return "email-stars-indigo"
        case .radioactive:
            return "email-stars-radioactive"
        case .rosé:
            return "email-stars-rose"
        case .contrastLight:
            return "email-stars-contrastLight"
        case .contrastDark:
            return "email-stars-contrastDark"
        }
    }

    class func cancelSubscriptionImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return "dollar-recycle-dark"
        case .light, .classic:
            return "dollar-recycle"
        case .electric:
            return "dollar-recycle-electricity"
        case .indigo:
            return "dollar-recycle-indigo"
        case .radioactive:
            return "dollar-recycle-radioactive"
        case .rosé:
            return "dollar-recycle-rose"
        case .contrastLight:
            return "dollar-recycle-contrastLight"
        case .contrastDark:
            return "dollar-recycle-contrastDark"
        }
    }

    class func folderLockedImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return "folder-locked-dark"
        case .light, .classic:
            return "folder-locked"
        case .electric:
            return "folder-locked-electricity"
        case .indigo:
            return "folder-locked-indigo"
        case .radioactive:
            return "folder-locked-radioactive"
        case .rosé:
            return "folder-locked-rose"
        case .contrastLight:
            return "folder-locked-contrastLight"
        case .contrastDark:
            return "folder-locked-contrastDark"
        }
    }

    class func pcPlusLogoHorizontalImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark, .electric, .radioactive, .contrastDark:
            return "PCPlusHorizontal-Dark"
        case .light, .classic, .indigo, .rosé, .contrastLight:
            return "PCPlusHorizontal"
        }
    }

    class func pcLogoHorizontalImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark, .electric, .radioactive, .contrastDark:
            return "horizontal-logo-dark"
        case .light, .classic, .indigo, .rosé, .contrastLight:
            return "horizontal-logo"
        }
    }

    static func pcLogoSmallHorizontalImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark, .electric, .radioactive, .contrastDark, .indigo, .classic:
            return "small-horizontal-logo-dark"
        case .light, .rosé, .contrastLight:
            return "small-horizontal-logo"
        }
    }

    static func pcLogoSmallHorizontalForBackgroundImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark, .electric, .radioactive, .contrastDark:
            return "small-horizontal-logo-dark"
        case .light, .classic, .indigo, .rosé, .contrastLight:
            return "small-horizontal-logo"
        }
    }

    static func socialIconAppleImageName(theme: Theme = .sharedTheme) -> String {
        switch theme.activeTheme {
        case .dark, .extraDark, .electric, .radioactive, .contrastDark:
            return "sso-icon-apple-dark"
        case .light, .classic, .indigo, .rosé, .contrastLight:
            return "sso-icon-apple"
        }
    }

    static func socialIconGoogleImageName() -> String {
        return "sso-icon-google"
    }

    class func pcPlusLogoVerticalImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark, .electric, .radioactive, .contrastDark:
            return "verticalLogoDark"
        case .light, .classic, .indigo, .rosé, .contrastLight:
            return "verticalLogo"
        }
    }

    class func pcLogoVerticalImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark, .electric, .radioactive, .contrastDark:
            return "pc-logo-vertical-dark"
        case .light, .classic, .indigo, .rosé, .contrastLight:
            return "pc-logo-vertical"
        }
    }

    class func fileErrorImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark, .radioactive:
            return "fileError-dark"
        case .light, .classic:
            return "fileError"
        case .indigo:
            return "fileError-indigo"
        case .rosé:
            return "fileError-rose"
        case .electric:
            return "fileError-electricity"
        case .contrastLight:
            return "fileError-contrastLight"
        case .contrastDark:
            return "fileError-contrastDark"
        }
    }

    class func termsOfUseImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return "clipboard-dark"
        case .light, .classic:
            return "clipboard"
        case .electric:
            return "clipboard-electricity"
        case .indigo:
            return "clipboard-indigo"
        case .radioactive:
            return "clipboard-radioactive"
        case .rosé:
            return "clipboard-rose"
        case .contrastLight:
            return "clipboard-contrastLight"
        case .contrastDark:
            return "clipboard-contrastDark"
        }
    }

    class func promoErrorImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return "promo-error-dark"
        case .light, .classic:
            return "promo-error"
        case .electric:
            return "promo-error-electricity"
        case .indigo:
            return "promo-error-indigo"
        case .radioactive:
            return "promo-error-radioactive"
        case .rosé:
            return "promo-error-rose"
        case .contrastLight:
            return "promo-error-contrastLight"
        case .contrastDark:
            return "promo-error-contrastDark"
        }
    }

    class func emptyFilterImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return "empty-filter-dark"
        case .light, .classic:
            return "empty-filter"
        case .electric:
            return "empty-filter-electricity"
        case .indigo:
            return "empty-filter-indigo"
        case .radioactive:
            return "empty-filter-radioactive"
        case .rosé:
            return "empty-filter-rose"
        case .contrastLight:
            return "empty-filter-contrastLight"
        case .contrastDark:
            return "empty-filter-contrastDark"
        }
    }

    // MARK: - App Colors

    class func keyboardAppearance() -> UIKeyboardAppearance {
        Theme.isDarkTheme() ? UIKeyboardAppearance.dark : UIKeyboardAppearance.light
    }

    class func optionPickerBackgroundColor(for theme: Theme.ThemeType? = nil) -> UIColor {
        ThemeColor.primaryUi01(for: theme)
    }

    class func defaultStatusBarStyle() -> UIStatusBarStyle {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark, .electric, .classic, .indigo, .radioactive, .contrastDark:
            return UIStatusBarStyle.lightContent
        case .light, .rosé, .contrastLight:
            return UIStatusBarStyle.darkContent
        }
    }

    class func popupStatusBarStyle(themeOverride: Theme.ThemeType? = nil) -> UIStatusBarStyle {
        switch themeOverride ?? Theme.sharedTheme.activeTheme {
        case .dark, .extraDark, .electric, .radioactive, .contrastDark:
            return UIStatusBarStyle.lightContent
        case .light, .classic, .indigo, .rosé, .contrastLight:
            return UIStatusBarStyle.darkContent
        }
    }

    class func loadingActivityColor() -> UIColor {
        ThemeColor.primaryIcon01()
    }

    class func destructiveTextColor(for theme: Theme.ThemeType? = nil) -> UIColor {
        ThemeColor.support05(for: theme)
    }

    class func mainTextColor(for theme: Theme.ThemeType? = nil) -> UIColor {
        ThemeColor.primaryText01(for: theme)
    }

    class func tableDividerColor(for theme: Theme.ThemeType? = nil) -> UIColor {
        ThemeColor.primaryUi05(for: theme)
    }

    class func indicatorStyle(for theme: Theme.ThemeType? = nil) -> UIScrollView.IndicatorStyle {
        if let themeOverride = theme {
            return themeOverride.isDark ? .white : .black
        }
        return Theme.isDarkTheme() ? .white : .black
    }

    class func stepperColor() -> UIColor {
        ThemeColor.primaryInteractive01()
    }

    class func tabBarBackgroundColor() -> UIColor {
        ThemeColor.primaryUi03()
    }

    class func tabBarItemTintColor() -> UIColor {
        ThemeColor.primaryIcon02Selected()
    }

    class func unselectedTabBarItemColor() -> UIColor {
        ThemeColor.primaryIcon02()
    }

    class func navBarTitleColor(themeOverride: Theme.ThemeType? = nil) -> UIColor {
        ThemeColor.secondaryText01(for: themeOverride)
    }

    class func navBarIconsColor(themeOverride: Theme.ThemeType? = nil) -> UIColor {
        ThemeColor.secondaryIcon01(for: themeOverride)
    }

    class func viewBackgroundColor() -> UIColor {
        ThemeColor.primaryUi01()
    }

    class func userEpisodeColor(number: Int) -> UIColor {
        switch number {
        case 1:
            return userEpisodeNoArtworkColor()
        case 2:
            return userEpisodeRedColor()
        case 3:
            return userEpisodeBlueColor()
        case 4:
            return userEpisodeGreenColor()
        case 5:
            return userEpisodeYellowColor()
        case 6:
            return userEpisodeOrangeColor()
        case 7:
            return userEpisodePurpleColor()
        case 8:
            return userEpisodePinkColor()
        default:
            return userEpisodeNoArtworkColor()
        }
    }

    class func userEpisodeRedColor() -> UIColor {
        ThemeColor.filter01(for: Theme.isDarkTheme() ? .dark : .light)
    }

    class func userEpisodeBlueColor() -> UIColor {
        ThemeColor.filter05(for: Theme.isDarkTheme() ? .dark : .light)
    }

    class func userEpisodeGreenColor() -> UIColor {
        ThemeColor.filter04(for: Theme.isDarkTheme() ? .dark : .light)
    }

    class func userEpisodeYellowColor() -> UIColor {
        ThemeColor.filter03(for: Theme.isDarkTheme() ? .dark : .light)
    }

    class func userEpisodeOrangeColor() -> UIColor {
        ThemeColor.filter02(for: Theme.isDarkTheme() ? .dark : .light)
    }

    class func userEpisodePurpleColor() -> UIColor {
        ThemeColor.filter06(for: Theme.isDarkTheme() ? .dark : .light)
    }

    class func userEpisodePinkColor() -> UIColor {
        ThemeColor.filter07(for: Theme.isDarkTheme() ? .dark : .light)
    }

    class func folderColor(colorInt: Int32) -> UIColor {
        switch colorInt {
        case 0: return ThemeColor.filter01()
        case 1: return ThemeColor.filter02()
        case 2: return ThemeColor.filter03()
        case 3: return ThemeColor.filter04()
        case 4: return ThemeColor.filter05()
        case 5: return ThemeColor.filter06()
        case 6: return ThemeColor.filter07()
        case 7: return ThemeColor.filter08()
        case 8: return ThemeColor.filter09()
        case 9: return ThemeColor.filter10()
        case 10: return ThemeColor.filter11()
        case 11: return ThemeColor.filter12()
        default: return ThemeColor.filter08()
        }
    }

    class func playlistRedColor() -> UIColor {
        ThemeColor.filter01()
    }

    class func playlistBlueColor() -> UIColor {
        ThemeColor.filter05()
    }

    class func playlistGreenColor() -> UIColor {
        ThemeColor.filter04()
    }

    class func playlistPurpleColor() -> UIColor {
        ThemeColor.filter06()
    }

    class func playlistYellowColor() -> UIColor {
        ThemeColor.filter03()
    }

    // MARK: - Getting Colors from ThemeStyles

    /// Returns a SwiftUI color for the theme style
    static func color(for style: ThemeStyle, theme: Theme? = nil) -> Color {
        return colorForStyle(style, themeOverride: theme?.activeTheme).color
    }

    // TODO: there probably is a more elegant way to do this...
    class func colorForStyle(_ style: ThemeStyle, themeOverride: Theme.ThemeType? = nil) -> UIColor {
        switch style {
        case .primaryText01: return ThemeColor.primaryText01(for: themeOverride)
        case .primaryText02: return ThemeColor.primaryText02(for: themeOverride)
        case .primaryUi01: return ThemeColor.primaryUi01(for: themeOverride)
        case .primaryUi01Active: return ThemeColor.primaryUi01Active(for: themeOverride)
        case .primaryUi02: return ThemeColor.primaryUi02(for: themeOverride)
        case .primaryUi02Selected: return ThemeColor.primaryUi02Selected(for: themeOverride)
        case .primaryUi02Active: return ThemeColor.primaryUi02Active(for: themeOverride)
        case .primaryUi03: return ThemeColor.primaryUi03(for: themeOverride)
        case .primaryUi04: return ThemeColor.primaryUi04(for: themeOverride)
        case .primaryUi05: return ThemeColor.primaryUi05(for: themeOverride)
        case .primaryUi05Selected: return ThemeColor.primaryUi05Selected(for: themeOverride)
        case .primaryUi06: return ThemeColor.primaryUi06(for: themeOverride)
        case .primaryIcon01: return ThemeColor.primaryIcon01(for: themeOverride)
        case .primaryIcon01Active: return ThemeColor.primaryIcon01Active(for: themeOverride)
        case .primaryIcon02: return ThemeColor.primaryIcon02(for: themeOverride)
        case .primaryIcon02Selected: return ThemeColor.primaryIcon02Selected(for: themeOverride)
        case .primaryIcon02Active: return ThemeColor.primaryIcon02Active(for: themeOverride)
        case .primaryIcon03: return ThemeColor.primaryIcon03(for: themeOverride)
        case .primaryIcon03Active: return ThemeColor.primaryIcon03Active(for: themeOverride)
        case .primaryText02Selected: return ThemeColor.primaryIcon02Selected(for: themeOverride)
        case .primaryField01: return ThemeColor.primaryField01(for: themeOverride)
        case .primaryField01Active: return ThemeColor.primaryField01Active(for: themeOverride)
        case .primaryField02: return ThemeColor.primaryField02(for: themeOverride)
        case .primaryField02Active: return ThemeColor.primaryField02Active(for: themeOverride)
        case .primaryField03: return ThemeColor.primaryField03(for: themeOverride)
        case .primaryField03Active: return ThemeColor.primaryField03Active(for: themeOverride)
        case .primaryInteractive01: return ThemeColor.primaryInteractive01(for: themeOverride)
        case .primaryInteractive01Hover: return ThemeColor.primaryInteractive01Hover(for: themeOverride)
        case .primaryInteractive01Active: return ThemeColor.primaryInteractive01Active(for: themeOverride)
        case .primaryInteractive01Disabled: return ThemeColor.primaryInteractive01Disabled(for: themeOverride)
        case .primaryInteractive02: return ThemeColor.primaryInteractive02(for: themeOverride)
        case .primaryInteractive02Hover: return ThemeColor.primaryInteractive02Hover(for: themeOverride)
        case .primaryInteractive02Active: return ThemeColor.primaryInteractive02Active(for: themeOverride)
        case .primaryInteractive03: return ThemeColor.primaryInteractive03(for: themeOverride)
        case .secondaryUi01: return ThemeColor.secondaryUi01(for: themeOverride)
        case .secondaryUi02: return ThemeColor.secondaryUi02(for: themeOverride)
        case .secondaryIcon01: return ThemeColor.secondaryIcon01(for: themeOverride)
        case .secondaryIcon02: return ThemeColor.secondaryIcon02(for: themeOverride)
        case .secondaryText01: return ThemeColor.secondaryText01(for: themeOverride)
        case .secondaryText02: return ThemeColor.secondaryText02(for: themeOverride)
        case .secondaryField01: return ThemeColor.secondaryField01(for: themeOverride)
        case .secondaryField01Active: return ThemeColor.secondaryField01Active(for: themeOverride)
        case .secondaryInteractive01: return ThemeColor.secondaryInteractive01(for: themeOverride)
        case .secondaryInteractive01Hover: return ThemeColor.secondaryInteractive01Hover(for: themeOverride)
        case .secondaryInteractive01Active: return ThemeColor.secondaryInteractive01Active(for: themeOverride)
        case .support01: return ThemeColor.support01()
        case .support02: return ThemeColor.support02()
        case .support03: return ThemeColor.support03()
        case .support04: return ThemeColor.support04()
        case .support05: return ThemeColor.support05()
        case .support06: return ThemeColor.support06()
        case .support07: return ThemeColor.support07()
        case .support08: return ThemeColor.support08()
        case .support09: return ThemeColor.support09()
        case .support10: return ThemeColor.support10()
        case .playerContrast01: return ThemeColor.playerContrast01(for: themeOverride)
        case .playerContrast02: return ThemeColor.playerContrast02(for: themeOverride)
        case .playerContrast03: return ThemeColor.playerContrast03(for: themeOverride)
        case .playerContrast04: return ThemeColor.playerContrast04(for: themeOverride)
        case .playerContrast05: return ThemeColor.playerContrast05(for: themeOverride)
        case .playerContrast06: return ThemeColor.playerContrast06(for: themeOverride)
        case .contrast01: return ThemeColor.contrast01()
        case .contrast02: return ThemeColor.contrast02()
        case .contrast03: return ThemeColor.contrast03()
        case .contrast04: return ThemeColor.contrast04()
        case .filter01: return ThemeColor.filter01(for: themeOverride)
        case .filter02: return ThemeColor.filter02(for: themeOverride)
        case .filter03: return ThemeColor.filter03(for: themeOverride)
        case .filter04: return ThemeColor.filter04(for: themeOverride)
        case .filter05: return ThemeColor.filter05(for: themeOverride)
        case .filter06: return ThemeColor.filter06(for: themeOverride)
        case .filter07: return ThemeColor.filter07(for: themeOverride)
        case .filter08: return ThemeColor.filter08(for: themeOverride)
        case .veil: return ThemeColor.veil()
        case .gradient01A: return ThemeColor.gradient01A()
        case .gradient01E: return ThemeColor.gradient01E()
        case .gradient02A: return ThemeColor.gradient02A()
        case .gradient02E: return ThemeColor.gradient02E()
        case .gradient03A: return ThemeColor.gradient03A()
        case .gradient03E: return ThemeColor.gradient03E()
        case .gradient04A: return ThemeColor.gradient04A()
        case .gradient04E: return ThemeColor.gradient04E()
        case .gradient05A: return ThemeColor.gradient05A()
        case .gradient05E: return ThemeColor.gradient05E()
        case .imageFilter01: return ThemeColor.imageFilter01()
        case .imageFilter02: return ThemeColor.imageFilter02()
        case .imageFilter03: return ThemeColor.imageFilter03()
        case .imageFilter04: return ThemeColor.imageFilter04()
        case .category01: return ThemeColor.category01()
        case .category02: return ThemeColor.category02()
        case .category03: return ThemeColor.category03()
        case .category04: return ThemeColor.category04()
        case .category05: return ThemeColor.category05()
        case .category06: return ThemeColor.category06()
        case .category07: return ThemeColor.category07()
        case .category08: return ThemeColor.category08()
        case .category09: return ThemeColor.category09()
        case .category10: return ThemeColor.category10()
        case .category11: return ThemeColor.category11()
        case .category12: return ThemeColor.category12()
        case .category13: return ThemeColor.category13()
        case .category14: return ThemeColor.category14()
        case .category15: return ThemeColor.category15()
        case .category16: return ThemeColor.category16()
        case .category17: return ThemeColor.category17()
        case .category18: return ThemeColor.category18()
        case .category19: return ThemeColor.category19()
        case .podcastOndark, .podcastOnlight, .podcastUi01, .podcastUi02, .podcastUi03, .podcastUi04, .podcastUi05, .podcastUi06, .podcastIcon01, .podcastIcon02, .podcastIcon03, .podcastText01, .podcastText02, .podcastInteractive01, .podcastInteractive01Active, .podcastInteractive02, .podcastInteractive03, .podcastInteractive03Active, .podcastInteractive04, .podcastInteractive05, .filterUi01, .filterUi02, .filterUi03, .filterUi04, .filterIcon01, .filterIcon02, .filterText01, .filterText02, .filterInteractive01, .filterInteractive01Active, .filterInteractive02, .filterInteractive03, .filterInteractive03Active, .filterInteractive04, .filterInteractive05, .filterInteractive06, .playerHighlight01, .playerBackground01, .playerBackground02, .playerHighlight02, .playerHighlight03, .playerHighlight04, .playerHighlight05, .playerHighlight06, .playerHighlight07:
            assertionFailure("**** colorForStyle: color token used that requires additional info, you cannot use this method to get this colour ****")
            return ThemeColor.primaryUi01()
        }
    }
}
