import SwiftUI

extension View {
    func syncNavigationDetail(path: NavigationPath, tabRouter: MainTabViewModel) -> some View {
        onChange(of: path.isEmpty) { _, isEmpty in
            tabRouter.isShowingDetail = !isEmpty
        }
    }
}
