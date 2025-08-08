import SwiftUI

struct HowToUploadView: View {
    @EnvironmentObject var theme: Theme

    var dismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            instructionsScrollView()
            doneButton()
        }
        .background(theme.primaryUi01)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                dismissButton()
            }

            ToolbarItem(placement: .principal) {
                Text(L10n.filesHowToTitle)
                    .bold()
                    .foregroundStyle(theme.secondaryText01)
            }
        }
    }

    @ViewBuilder
    func instructionsScrollView() -> some View {
        ScrollView {
            VStack {
                Spacer()

                Text(L10n.howToUploadExplanation)
                    .padding()

                instructionsSection(section: .menu)
                    .padding(.bottom, 10)

                instructionsSection(section: .action)

                Text(L10n.howToUploadSummary)
                    .padding()

                Spacer()
            }
            .padding(.top)
            .font(.subheadline.weight(.regular))
            .multilineTextAlignment(.center)
            .foregroundStyle(theme.primaryText02)
        }
    }

    enum Section {
        case menu
        case action

        var title: String {
            switch self {
            case .menu:
                L10n.howToUploadShareMenuInstruction
            case .action:
                L10n.howToUploadShareActionInstruction
            }
        }
    }

    @ViewBuilder
    func instructionsSection(section: Section) -> some View {
        HStack {
            Spacer()
            VStack {
                Text(section.title)
                switch section {
                case .menu:
                    HowToShareMenuImageView()
                case .action:
                    HowToShareActionImageView()
                        .offset(y: 10)
                }
            }
            Spacer()
        }
        .padding()
        .background(
            theme.primaryUi01Active
                .cornerRadius(10)
                .padding(.horizontal)
        )
    }

    @ViewBuilder
    func doneButton() -> some View {
        Button(action: {
            dismiss()
        }) {
            Text(L10n.done.localizedCapitalized)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(RoundedButtonStyle(theme: theme))
        .padding()
        .applyDefaultThemeOptions()
        .shadow(color: Color.black.opacity(0.15),
                radius: 2,
                x: 0, y: -2)
    }

    @ViewBuilder
    func dismissButton() -> some View {
        Button {
            dismiss()
        } label: {
            Image(uiImage: .init(named: "cancel") ?? UIImage())
        }
        .foregroundStyle(theme.secondaryIcon01)
        .accessibilityLabel(L10n.accessibilityCloseDialog)
    }
}
