import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class InterestsViewModel: ObservableObject, @unchecked Sendable {

    let maxInitialCategories: Int = 12
    let minimumSelectionCount: Int = 3
    var allCategories: [DiscoverCategory] = []

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
        let result = (await DiscoverServerHandler.shared.discoverCategories(source: categoriesItem.source ?? "", authenticated: categoriesItem.isAuthenticated)).filter({$0.id != 11})
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            allCategories = result
            categories = Array(allCategories.prefix(maxInitialCategories))
            isLoaded = true
        }
    }

    func isSelectedCategory(_ category: DiscoverCategory) -> Bool {
        return selectedCategories.contains(category.id ?? -1)
    }

    func positionOfCategory(_ category: DiscoverCategory) -> Int? {
        return categories.firstIndex(of: category)
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

    func showAll() {
        categories = allCategories
    }
}

struct InterestsView: View {

    @StateObject var viewModel = InterestsViewModel()

    @State var showMore: Bool = false

    @EnvironmentObject var theme: Theme

    @Environment(\.dismiss) var dismiss

    var body: some View {
        Group {
            if viewModel.isLoaded {
                mainBody
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.primaryIcon01))
                    .task {
                        await viewModel.load()
                    }
            }
        }
    }

    let columns: [GridItem] = [GridItem(.flexible(), alignment: .trailing), GridItem(.flexible(), alignment: .leading)]

    var mainBody: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack {
                Spacer()
                Button(L10n.eoyNotNow) {
                    dismiss()
                }
                .tint(theme.primaryInteractive01)
            }
            .padding(12)
            GeometryReader { geometryProxy in
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        header
                        Spacer().frame(height: 40)
                        FlexibleView(
                            availableWidth: geometryProxy.size.width,
                            data: viewModel.categories,
                            spacing: 8,
                            alignment: .center
                        ) { category in
                            categoryButton(for: category, index: viewModel.positionOfCategory(category) ?? 0)
                        }
                        if !showMore {
                            Spacer().frame(height: 40)
                            showMoreCategoriesButton
                        }
                        Spacer().frame(height: 40)
                    }
                }
            }
            .padding(.horizontal, 16)
            .fadeGradient(height: 40)
            continueButton
        }
        .background(theme.primaryUi01)
    }

    @ViewBuilder func categoryButton(for category: DiscoverCategory, index: Int) -> some View {
        let isSelected = viewModel.isSelectedCategory(category)
        InterestButton(name: category.name ?? "", icon: category.icon, isSelected: isSelected, style: InterestButton.Style.allCases[index % InterestButton.Style.allCases.count]) {
            withAnimation() {
                viewModel.toggleSelectionOfCategory(category)
            }
        }
    }

    var header: some View {
        VStack(spacing: 16) {
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
                showMore.toggle()
                withAnimation() {
                    viewModel.showAll()
                }
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
