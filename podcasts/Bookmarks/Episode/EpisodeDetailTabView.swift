import SwiftUI

// MARK: - EpisodeTabsViewModel

class EpisodeTabsViewModel: ObservableObject {
    @Published var selectedTab: Tab
    let tabs: [Tab]

    var selectedIndex: Int {
        tabs.firstIndex(of: selectedTab) ?? 0
    }

    init(tabs: [Tab]) {
        self.tabs = tabs

        _selectedTab = .init(initialValue: tabs.first ?? .init(title: "Missing"))
    }

    func selectTabIndex(_ index: Int) {
        guard let tab = tabs[safe: index], tab != selectedTab else {
            return
        }

        select(tab: tab)
    }

    func select(tab: Tab) {
        selectedTab = tab
    }

    struct Tab: Identifiable, Equatable {
        let title: String

        var id: String { title }
    }
}

// MARK: - EpisodeDetailTabView

struct EpisodeDetailTabView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: EpisodeTabsViewModel

    private var isSmallScreen: Bool {
        UIScreen.main.bounds.height <= 667
    }

    var body: some View {
        wrapperView {
            HStack(spacing: 12) {
                ForEach(viewModel.tabs) { tab in
                    Text(tab.title)
                        .buttonize {
                            viewModel.select(tab: tab)
                        } customize: { config in
                            config.label
                                .fixedSize()
                                .applyStyle(theme: theme,
                                            highlighted: viewModel.selectedTab == tab,
                                            isSmallScreen: isSmallScreen)
                                .applyButtonEffect(isPressed: config.isPressed)
                        }
                }

                Spacer()
            }
            .font(style: .subheadline, weight: .medium)
        }
        .padding(.leading, isSmallScreen ? 0 : 10)
    }

    @ViewBuilder
    func wrapperView<Content: View>(_ content: () -> Content) -> some View {
        if isSmallScreen {
            ScrollView(.horizontal, showsIndicators: false) {
                content()
            }
        } else {
            content()
        }
    }
}

// MARK: - View Extension

private extension View {
    func applyStyle(theme: Theme, highlighted: Bool = false, isSmallScreen: Bool) -> some View {
        self
            .contentShape(Rectangle())
            .padding(.vertical, 8)
            .padding(.horizontal, isSmallScreen ? 6 : 12)
            .foregroundColor(highlighted ? theme.primaryUi01 : theme.primaryText02)
            .background(highlighted ? theme.primaryText01 : nil)
            .animation(.linear(duration: 0.1), value: highlighted)
            .cornerRadius(8)
    }
}
