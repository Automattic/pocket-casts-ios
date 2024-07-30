import SwiftUI

struct KidsProfileSheet: View {
    @ObservedObject var viewModel: KidsProfileSheetViewModel

    @EnvironmentObject var theme: Theme

    private let transition: AnyTransition = .asymmetric(insertion: .slide, removal: .scale(scale: 0.7)).combined(with: .opacity)

    var body: some View {
        VStack {
            if viewModel.currentScreen == .submit {
                submitScreen
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

    private var submitScreen: some View {
        // this will be replaced by the next screen
        ZStack {
            Rectangle().background(.black)
                .padding(.leading, 20.0)
                .padding(.top, 20.0)
                .padding(.trailing, 20.0)
                .frame(height: 330)
            Text("Placeholder")
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    KidsProfileSheet(viewModel: KidsProfileSheetViewModel())
        .environmentObject(Theme(previewTheme: .light))
}