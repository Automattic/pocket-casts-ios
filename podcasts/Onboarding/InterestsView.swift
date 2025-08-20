import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class InterestsViewModel: ObservableObject {

    let minimumSelectionCount: Int = 3

    @Published var categories: [DiscoverCategory] = []
    @Published var isLoaded: Bool = false
    @Published var selectedCategories: Set<Int> = []

    func load() async {
        let page = await DiscoverServerHandler.shared.discoverPage()
        guard let layout = page.0 else {
            return
        }

        let categoriesItem = layout.layout?.first { item in
            item.type == "categories"
        }
        guard let categoriesItem else {
            return
        }
        let result = await DiscoverServerHandler.shared.discoverCategories(source: categoriesItem.source ?? "", authenticated: categoriesItem.isAuthenticated)
        DispatchQueue.main.async { [weak self] in
            self?.categories = result
            self?.isLoaded = true
        }
    }

    func isSelectedCategory(_ category: DiscoverCategory) -> Bool {
        return selectedCategories.contains(category.id ?? -1)
    }

    func toggleSelectionOfCategory(_ category: DiscoverCategory) {
        guard let id = category.id else {
            return
        }
        if isSelectedCategory(category) {
            selectedCategories.remove(id)
        } else {
            selectedCategories.insert(id)
        }
    }

    var isMinimumSelectionDone: Bool {
        return selectedCategories.count >= minimumSelectionCount
    }
}

struct InterestsView: View {

    @StateObject var viewModel = InterestsViewModel()

    @EnvironmentObject var theme: Theme

    var body: some View {
        Group {
            if viewModel.isLoaded {
                ZStack(alignment: .bottom) {
                    ScrollView(.vertical) {
                        VStack(spacing: 16) {
                            header
                            ForEach(viewModel.categories, id: \.id) { category in
                                VStack(alignment: .leading, spacing: 16) {
                                    Button(action: {
                                        viewModel.toggleSelectionOfCategory(category)
                                    }) {
                                        Text(category.name ?? "Unknown")
                                            .font(.title2.weight(.bold))
                                            .foregroundStyle(theme.primaryText01)
                                            .background(viewModel.isSelectedCategory(category) ? .red : .clear)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }
                            showMoreCategoriesButton
                        }
                        .padding(.bottom, 120)
                    }
                    .fadeGradient(bottomOffset: 50)
                    continueButton
                }
                .background(theme.primaryUi01)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.primaryIcon01))
                    .task {
                        await viewModel.load()
                    }
            }
        }
    }

    var header: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button(L10n.eoyNotNow) {

                }
                .tint(theme.primaryInteractive01)
            }
            .padding(.horizontal, 20)

            VStack(alignment: .center, spacing: 16) {
                Text(L10n.interestsTitle)
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.primaryText01)
                Text(L10n.interestsSubtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.primaryText02)
            }
            .padding(.horizontal, 30)
        }
        .padding(.top, 20)
    }

    var showMoreCategoriesButton: some View {
        HStack {
            Spacer()
            Button(L10n.interestsShowMoreCategories) {

            }
            .tint(theme.primaryInteractive01)
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    var continueButton: some View {
        VStack {
            Button(action: {
                //TODO: Implement this
            }) {
                Text(viewModel.isMinimumSelectionDone ? L10n.continue : L10n.interestsSelectAtLeast(viewModel.minimumSelectionCount))
                    .textStyle(RoundedButton())
            }
            .padding(.horizontal)
            .padding(.top, 2)
            .padding(.bottom)
            .opacity(viewModel.isMinimumSelectionDone ? 1 : 0.5)
            .disabled(!viewModel.isMinimumSelectionDone)
        }
        .background(theme.primaryUi01)
    }
}

#Preview("Live") {
    InterestsView()
        .environmentObject(Theme(previewTheme: .light))
}
