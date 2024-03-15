import SwiftUI

struct MenuRow: View {
    let label: String
    let icon: String
    let count: Int

    init(label: String, icon: String, count: Int = 0) {
        self.label = label
        self.icon = icon
        self.count = count
    }

    var countText: String {
        guard count > 0 else {
            return "0"
        }
        let ammendedCount = count > 99 ? "99+" : "\(count)"
        return ammendedCount
    }

    var body: some View {
        Label {
            HStack {
                Text(label)
                Spacer()
                Group {
                    Text(countText)
                        .font(.footnote.bold())
                        .padding(4)
                        .background(.white)
                        .clipShape(Circle())
                        .foregroundColor(.black)
                }
                .frame(minWidth: 20, minHeight: 20)
                .opacity(count > 0 ? 1 : 0)
            }
        } icon: {
            Image(icon)
        }
    }
}

#Preview {
    MenuRow(label: "Podcasts", icon: "podcasts", count: 10)
}
