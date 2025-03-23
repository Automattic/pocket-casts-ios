import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct CustomOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOptions = Set<CustomOption>()
    @State private var selectionOrder: [CustomOption] = []

    struct CustomOption: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let type: String
        let data: String?

        static let options: [CustomOption] = [
            CustomOption(title: "Near Me", type: "locations", data: nil),
            CustomOption(title: "Headlines", type: "headlines", data: nil),
            CustomOption(title: "Weather", type: "weather", data: nil),
            CustomOption(title: "Stocks", type: "stocks", data: "DAX,DJI,AAPL,GOOG"),
            CustomOption(title: "News", type: "news", data: "NYT"),
            CustomOption(title: "Sports", type: "sports", data: "General"),
            CustomOption(title: "Newsletters", type: "newsletters", data: "morningbrew"),
            CustomOption(title: "Daily Fact", type: "fact", data: nil),
            CustomOption(title: "Inspiration", type: "inspiration", data: nil),
            CustomOption(title: "Tarot", type: "tarot", data: nil),
            CustomOption(title: "Horoscope", type: "horoscope", data: nil),
            CustomOption(title: "Affirmation", type: "affirmation", data: nil),
            CustomOption(title: "Dad Joke", type: "joke", data: nil),
            CustomOption(title: "Demos", type: "demos", data: nil)
        ]
    }

    var onSave: ([String: String]) -> Void

    var body: some View {
        VStack {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(CustomOption.options) { option in
                    OptionCell(
                        title: option.title,
                        isSelected: selectedOptions.contains(option),
                        order: selectionOrder.firstIndex(of: option).map { $0 + 1 }
                    )
                    .onTapGesture {
                        toggleSelection(option)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)

            Spacer()

            Button(action: {
                let services = selectedOptions.reduce(into: [String: String]()) { result, option in
                    if let data = option.data {
                        result[option.type] = data
                    } else {
                        result[option.type] = option.title
                    }
                }
                onSave(services)
                dismiss()
            }) {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(ThemeColor.primaryInteractive01()))
                    .cornerRadius(8)
            }
            .padding()
        }
    }

    private func toggleSelection(_ option: CustomOption) {
        if selectedOptions.contains(option) {
            selectedOptions.remove(option)
            selectionOrder.removeAll { $0 == option }
        } else {
            selectedOptions.insert(option)
            selectionOrder.append(option)
        }
    }
}

struct OptionCell: View {
    let title: String
    let isSelected: Bool
    let order: Int?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(ThemeColor.primaryUi02()))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            Color(isSelected ? ThemeColor.primaryInteractive01() : ThemeColor.primaryUi05()),
                            lineWidth: 2
                        )
                )

            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(ThemeColor.primaryText01()))

                Spacer()

                if let order = order {
                    ZStack {
                        Circle()
                            .fill(Color(ThemeColor.primaryInteractive01()))
                            .frame(width: 24, height: 24)

                        Text("\(order)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 56)
        .background(
            isSelected ? Color(ThemeColor.primaryInteractive01()).opacity(0.1) : Color.clear
        )
    }
}

#Preview {
    CustomOptionsView { services in
        print(services)
    }
}
