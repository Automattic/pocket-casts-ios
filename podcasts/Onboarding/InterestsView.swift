import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct InterestsView: View {

    @State var categories: [DiscoverCategory] = []
    @State var layout: DiscoverLayout?
    @State var selectedCategories: Set<Int> = []

    let minimumInterestsCount: Int = 3

    @EnvironmentObject var theme: Theme

    var body: some View {
        Group {
            if layout != nil {
                ZStack(alignment: .bottom) {
                    ScrollView(.vertical) {
                        VStack(spacing: 16) {
                            header
                            ForEach(categories, id: \.id) { category in
                                VStack(alignment: .leading, spacing: 16) {
                                    Button(action: {
                                        guard let id = category.id else {
                                            return
                                        }
                                        if selectedCategories.contains(id) {
                                            selectedCategories.remove(id)
                                        } else {
                                            selectedCategories.insert(id)
                                        }
                                    }) {
                                        Text(category.name ?? "Unknown")
                                            .font(.title2.weight(.bold))
                                            .foregroundStyle(theme.primaryText01)
                                            .background(selectedCategories.contains(category.id ?? -1) ? .red : .clear)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }
                            showMoreCategoriesButton
                        }
                        .padding(.bottom, 120)
                    }
                    //.fadeGradient(bottomOffset: 50)
                    VStack {
                        Button(action: {
                            //TODO: Implement this
                        }) {
                            Text(selectedCategories.count >= minimumInterestsCount ? L10n.continue : L10n.interestsSelectAtLeast(minimumInterestsCount))
                                .textStyle(RoundedButton())
                        }
                        .padding(.horizontal)
                        .padding(.top, 2)
                        .padding(.bottom)
                        .opacity(selectedCategories.count < minimumInterestsCount ? 0.5 : 1)
                        .disabled(selectedCategories.count < minimumInterestsCount)
                    }
                    .background(theme.primaryUi01)
                }
                .background(theme.primaryUi01)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.primaryIcon01))
                    .task {
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
                        categories = await DiscoverServerHandler.shared.discoverCategories(source: categoriesItem.source ?? "", authenticated: categoriesItem.isAuthenticated)
                        self.layout = layout
                    }
            }
        }
        //.ignoresSafeArea()
        //.background(theme.primaryUi01)
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
}

#Preview("Live") {
    InterestsView()
        .environmentObject(Theme(previewTheme: .light))
}
