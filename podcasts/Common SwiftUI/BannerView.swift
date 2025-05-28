import SwiftUI
import PocketCastsUtils
import Combine

class BannerModel: ObservableObject {

    let title: String?
    let message: String?
    let action: String?
    let iconName: String?
    let invertedColor: Bool
    private(set) var onActionTap: (() -> ())?
    private(set) var onCloseTap: (() -> ())?

    init(title: String? = nil, message: String? = nil, action: String? = nil, iconName: String? = nil, invertedColor: Bool = false, onActionTap: (() -> ())? = nil, onCloseTap: (() -> ())? = nil) {
        self.title = title
        self.message = message
        self.action = action
        self.iconName = iconName
        self.invertedColor = invertedColor
        self.onActionTap = onActionTap
        self.onCloseTap = onCloseTap
    }

    func setupBinding(onActionTap: (() -> Void)? = nil, onCloseTap: (() -> Void)? = nil) {
        self.onActionTap = onActionTap
        self.onCloseTap = onCloseTap
    }
}

struct BannerView: View {

    @ObservedObject var model: BannerModel
    @EnvironmentObject var theme: Theme
    @Environment(\.sizeCategory) private var sizeCategory

    let edgeInsets: EdgeInsets?

    init(model: BannerModel, edgeInsets: EdgeInsets? = nil) {
        self.model = model
        self.edgeInsets = edgeInsets
    }

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
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleFactor(for: sizeCategory)
                    .foregroundColor(theme.primaryIcon03)
                    .frame(width: 24, height: 24)
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
        .padding(.leading, model.iconName == nil ? 24 : 16)
        .padding(.trailing, model.onCloseTap == nil ? 16 : 56)
        .padding(.vertical, 16)
        .overlay(alignment: .topTrailing) {
            if model.onCloseTap != nil {
                Button() {
                    model.onCloseTap?()
                } label: {
                    Image("cross-little")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleFactor(for: sizeCategory)
                        .foregroundColor(theme.primaryIcon02)
                        .frame(width: 24, height: 24)
                }
                .padding(8)
            }
        }
        .background(backgroundColor)
        .cornerRadius(8)
        .background(.clear)
        .if(edgeInsets != nil) { content in
            content.padding(edgeInsets ?? EdgeInsets())
        }
        .if(edgeInsets == nil) { content in
            content.padding()
        }
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
