import SwiftUI

struct MenuRow: View {
    let label: String
    let icon: String
    @Binding var count: Int

    init(label: String, icon: String, count: Int = 0) {
        self.label = label
        self.icon = icon
        _count = Binding.constant(count)
    }

    init(label: String, icon: String, count: Binding<Int>) {
        self.label = label
        self.icon = icon
        _count = count
    }

    var countText: String {
        guard count > 0 else {
            return "0"
        }
        let ammendedCount = count > 99 ? "99+" : "\(count)"
        return ammendedCount
    }

    var accessibilityLabel: String {
        if count > 0 {
            return "\(label), \(count)"
        } else {
            return label
        }
    }

    var body: some View {
        Label {
            HStack {
                Text(label)
                Spacer()
                Group {
                    Text(countText)
                        .font(.footnote.bold())
                        .padding(2)
                        .frame(minWidth: 20)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 9, height: 9)))
                        .foregroundColor(.black)
                }
                .opacity(count > 0 ? 1 : 0)
            }
            .accessibilityLabel(accessibilityLabel)
        } icon: {
            Image(icon)
        }
    }
}

#Preview {
    MenuRow(label: "Podcasts", icon: "podcasts", count: 10)
}
