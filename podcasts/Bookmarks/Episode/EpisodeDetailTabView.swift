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

    var body: some View {
        HStack(spacing: 12) {
            ForEach(viewModel.tabs) { tab in
                Text(tab.title)
                    .buttonize {
                        viewModel.select(tab: tab)
                    } customize: { config in
                        config.label
                            .applyStyle(theme: theme, highlighted: viewModel.selectedTab == tab)
                            .applyButtonEffect(isPressed: config.isPressed)
                    }
            }

            Spacer()
        }
        .font(style: .subheadline, weight: .medium)
        .padding(.leading, 10)
    }
}

// MARK: - View Extension

private extension View {
    func applyStyle(theme: Theme, highlighted: Bool = false) -> some View {
        self
            .contentShape(Rectangle())
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .foregroundColor(highlighted ? theme.primaryUi01 : theme.primaryText02)
            .background(highlighted ? theme.primaryText01 : nil)
            .animation(.linear(duration: 0.1), value: highlighted)
            .cornerRadius(8)
    }
}
