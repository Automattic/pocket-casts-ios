import PocketCastsDataModel
import SwiftUI

struct NameFolderView: View {
    enum Field: Hashable {
        case name
    }

    @EnvironmentObject var theme: Theme

    @ObservedObject var model: FolderModel

    @State var focusOnTextField = false

    var dismissAction: (String?) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(L10n.name.localizedUppercase)
                .textStyle(SecondaryText())
                .font(.subheadline)
                .onChange(of: model.name, perform: { value in
                    if value.count > model.maximumAllowedCharactersForName {
                        model.name = String(value.prefix(model.maximumAllowedCharactersForName))
                      }
                  })
            if #available(iOS 15.0, *) {
                TextField(L10n.folderName, text: $model.name)
                    .focusMe(state: $focusOnTextField)
                    .themedTextField()
            }
            else {
                TextField(L10n.folderName, text: $model.name)
                    .themedTextField()
            }
            Spacer()
            NavigationLink(destination: ColorPreviewFolderView(model: model, dismissAction: dismissAction)) {
                Text(L10n.continue)
                    .textStyle(RoundedButton())
            }
        }
        .padding()
        .navigationTitle(L10n.folderNameTitle)
        .onAppear {
            // this appears to be a known issue with SwiftUI, in that it just passes this onto UIKit which can't set focus while a view is appearing, so here we artificially delay it
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusOnTextField = true
            }
        }
        .applyDefaultThemeOptions()
    }
}

struct NameFolderView_Previews: PreviewProvider {
    static var previews: some View {
        NameFolderView(model: FolderModel(), dismissAction: { _ in })
            .environmentObject(Theme(previewTheme: .light))
    }
}

// MARK: - FocusState wrapper

@available(iOS 15, *)
struct FocusModifier: ViewModifier {
    @FocusState var focused: Bool
    @Binding var state: Bool

    init(_ state: Binding<Bool>) {
        _state = state
    }

    func body(content: Content) -> some View {
        content.focused($focused, equals: true)
            .onChange(of: state, perform: changeFocus)
    }

    private func changeFocus(_ value: Bool) {
        focused = value
    }
}

@available(iOS 15, *)
extension View {
    func focusMe(state: Binding<Bool>) -> some View {
        modifier(FocusModifier(state))
    }
}
