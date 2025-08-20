import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import Kingfisher

class InterestsViewModel: ObservableObject, @unchecked Sendable {

    let maxInitialCategories: Int = 12
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

    func categories(all: Bool) -> [DiscoverCategory] {
        all ? categories : Array(categories.prefix(maxInitialCategories))
    }
}

struct InterestsView: View {

    @StateObject var viewModel = InterestsViewModel()

    @State var showMore: Bool = false

    @EnvironmentObject var theme: Theme

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
        VStack(alignment: .center) {
            ScrollView(.vertical) {
                VStack(spacing: 16) {
                    header
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                        ForEach(viewModel.categories(all: showMore), id: \.id) { category in
                            categoryButton(for: category)
                        }
                    }
                    if !showMore {
                        showMoreCategoriesButton
                    }
                    Spacer().frame(height: 50)
                }
            }
            .fadeGradient(height: 50)
            continueButton
        }
        .background(theme.primaryUi01)
    }

    @ViewBuilder func categoryButton(for category: DiscoverCategory) -> some View {
        Button(action: {
            viewModel.toggleSelectionOfCategory(category)
        }) {
            HStack {
                if let icon = category.icon, let url = URL(string: icon) {
                    KFImage(url)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                Text(category.name ?? "Unknown")
                    .font(.title3.weight(.medium))
            }
        }.buttonStyle(
            CategoryInterestButtonStyle(isSelected: viewModel.isSelectedCategory(category))
        )
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
                showMore.toggle()
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
