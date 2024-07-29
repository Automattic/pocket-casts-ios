import SwiftUI

struct KidsProfileSheet: View {
    @ObservedObject var viewModel: KidsProfileSheetViewModel

    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack {
            if viewModel.currentScreen == .submit {
                submitScreen
                    .transition(viewModel.transition)
            } else {
                KidsProfileThankYouScreen(viewModel: viewModel, theme: theme)
                    .transition(viewModel.transition)
            }
            Spacer()
        }
        .animation(.easeOut, value: viewModel.currentScreen)
    }

    private var submitScreen: some View {
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
