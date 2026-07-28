import SwiftUI

struct ColorSelectCircle: View {
    @EnvironmentObject var theme: Theme

    @State var folderColorId: Int
    @ObservedObject var model: FolderModel

    var body: some View {
        Button {
            model.colorInt = folderColorId
        } label: {
            ZStack {
                Circle()
                    .fill(model.color(for: folderColorId))
                    .frame(width: 40, height: 40)
                if model.colorInt == folderColorId {
                    Image("small-tick")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(ThemeColor.primaryInteractive02(for: theme.activeTheme).color)
                }
            }
        }
        .accessibilityLabel("\(L10n.color) \(folderColorId + 1)")
    }
}
