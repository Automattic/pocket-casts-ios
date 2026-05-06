import SwiftUI

@MainActor
@Observable
final class MainTabRouter {
    var selectedTab: MainTab = .home
    var isShowingDetail: Bool = false
}
