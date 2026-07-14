import SwiftUI

struct NowPlayingTab: View {

    @FocusState private var isFocused: Bool
    @Environment(MainTabViewModel.self) var tabRouter: MainTabViewModel

    var body: some View {
        NowPlayingView()
            .focused($isFocused)
            .ignoresSafeArea()
            .onChange(of: isFocused) { _, newValue in
                withAnimation(.default) {
                    tabRouter.isShowingDetail = newValue
                }
            }
            .animation(.easeIn, value: isFocused)
            .toolbar(!isFocused ? .visible : .hidden, for: .tabBar)
    }
}
