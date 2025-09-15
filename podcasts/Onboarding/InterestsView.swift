import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import WrappingHStack

class InterestsViewModel: ObservableObject, @unchecked Sendable {

    enum CategoryType: Int {
        case arts = 1
        case business = 2
        case comedy = 3
        case education = 4
        case leisure = 5
        case government = 6
        case healthFitness = 7
        case kidsFamily = 8
        case music = 9
        case news = 10
        case religionSpirituality = 11
        case science = 12
        case societyCulture = 13
        case sports = 14
        case technology = 15
        case tvFilm = 16
        case fiction = 17
        case history = 18
        case trueCrime = 19
    }

    let maxInitialCategories: Int = 12
    let minimumSelectionCount: Int = 3
    var allCategories: [DiscoverCategory] = []

    @Published var categories: [DiscoverCategory] = []
    @Published var isLoaded: Bool = false
    @Published var selectedCategories: Set<Int> = []

    var fullSelectedCategories: [DiscoverCategory] {
        return categories.filter { selectedCategories.contains($0.id ?? -1) }
    }

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
        let result = (await DiscoverServerHandler.shared.discoverCategories(source: categoriesItem.source ?? "", authenticated: categoriesItem.isAuthenticated)).filter({$0.id != CategoryType.religionSpirituality.rawValue}).sorted { $0.popularity ?? -1 < $1.popularity ?? -1 }
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

    let continueCallback: (([DiscoverCategory]) -> ())?
    let notNowCallback: (() -> ())?
    let isInsideNavigation: Bool

    init(continueCallback: (([DiscoverCategory]) -> ())? = nil, notNowCallback: (() -> ())? = nil, isInsideNavigation: Bool = true) {
        self.continueCallback = continueCallback
        self.notNowCallback = notNowCallback
        self.isInsideNavigation = isInsideNavigation
    }

    var body: some View {
        VStack {
            if viewModel.isLoaded {
                mainBody
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.primaryIcon01))
                    .onAppear {
                        OnboardingFlow.shared.track(.onboardingInterestsShown)
                    }
                    .task {
                        await viewModel.load()
                    }
            }
        }
        .if(isInsideNavigation, transform: { content in
            content.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.eoyNotNow) {
                        OnboardingFlow.shared.track(.onboardingInterestsNotNowTapped)
                        notNowCallback?()
                    }
                    .tint(theme.primaryInteractive01)
                }
            }
        })
    }

    var mainBody: some View {
        VStack(alignment: .center, spacing: 0) {
            if !isInsideNavigation {
                HStack {
                    Spacer()
                    Button(L10n.eoyNotNow) {
                        OnboardingFlow.shared.track(.onboardingInterestsNotNowTapped)
                        notNowCallback?()
                    }
                    .tint(theme.primaryInteractive01)
                }
                .padding(12)
            }
            ZStack {
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        header
                        Spacer().frame(height: 40)
                        WrappingHStack(alignment: .center, horizontalSpacing: 8, verticalSpacing: 8, fitContentWidth: false) {
                            ForEach(viewModel.categories, id: \.self) { category in
                                categoryButton(for: category, index: viewModel.positionOfCategory(category) ?? 0).transition(.fade)
                            }
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
            OnboardingFlow.shared.track(.onboardingInterestsCategorySelected, properties: ["category_id": "\(category.id ?? -1)", "name": category.name ?? "", "is_selected": !isSelected])
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
            .padding(.horizontal, 16)
        }
        .padding(.top, 20)
    }

    var showMoreCategoriesButton: some View {
        HStack {
            Spacer()
            Button(action: {
                OnboardingFlow.shared.track(.onboardingInterestsShownMoreTapped)
                showMore.toggle()
                withAnimation() {
                    viewModel.showAll()
                }
            }) {
                Text(L10n.interestsShowMoreCategories)
                    .font(size: 17, style: .body, weight: .medium)
                    .tint(theme.primaryInteractive01)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    var continueButton: some View {
        VStack {
            Button(action: {
                continueCallback?(viewModel.fullSelectedCategories)
                OnboardingFlow.shared.track(.onboardingInterestsContinueTapped, properties: ["categories": Array(viewModel.selectedCategories)])
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
    InterestsView(continueCallback: nil)
        .environmentObject(Theme(previewTheme: .light))
}
