import SwiftUI

struct PlusPaywallSubscriptions: View {
    @ObservedObject var viewModel: PlusLandingViewModel

    var body: some View {
        container {
            Text("Placeholder for subscription")
                .foregroundStyle(.white)
                .padding(.horizontal, 20.0)
        }
        .background(
            Color(hex: "282829")
                .edgesIgnoringSafeArea(.all)
        )
    }

    @ViewBuilder
    func container(@ViewBuilder _ content: () -> some View) -> some View {
        ZStack {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    content()
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

#Preview {
    PlusPaywallSubscriptions(viewModel: PlusLandingViewModel(source: .login))
}
