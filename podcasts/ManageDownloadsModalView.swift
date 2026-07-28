import SwiftUI
import PocketCastsUtils
import Combine

struct ManageDownloadsModalView: View {

    @EnvironmentObject var theme: Theme

    @ObservedObject var dataModel: ManageDownloadsModel

    @ScaledMetric(relativeTo: .largeTitle) private var imageSize = 36

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Spacer()
            Image("cleanup")
                .resizable()
                .frame(width: imageSize, height: imageSize)
                .foregroundColor(theme.primaryText02Selected)
            Text(L10n.manageDownloadsTitle)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(theme.primaryText01)
            Text(L10n.manageDownloadsDetail(dataModel.sizeOccupied))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .font(.callout)
                .foregroundColor(theme.primaryText01)
            Spacer()
            Button() {
                dataModel.onManageTap?()
            } label: {
                Text(L10n.manageDownloadsAction)
            }
            .buttonStyle(RoundedButtonStyle(theme: theme))
            Button() {
                dataModel.onNotNowTap?()
            } label: {
                Text(L10n.maybeLater)
                    .font(size: 14, style: .subheadline, weight: .medium)
                    .foregroundColor(theme.primaryText01)
            }.frame(idealHeight: 56)
            Spacer().frame(height: 16)
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
