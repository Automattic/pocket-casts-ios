import SwiftUI

struct PageIndicatorView: View {
    let numberOfItems: Int

    let currentPage: Int

    var body: some View {
        HStack {
            ForEach(0 ..< numberOfItems, id: \.self) { itemIndex in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.white)
                    .opacity(itemIndex == currentPage ? 1 : 0.5)
            }
        }
    }
}

struct PageIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        PageIndicatorView(numberOfItems: 10, currentPage: 1)
    }
}
