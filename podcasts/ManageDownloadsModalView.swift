import SwiftUI
import PocketCastsUtils
import Combine

struct ManageDownloadsModalView: View {

    @EnvironmentObject var theme: Theme

    @ObservedObject var dataModel: ManageDownloadsModel

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Spacer()
            Image("cleanup")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(theme.primaryText02Selected)
            Text(L10n.manageDownloadsTitle)
                .font(.system(size: 23, weight: .bold))
                .foregroundColor(theme.primaryText01)
            Text(L10n.manageDownloadsDetail(dataModel.sizeOccupied))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.primaryText01)
            Spacer()
            Button() {
                dataModel.onManageTap?()
            } label: {
                Text(L10n.manageDownloadsAction)
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(RoundedButtonStyle(theme: theme))
            Button() {
                dataModel.onNotNowTap?()
            } label: {
                Text(L10n.maybeLater)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.primaryText01)
            }.frame(height: 56)
        }
        .padding()
        .ignoresSafeArea()
        .background(theme.primaryUi01)
    }
}

#Preview("Light") {
    ManageDownloadsModalView(dataModel: .init(initialSize: "100 MB"))
        .environmentObject(Theme(previewTheme: .light))
        .padding(16)
}

#Preview("Dark") {
    ManageDownloadsModalView(dataModel: .init(initialSize: "100 MB"))
        .environmentObject(Theme(previewTheme: .dark))
        .padding(16)
}
