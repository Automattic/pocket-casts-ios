import PocketCastsDataModel
import SwiftUI

struct SuggestedFoldersUpSellView: View {
    @Environment(\.dismiss) var dismissAction
    @EnvironmentObject var theme: Theme
    @ObservedObject var model: SuggestedFoldersModel

    var onCompletion: ((SuggestedFoldersResult) -> Void)?

    init(model: SuggestedFoldersModel = SuggestedFoldersModel(), onCompletion: ((SuggestedFoldersResult) -> Void)? = nil) {
        self.model = model
        self.onCompletion = onCompletion
    }

    var body: some View {
        Group {
            switch model.loadingState {
            case .loaded:
                mainBody
            default:
                loadingView
            }
        }
        .task {
            await model.load()
        }
        .applyDefaultThemeOptions()
    }

    var loadingView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                LoadingView()
                Spacer()
            }
            Spacer()
        }
        .applyDefaultThemeOptions()
    }

    var mainBody: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer()
                .frame(minHeight: 16)
            foldersView
            Spacer()
            Group {
                Text(L10n.suggestedFoldersUpsellTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .textStyle(PrimaryText())
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.suggestedFoldersUpsellDescription)
                    .font(.system(size: 15))
                    .textStyle(SecondaryText())
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.center)
            Spacer()
            Button {
                Analytics.track(.suggestedFoldersPaywallModalUseTheseFoldersTapped, properties: [:])
                dismissAction()
                onCompletion?(.applySuggestedFolders(model.folders))
            } label: {
                Text(L10n.suggestedFoldersUseSuggestedFolders)
                    .textStyle(RoundedButton())
            }
            Spacer().frame(height: 8)
            Button {
                Analytics.track(.suggestedFoldersPaywallModalMaybeLaterTapped, properties: [:])
                dismissAction()
                onCompletion?(.dismiss)
            } label: {
                Text(L10n.maybeLater)
                    .textStyle(BorderButton())
            }
            Spacer().frame(height: 8)
        }
        .padding(.horizontal, 16)
        .onAppear {
            Analytics.track(.suggestedFoldersPaywallModalShown, properties: [:])
        }
    }

    var foldersView: some View {
        LazyHGrid(rows: [GridItem(.adaptive(minimum: 90, maximum: 130))], alignment: .center, spacing: 6) {
            ForEach(Array<SuggestedFolder>(model.folders.prefix(3))) { folder in
                SuggestedFolderPreviewWrapper(folder: folder)
                    .cornerRadius(4)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(minHeight: 90)
            }
        }
    }
}

struct SuggestedFoldersUpSellView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestedFoldersUpSellView()
            .environmentObject(Theme(previewTheme: .light))
    }
}
