import PocketCastsDataModel
import SwiftUI

struct SupportLogsView: View {
    @ObservedObject private var viewModel: SupportLogsViewModel

    private let controlSpacing: CGFloat = 22

    init(_ viewModel: SupportLogsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            optOutHeader()
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(viewModel.displayItems) { item in
                        Text(item.displayName)
                        ReadOnlyTextView(text: item.info)
                            .padding(.bottom, controlSpacing)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.top)
        .frame(maxWidth: .infinity, alignment: .leading)
        .applyDefaultThemeOptions(backgroundOverride: .primaryUi04)
        .navigationTitle(L10n.supportTitleAttachedLogs)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchDisplayItems()
        }
    }

    private func optOutHeader() -> some View {
        Group {
            Toggle(L10n.supportIncludeDebugInformation, isOn: $viewModel.includeDebugInfo)
                .toggleStyle(.themedSwitch)
                .padding(.horizontal)
            ThemedDivider()
        }
    }
}

struct SupportLogsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SupportLogsView(SupportLogsViewModel(SupportConfig(type: .feedback)))
                .environmentObject(Theme(previewTheme: .light))
        }
    }
}
