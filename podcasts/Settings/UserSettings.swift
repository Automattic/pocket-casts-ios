import PocketCastsUtils
import SwiftUI

class UserSettings {
    // MARK: - Headphone Controls
    lazy var headphonesPreviousAction = AppSetting("headphones.previousAction", defaultValue: HeadphoneControlAction.skipBack)
    lazy var headphonesNextAction = AppSetting("headphones.nextAction", defaultValue: HeadphoneControlAction.skipForward)

    // MARK: - Bookmarks
    lazy var playBookmarkCreationSound = AppSetting(defaultValue: true)
    lazy var bookmarksPlayerSort = AppSetting(defaultValue: BookmarkSortOption.newestToOldest)
    lazy var bookmarksPodcastSort = AppSetting(defaultValue: BookmarkSortOption.newestToOldest)
    lazy var bookmarksEpisodeSort = AppSetting(defaultValue: BookmarkSortOption.newestToOldest)
}

// MARK: -

extension UserSettings {
    // MARK: - Internal Singleton

    fileprivate static var shared = UserSettings()

    // MARK: - Subscript

    public static subscript<Value, Setting: AppSetting<Value>>(key: ReferenceWritableKeyPath<UserSettings, Setting>) -> Value {
        get {
            self.shared[keyPath: key].value
        }

        set {
            self.shared[keyPath: key].value = newValue
        }
    }
}

// MARK: - UserSetting Property Wrapper

@propertyWrapper struct UserSetting<Value, Setting: AppSetting<Value>>: DynamicProperty {
    var wrappedValue: Value {
        get {
            setting.value
        }

        nonmutating set {
            setting.save(newValue)
        }
    }

    var projectedValue: Binding<Value> {
        .init(get: { wrappedValue }, set: { self.wrappedValue = $0 })
    }

    @ObservedObject private var setting: Setting

    public init<Root>(_ key: ReferenceWritableKeyPath<Root, Setting>, settings: Root = UserSettings.shared) {
        self.setting = settings[keyPath: key]
    }
}
