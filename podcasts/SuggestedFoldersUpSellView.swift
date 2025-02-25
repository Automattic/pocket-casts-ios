import PocketCastsDataModel
import SwiftUI

struct SuggestedFoldersUpSellView: View {
    @Environment(\.dismiss) var dismissAction
    @EnvironmentObject var theme: Theme
    @ObservedObject var model: SuggestedFoldersModel = SuggestedFoldersModel()

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer()
            foldersView
            Spacer()
            Group {
                Text(L10n.suggestedFoldersUpsellTitle)
                    .font(.title2)
                    .textStyle(PrimaryText())
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.suggestedFoldersUpsellDescription)
                    .font(.body)
                    .textStyle(SecondaryText())
                    .fixedSize(horizontal: false, vertical: true)
            }.multilineTextAlignment(.center)
            Spacer()
            Button {
                Analytics.track(.suggestedFoldersPaywallModalUseTheseFoldersTapped, properties: [:])
                dismissAction()
            } label: {
                Text(L10n.suggestedFoldersUseSuggestedFolders)
                    .textStyle(RoundedButton())
            }
            Button {
                Analytics.track(.suggestedFoldersPaywallModalMaybeLaterTapped, properties: [:])
                dismissAction()
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
        .applyDefaultThemeOptions()
    }

    var foldersView: some View {
        LazyHGrid(rows: [GridItem(.adaptive(minimum: 110, maximum: 160))], alignment: .center, spacing: 6) {
            ForEach(Array<SuggestedFolder>(model.folders.prefix(3))) { folder in
                SuggestedFolderPreviewWrapper(folder: folder)
                    .cornerRadius(4)
                    .frame(width: 130, height: 130)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}

struct SuggestedFoldersUpSellView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestedFoldersView(dismissAction: { _ in })
            .environmentObject(Theme(previewTheme: .light))
    }
}
