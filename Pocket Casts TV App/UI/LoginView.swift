import SwiftUI

struct LoginView: View {
    @State private var viewModel = RootViewModel()

    var body: some View {
        VStack {
            Spacer()
            Text("Login")
            Spacer()
        }
    }
}

#Preview {
    LoginView()
}
