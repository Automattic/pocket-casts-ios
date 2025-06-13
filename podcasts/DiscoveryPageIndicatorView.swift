import SwiftUI

struct DiscoveryPageIndicatorView: View {
    let numberOfItems: Int

    @Binding var currentPage: Int?

    @EnvironmentObject var theme: Theme

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< numberOfItems, id: \.self) { itemIndex in
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundStyle(itemIndex == currentPage ?  theme.primaryUi05Selected : theme.primaryUi05)
            }
        }.onTapGesture {
            var newValue = 0
            if let currentPage {
                newValue = currentPage + 1
                if newValue >= numberOfItems {
                    newValue = 0
                }
            }
            withAnimation {
                currentPage = newValue
            }
        }
    }
}

struct DiscoveryPageIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        PageIndicatorView(numberOfItems: 10, currentPage: 1)
    }
}
