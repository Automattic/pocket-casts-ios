import SwiftUI
import PocketCastsDataModel

struct TroubleshootingView: View {
    @EnvironmentObject var theme: Theme
    @StateObject private var viewModel: TroubleshootingViewModel
    @State private var showRemoveConfirmation = false

    init(source: OnlineSupportController.Source) {
        _viewModel = StateObject(wrappedValue: TroubleshootingViewModel(source: source))
    }

    var body: some View {
        List {
            Section {
                headerView
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            Section {
                statusRow

                if let lastRemovedCount = viewModel.lastRemovedCount {
                    Text(removedResultText(for: lastRemovedCount))
                        .foregroundColor(theme.support02)
                }

                Button(role: .destructive) {
                    showRemoveConfirmation = true
                } label: {
                    Text(L10n.troubleshootingRemoveOrphanedEpisodes)
                        .foregroundColor(theme.support05)
                        .opacity(canRemove ? 1 : 0.5)
                }
                .disabled(!canRemove)
            } header: {
                Text(L10n.troubleshootingOrphanedEpisodesHeader)
            } footer: {
                Text(L10n.troubleshootingOrphanedEpisodesDescription)
                    .foregroundColor(theme.primaryText02)
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.primaryUi04)
        .navigationTitle(L10n.troubleshootingTitle)
        .applyDefaultThemeOptions()
        .onAppear {
            viewModel.checkOrphanedEpisodes()
        }
        .alert(L10n.troubleshootingRemoveOrphanedEpisodesConfirmTitle, isPresented: $showRemoveConfirmation) {
            Button(L10n.troubleshootingRemoveOrphanedEpisodes, role: .destructive) {
                viewModel.removeOrphanedEpisodes()
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.troubleshootingRemoveOrphanedEpisodesConfirmMessage)
        }
    }

    private var canRemove: Bool {
        if case .found(let episodes) = viewModel.orphanedEpisodesState {
            return !episodes.isEmpty
        }
        return false
    }

    private var headerView: some View {
        Image(systemName: "wrench.and.screwdriver.fill")
            .font(.system(size: 32))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.green)

            Text(L10n.troubleshootingOrphanedEpisodesNoneFound)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var statusRow: some View {
        switch viewModel.orphanedEpisodesState {
        case .checking:
            busyRow(L10n.troubleshootingOrphanedEpisodesChecking)
        case .removing:
            busyRow(L10n.troubleshootingOrphanedEpisodesRemoving)
        case .found(let episodes) where episodes.isEmpty:
            emptyStateView
        case .found(let episodes):
            // Environment objects aren't reliably propagated across a NavigationLink push when the
            // source view has no ancestor NavigationView/NavigationStack (this screen is pushed onto
            // a UIKit UINavigationController directly), so inject theme explicitly to avoid a crash.
            NavigationLink {
                OrphanedEpisodesListView(episodes: episodes)
                    .environmentObject(theme)
            } label: {
                Text(countText(for: episodes.count))
            }
        }
    }

    private func busyRow(_ text: String) -> some View {
        HStack {
            Text(text)
                .foregroundColor(theme.primaryText02)
            Spacer()
            ProgressView()
        }
    }

    private func countText(for count: Int) -> String {
        count == 1 ? L10n.troubleshootingOrphanedEpisodesFoundSingular : L10n.troubleshootingOrphanedEpisodesFoundPluralFormat(count.localized())
    }

    private func removedResultText(for count: Int) -> String {
        if count == 0 {
            return L10n.troubleshootingRemoveOrphanedEpisodesResultNone
        }
        return count == 1 ? L10n.troubleshootingRemoveOrphanedEpisodesResultSingular : L10n.troubleshootingRemoveOrphanedEpisodesResultPluralFormat(count.localized())
    }
}

struct TroubleshootingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TroubleshootingView(source: .settings)
        }
        .setupDefaultEnvironment()
    }
}
