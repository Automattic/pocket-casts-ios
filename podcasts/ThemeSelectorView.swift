import PocketCastsServer
import SwiftUI

struct ThemeSelectorView: View {
    @EnvironmentObject var theme: Theme

    var title: String
    var onThemeSelected: (Theme.ThemeType) -> Void
    var dismissAction: () -> Void
    @State var selectedTheme: Theme.ThemeType

    let columns = [
        GridItem(.flexible(), alignment: .top),
        GridItem(.flexible(), alignment: .top),
        GridItem(.flexible(), alignment: .top)
    ]

    var body: some View {
        ZStack {
            ThemeColor.primaryUi01(for: theme.activeTheme).color
                .ignoresSafeArea()
            ScrollView {
                HStack {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .textStyle(PrimaryText())
                        .padding()
                    Spacer()
                    ModalCloseButton(action: dismissAction)
                        .frame(width: 50)
                }
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(Theme.ThemeType.displayOrder, id: \.self) { currentTheme in
                        Button(action: {
                            onThemeSelected(currentTheme)
                        }) {
                            ThemePreviewView(themeType: currentTheme, isSelected: selectedTheme == currentTheme, isLocked: currentTheme.isPlusOnly && !SubscriptionHelper.hasActiveSubscription())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
        }
    }
}

struct ThemePreviewView: View {
    @EnvironmentObject var theme: Theme

    @State var themeType: Theme.ThemeType
    @State var isSelected: Bool
    @State var isLocked: Bool

    var body: some View {
        VStack {
            ZStack(alignment: .bottomTrailing) {
                Image(themeType.imageName)
                    .shadow(radius: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? ThemeColor.primaryField03Active(for: theme.activeTheme).color : Color.clear, lineWidth: 4)
                    )
                if isSelected {
                    Image("tickBlueCircle")
                } else if isLocked {
                    Image("plusGoldCircle")
                }
            }
            .accessibility(hidden: true)
            Text(themeType.description)
                .font(.footnote)
                .fontWeight(.medium)
                .textStyle(PrimaryText())
        }
        .opacity(isLocked ? 0.5 : 1)
        .accessibilityLabel(isLocked ? L10n.accessibilityPlusOnly : themeType.description)
    }
}

struct ThemeSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeSelectorView(title: L10n.appearanceThemeSelect, onThemeSelected: { _ in

        }, dismissAction: {}, selectedTheme: .dark)
            .environmentObject(Theme.sharedTheme)
    }
}
