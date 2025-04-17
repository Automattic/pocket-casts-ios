import SwiftUI
import PocketCastsUtils
import Combine

class BannerModel: ObservableObject {

    let title: String?
    let message: String?
    let action: String?
    let iconName: String?
    let invertedColor: Bool
    let onActionTap: (() -> ())?
    let onCloseTap: (() -> ())?

    init(title: String? = nil, message: String? = nil, action: String? = nil, iconName: String? = nil, invertedColor: Bool = false, onActionTap: (() -> ())? = nil, onCloseTap: (() -> ())? = nil) {
        self.title = title
        self.message = message
        self.action = action
        self.iconName = iconName
        self.invertedColor = invertedColor
        self.onActionTap = onActionTap
        self.onCloseTap = onCloseTap
    }
}

struct BannerView: View {

    @ObservedObject var model: BannerModel
    @EnvironmentObject var theme: Theme

    private var backgroundColor: Color {
        if model.invertedColor {
            if case .radioactive = theme.activeTheme {
                return theme.primaryUi06
            }
            return theme.primaryUi02Active
        }
        switch theme.activeTheme {
            case .indigo:
                return theme.primaryUi02Active
            case .contrastLight:
                return theme.secondaryUi02
            case .contrastDark:
                return theme.primaryUi02Active
            default:
                return theme.primaryUi01
        }
    }

    var body: some View {
        HStack(alignment: .top) {
            if let iconName = model.iconName {
                Image(iconName)
                    .foregroundColor(theme.primaryIcon03)
            }
            VStack(alignment: .leading, spacing: 8) {
                if let title = model.title {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(theme.primaryText01)
                }
                if let message = model.message {
                    Text(message)
                        .font(.caption2.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(theme.primaryText02)
                }
                if let action = model.action {
                    Button() {
                        model.onActionTap?()
                    } label: {
                        Text(action)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(theme.primaryInteractive01)
                    }
                }
            }
            Spacer()
        }
        .overlay(alignment: .topTrailing) {
            if model.onCloseTap != nil {
                Button() {
                    model.onCloseTap?()
                } label: {
                    Image("close")
                        .renderingMode(.template)
                        .foregroundColor(theme.primaryIcon02)
                }
                .padding(8)
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(8)
        .background(theme.primaryUi04)
        .padding()
    }
}

#Preview("Light") {
    BannerView(model: .init(title: "Manage Title", message: "Manage Message", action: "Do Action"))
        .environmentObject(Theme(previewTheme: .light))
        .padding(16)
        .frame(height: 132)
}

#Preview("Dark") {
    BannerView(model: .init(title: "Manage Title", message: "Manage Message", action: "Do Action"))
        .environmentObject(Theme(previewTheme: .dark))
        .padding(16)
        .frame(height: 132)
}
