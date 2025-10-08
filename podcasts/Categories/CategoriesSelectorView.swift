import SwiftUI
import PocketCastsServer
import PocketCastsUtils

struct CategoriesSelectorView: View {
    @ObservedObject var discoverItemObservable: CategoriesSelectorViewController.DiscoverItemObservable

    @State private var categories: [DiscoverCategory]?
    @State private var prioritized: [DiscoverCategory]?

    @EnvironmentObject private var theme: Theme

    var body: some View {
        Group {
            if let categories, let prioritized {
                let sponsoredCategoryIDs = discoverItemObservable.item?.sponsoredCategoryIDs
                let recommendations = UserDefaults.standard.visitations(for: .discoverCategory)

                let prioritizedCategories = Category.create(from: prioritized, sponsoredCategoryIDs: sponsoredCategoryIDs, recommendations: recommendations)
                let overflowCategories = Category.create(from: categories, sponsoredCategoryIDs: sponsoredCategoryIDs, recommendations: recommendations)

                CategoriesPillsView(categories: prioritizedCategories,
                                    overflowCategories: overflowCategories,
                                    selectedCategory: $discoverItemObservable.selectedCategory.animation(.easeOut(duration: 0.25)),
                                    region: discoverItemObservable.region)
            } else {
                PlaceholderPillsView()
            }
        }
        .background(theme.secondaryUi01)
        .task(id: discoverItemObservable.item?.source) {
            let result = await discoverItemObservable.load()
            self.categories = result?.categories
            self.prioritized = result?.prioritized
        }
    }
}

struct PlaceholderPillsView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(0..<10) { _ in
                    Button(action: {}, label: {
                        Text("Placeholder")
                    })
                    .buttonStyle(CategoryButtonStyle())
                    .redacted(reason: .placeholder)
                }
            }
            .frame(alignment: .leading)
            .padding(CategoriesPillsView.Constants.buttonInsets)
        }
    }
}

struct Category {
    let category: DiscoverCategory
    let isSponsored: Bool
    let visits: Int

    init(category: DiscoverCategory, sponsoredCategoryIDs: [Int]?, recommendations: [String: Int]?) {
        self.category = category

        let sponsoredIDs = Set(sponsoredCategoryIDs?.map { String($0) } ?? [])
        let categoryID = category.id.map(String.init) ?? ""

        self.isSponsored = sponsoredIDs.contains(categoryID)
        self.visits = recommendations?[categoryID] ?? 0
    }

    static func create(from categories: [DiscoverCategory], sponsoredCategoryIDs: [Int]?, recommendations: [String: Int]?) -> [Category] {
        return categories.map { category in
            Category(category: category, sponsoredCategoryIDs: sponsoredCategoryIDs, recommendations: recommendations)
        }
    }
}

struct CategoriesPillsView: View {
    let categories: [Category]
    let overflowCategories: [Category]
    @Binding var selectedCategory: DiscoverCategory?

    let region: String?

    @State private var showingCategories = false

    @Namespace private var animation

    fileprivate enum Constants {
        static let buttonInsets: EdgeInsets = EdgeInsets(top: 2, leading: 16, bottom: 16, trailing: 16)
        static let selectedButtonInsets: EdgeInsets = EdgeInsets(top: 2, leading: 16, bottom: 0, trailing: 16)
    }

    var body: some View {
        if let selectedCategory {
            let selectedCategoryItem = categories.first { $0.category.id == selectedCategory.id }
            HStack {
                CloseButton(selectedCategory: $selectedCategory)
                CategoryButton(category: selectedCategory, selectedCategory: $selectedCategory, model: .init(region: region, index: 0, isSponsored: selectedCategoryItem?.isSponsored ?? false, visits: selectedCategoryItem?.visits ?? 0))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Constants.selectedButtonInsets)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    allCategoriesButton
                    categoryButtons
                }
                .padding(Constants.buttonInsets)
            }
        }
    }

    @ViewBuilder private var allCategoriesButton: some View {
        Button(action: {
            showingCategories.toggle()
            Analytics.track(.discoverCategoriesPillTapped, properties: ["name": "all", "region": region ?? "none", "id": -1])
        }, label: {
            HStack {
                Text("All Categories")
                Image(systemName: "chevron.down")
            }
        })
        .buttonStyle(CategoryButtonStyle())
        .sheet(isPresented: $showingCategories) {
            CategoriesModalPicker(categories: overflowCategories, selectedCategory: $selectedCategory, region: region)
                .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
        }
        .onChange(of: showingCategories) { isShowing in
            if isShowing {
                Analytics.track(.discoverCategoriesPickerShown, properties: ["region": region ?? "none"])
            } else {
                Analytics.track(.discoverCategoriesPickerClosed, properties: ["region": region ?? "none"])
            }
        }
        .onChange(of: selectedCategory) { _ in
            showingCategories = false
        }
    }

    @ViewBuilder private var categoryButtons: some View {
        ForEach(Array(categories.enumerated()), id: \.element.category.id) { index, categoryItem in
            CategoryButton(category: categoryItem.category, selectedCategory: $selectedCategory, model: .init(region: region, index: index, isSponsored: categoryItem.isSponsored, visits: categoryItem.visits))
                .matchedGeometryEffect(id: categoryItem.category.id, in: animation)
        }
    }
}

extension DiscoverCategory: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct CloseButton: View {
    @Binding var selectedCategory: DiscoverCategory?

    var body: some View {
        Button(action: {
            self.selectedCategory = nil
            Analytics.track(.discoverCategoryCloseButtonTapped)
        }, label: {
            Image(systemName: "xmark")
                .imageScale(.small)
        })
        .buttonStyle(CategoryButtonStyle(cornerStyle: .circle))
    }
}

struct CategoryButton: View {
    let category: DiscoverCategory

    @Binding var selectedCategory: DiscoverCategory?

    struct Model {
        let region: String?
        let index: Int
        let isSponsored: Bool
        let visits: Int
    }

    let model: Model

    var isSelected: Bool {
        category.id == selectedCategory?.id
    }

    var body: some View {
        Button(action: {
            selectedCategory = category
            Analytics.track(.discoverCategoriesPillTapped, properties: ["name": category.name ?? "none", "region": model.region ?? "none", "id": category.id ?? -1, "index": model.index, "sponsored": model.isSponsored, "visits": model.visits])
            if FeatureFlag.smartCategories.enabled, let categoryID = category.id {
                UserDefaults.standard.trackVisitation(event: .discoverCategory, id: String(categoryID))
            }
        }, label: {
            Text(category.name ?? "")
        })
        .buttonStyle(CategoryButtonStyle(isSelected: isSelected))
    }
}

// MARK: Previews

#Preview("unselected") {
    let category = DiscoverCategory(id: 0, name: "Test")
    let observable = CategoriesSelectorViewController.DiscoverItemObservable {
        return ([category], [category])
    }
    return ScrollView(.vertical) {
        CategoriesSelectorView(discoverItemObservable: observable)
            .frame(width: 400)
            .previewWithAllThemes()
    }
}

#Preview("selected") {
    let category = DiscoverCategory(id: 0, name: "Test")
    let observable = CategoriesSelectorViewController.DiscoverItemObservable {
        return ([category], [category])
    }
    return ScrollView(.vertical) {
        CategoriesSelectorView(discoverItemObservable: observable)
            .frame(width: 400)
            .previewWithAllThemes()
            .onAppear {
                observable.selectedCategory = category
            }
    }
}
