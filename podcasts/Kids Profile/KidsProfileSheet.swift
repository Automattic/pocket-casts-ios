import SwiftUI

struct KidsProfileSheet: View {
    @ObservedObject var viewModel: KidsProfileSheetViewModel

    @EnvironmentObject var theme: Theme

    private let transition: AnyTransition = .asymmetric(insertion: .slide, removal: .scale(scale: 0.7)).combined(with: .opacity)

    var body: some View {
        VStack {
            if viewModel.currentScreen == .submit {
                KidsProfileSubmitScreen(viewModel: viewModel, theme: theme)
                    .transition(transition)
            } else {
                KidsProfileThankYouScreen(viewModel: viewModel, theme: theme)
                    .transition(transition)
            }
            Spacer()
        }
        .animation(.easeOut, value: viewModel.currentScreen)
        .background(theme.primaryUi01)
    }
}

#Preview {
    KidsProfileSheet(viewModel: KidsProfileSheetViewModel())
        .environmentObject(Theme(previewTheme: .light))
}
